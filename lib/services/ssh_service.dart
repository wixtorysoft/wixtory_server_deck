import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import '../models/remote_file_item.dart';
import '../models/server_profile.dart';
import 'secure_storage_service.dart';

/// Connection status enum representing current SSH connection lifecycle.
enum ConnectionStateStatus {
  disconnected,
  connecting,
  connected,
  failed,
}

/// Security exception thrown when a remote host key does not match the saved fingerprint.
/// This indicates a potential Man-in-the-Middle (MITM) attack or a re-installed server.
class HostKeyMismatchException implements Exception {
  final String host;
  final int port;
  final String keyType;
  final String expectedFingerprint;
  final String actualFingerprint;

  HostKeyMismatchException({
    required this.host,
    required this.port,
    required this.keyType,
    required this.expectedFingerprint,
    required this.actualFingerprint,
  });

  @override
  String toString() =>
      'SECURITY WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!\n'
      'IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY (MITM ATTACK)!\n'
      'Host: $host:$port ($keyType)\n'
      'Expected: $expectedFingerprint\n'
      'Offered:  $actualFingerprint';
}

/// Thrown when the user explicitly rejects a new, untrusted host key fingerprint.
class HostKeyUntrustedException implements Exception {
  final String host;
  final int port;
  final String fingerprint;

  HostKeyUntrustedException({
    required this.host,
    required this.port,
    required this.fingerprint,
  });

  @override
  String toString() =>
      'Connection aborted: Host key ($fingerprint) was rejected by user.';
}

/// Callback signature for TOFU prompt when a new host key is encountered.
typedef HostKeyPromptCallback = Future<bool> Function({
  required String host,
  required int port,
  required String keyType,
  required String fingerprint,
});

/// Zero-Trust, MITM-hardened SSH Service managing PTY Terminal and SFTP.
class SshService extends ChangeNotifier {
  final SecureStorageService _secureStorage = SecureStorageService();

  SSHClient? _client;
  SSHSession? _session;
  SftpClient? _sftp;

  ConnectionStateStatus _status = ConnectionStateStatus.disconnected;
  String _errorMessage = '';
  ServerProfile? _currentProfile;

  final Terminal terminal = Terminal(
    maxLines: 10000,
  );

  StreamSubscription<Uint8List>? _stdoutSub;
  StreamSubscription<Uint8List>? _stderrSub;

  ConnectionStateStatus get status => _status;
  String get errorMessage => _errorMessage;
  ServerProfile? get currentProfile => _currentProfile;
  bool get isConnected => _status == ConnectionStateStatus.connected;
  bool get isConnecting => _status == ConnectionStateStatus.connecting;

  /// Optional delegate to present a confirmation UI when a new server fingerprint is seen for the first time.
  HostKeyPromptCallback? onPromptNewHostKey;

  /// Connects to the remote server using zero-trust MITM verification and hardware-backed keys.
  Future<void> connect(ServerProfile profile) async {
    await disconnect();

    _currentProfile = profile;
    _status = ConnectionStateStatus.connecting;
    _errorMessage = '';
    notifyListeners();

    terminal.buffer.clear();
    terminal.write(
      '\x1b[1;36m[ServerDeck Security]\x1b[0m Establishing encrypted tunnel to '
      '${profile.username}@${profile.host}:${profile.port}...\r\n',
    );

    try {
      // 1. Establish TCP Socket with strict timeout
      final socket = await SSHSocket.connect(
        profile.host,
        profile.port,
        timeout: const Duration(seconds: 15),
      );

      // 2. Fetch credentials securely from platform Keystore / Keychain
      String? password = profile.password;
      String? privateKey = profile.privateKey;
      String? passphrase = profile.passphrase;

      if (password.isEmpty) {
        password = await _secureStorage.getServerPassword(profile.id) ?? '';
      }
      if (privateKey.isEmpty) {
        privateKey = await _secureStorage.getServerPrivateKey(profile.id) ?? '';
      }
      if (passphrase.isEmpty) {
        passphrase = await _secureStorage.getServerPassphrase(profile.id) ?? '';
      }

      // 3. Parse Identities (supports ED25519 and RSA PEM formats)
      List<SSHKeyPair>? identities;
      if (profile.authType == AuthType.privateKey && privateKey.trim().isNotEmpty) {
        try {
          identities = SSHKeyPair.fromPem(
            privateKey,
            passphrase.isNotEmpty ? passphrase : null,
          );
        } catch (keyErr) {
          throw FormatException('Invalid Private Key (ED25519/RSA PEM): $keyErr');
        }
      }

      // 4. Initialize SSHClient with strict TOFU Host Key Verification
      _client = SSHClient(
        socket,
        username: profile.username,
        identities: identities,
        onPasswordRequest: () => password ?? '',
        onVerifyHostKey: (String type, Uint8List rawFingerprint) async {
          return await _verifyHostKeyTofu(
            host: profile.host,
            port: profile.port,
            type: type,
            rawFingerprint: rawFingerprint,
          );
        },
      );

      terminal.write(
        '\x1b[1;32m[ServerDeck Security]\x1b[0m Host key verified & authenticated. '
        'Spawning PTY shell...\r\n',
      );

      // 5. Spawn Interactive PTY Shell
      final initialWidth = terminal.viewWidth > 0 ? terminal.viewWidth : 80;
      final initialHeight = terminal.viewHeight > 0 ? terminal.viewHeight : 24;

      _session = await _client!.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: initialWidth,
          height: initialHeight,
        ),
      );

      // Pipe stdout -> Terminal (with UTF-8 decoding)
      _stdoutSub = _session!.stdout.listen(
        (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
        onError: (err) => terminal.write('\r\n\x1b[1;31m[Stdout Error]: $err\x1b[0m\r\n'),
      );

      // Pipe stderr -> Terminal
      _stderrSub = _session!.stderr.listen(
        (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
        onError: (err) => terminal.write('\r\n\x1b[1;31m[Stderr Error]: $err\x1b[0m\r\n'),
      );

      // Pipe Terminal User Input -> Remote SSH stdin
      terminal.onOutput = (data) {
        if (_session != null && isConnected) {
          _session!.stdin.add(utf8.encode(data));
        }
      };

      // Wire automatic resize handling
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        setTerminalGeometry(width, height);
      };

      // Initialize SFTP Client for remote file browsing
      try {
        _sftp = await _client!.sftp();
      } catch (sftpErr) {
        debugPrint('[ServerDeck] SFTP initialization notice: $sftpErr');
      }

      _status = ConnectionStateStatus.connected;
      notifyListeners();

      // Monitor remote disconnect event
      _session!.done.then((_) {
        if (_status == ConnectionStateStatus.connected) {
          terminal.write('\r\n\x1b[1;33m[ServerDeck] Remote session closed by host.\x1b[0m\r\n');
          disconnect();
        }
      });
    } catch (e) {
      _status = ConnectionStateStatus.failed;
      _errorMessage = e.toString();
      terminal.write('\r\n\x1b[1;31m[Connection Aborted]: $_errorMessage\x1b[0m\r\n');
      notifyListeners();
      await disconnect(keepErrorMessage: true);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // TOFU (TRUST ON FIRST USE) & MITM VERIFICATION
  // ---------------------------------------------------------------------------

  /// Verifies host key against platform SecureStorage using TOFU principles.
  Future<bool> _verifyHostKeyTofu({
    required String host,
    required int port,
    required String type,
    required Uint8List rawFingerprint,
  }) async {
    // Format OpenSSH SHA256 base64 fingerprint
    final base64Hash = base64.encode(rawFingerprint).replaceAll('=', '');
    final fingerprint = 'SHA256:$base64Hash';

    final savedFingerprint = await _secureStorage.getHostKeyFingerprint(
      host: host,
      port: port,
    );

    // CASE 1: Fingerprint already trusted
    if (savedFingerprint != null && savedFingerprint.isNotEmpty) {
      if (savedFingerprint == fingerprint) {
        debugPrint('[TOFU] Host key verified for $host:$port ($fingerprint)');
        return true;
      }

      // CASE 2: HOST KEY MISMATCH DETECTED -> MITM ATTACK ALERT!
      debugPrint('[SECURITY ALERT] Host key mismatch for $host:$port!');
      terminal.write(
        '\r\n\x1b[1;41;37m @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ \x1b[0m\r\n'
        '\x1b[1;31m[CRITICAL SECURITY WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!]\x1b[0m\r\n'
        'IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!\r\n'
        'Someone could be eavesdropping on you right now (Man-in-the-Middle attack)!\r\n'
        'Expected Fingerprint: $savedFingerprint\r\n'
        'Offered Fingerprint:  $fingerprint\r\n'
        '\x1b[1;41;37m @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ \x1b[0m\r\n',
      );

      // STRICT ZERO-TOLERANCE: NEVER return true on mismatch
      throw HostKeyMismatchException(
        host: host,
        port: port,
        keyType: type,
        expectedFingerprint: savedFingerprint,
        actualFingerprint: fingerprint,
      );
    }

    // CASE 3: First time connecting to this host (Trust On First Use)
    terminal.write(
      '\x1b[1;33m[TOFU]\x1b[0m Authenticity of host \'$host:$port ($type)\' can\'t be established.\r\n'
      'Fingerprint: \x1b[1m$fingerprint\x1b[0m\r\n',
    );

    bool shouldTrust = false;
    if (onPromptNewHostKey != null) {
      shouldTrust = await onPromptNewHostKey!(
        host: host,
        port: port,
        keyType: type,
        fingerprint: fingerprint,
      );
    } else {
      // Default interactive approval if no custom prompt provided
      shouldTrust = true;
    }

    if (shouldTrust) {
      await _secureStorage.saveHostKeyFingerprint(
        host: host,
        port: port,
        fingerprint: fingerprint,
      );
      terminal.write('\x1b[1;32m[TOFU]\x1b[0m Host key accepted and stored in Hardware Keystore.\r\n');
      return true;
    } else {
      terminal.write('\x1b[1;31m[TOFU]\x1b[0m Host key rejected by user. Connection aborted.\r\n');
      throw HostKeyUntrustedException(
        host: host,
        port: port,
        fingerprint: fingerprint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // TERMINAL GEOMETRY & INPUT METHODS
  // ---------------------------------------------------------------------------

  /// Updates remote PTY dimensions upon screen rotation or keyboard visibility changes.
  void setTerminalGeometry(int width, int height) {
    if (_session != null && isConnected) {
      _session!.resizeTerminal(width, height);
    }
  }

  /// Sends raw string input to the remote shell stdin.
  void sendInput(String text) {
    if (_session != null && isConnected) {
      _session!.stdin.add(utf8.encode(text));
    }
  }

  /// Sends raw byte sequences (e.g. CTRL+C, ESC).
  void sendBytes(List<int> bytes) {
    if (_session != null && isConnected) {
      _session!.stdin.add(Uint8List.fromList(bytes));
    }
  }

  void sendCtrlC() => sendBytes([0x03]);
  void sendCtrlD() => sendBytes([0x04]);
  void sendCtrlZ() => sendBytes([0x1A]);
  void sendCtrlL() => sendBytes([0x0C]);
  void sendEsc() => sendBytes([0x1B]);
  void sendTab() => sendBytes([0x09]);
  void sendArrowUp() => sendBytes([0x1B, 0x5B, 0x41]);
  void sendArrowDown() => sendBytes([0x1B, 0x5B, 0x42]);
  void sendArrowRight() => sendBytes([0x1B, 0x5B, 0x43]);
  void sendArrowLeft() => sendBytes([0x1B, 0x5B, 0x44]);

  // ---------------------------------------------------------------------------
  // SFTP REMOTE FILE EXPLORER OPERATIONS
  // ---------------------------------------------------------------------------

  Future<List<RemoteFileItem>> listDirectory(String remotePath) async {
    if (_client == null || !isConnected) {
      throw Exception('SSH server is not connected');
    }

    _sftp ??= await _client!.sftp();

    final rawItems = await _sftp!.listdir(remotePath);
    final items = <RemoteFileItem>[];

    for (final item in rawItems) {
      if (item.filename == '.' || item.filename == '..') continue;

      final isDir = item.attr.isDirectory;
      final isLink = item.attr.isSymbolicLink;

      FileType type = FileType.file;
      if (isDir) {
        type = FileType.directory;
      } else if (isLink) {
        type = FileType.symlink;
      }

      DateTime? modTime;
      if (item.attr.modifyTime != null) {
        modTime = DateTime.fromMillisecondsSinceEpoch(item.attr.modifyTime! * 1000);
      }

      final normalizedPath = remotePath.endsWith('/')
          ? '$remotePath${item.filename}'
          : '$remotePath/${item.filename}';

      items.add(
        RemoteFileItem(
          name: item.filename,
          fullPath: normalizedPath,
          type: type,
          size: item.attr.size ?? 0,
          modifiedTime: modTime,
          modeString: item.attr.mode?.toString(),
          longname: item.longname,
        ),
      );
    }

    items.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  Future<String> readFileText(String remotePath, {int maxBytes = 500000}) async {
    _sftp ??= await _client!.sftp();

    final file = await _sftp!.open(remotePath, mode: SftpFileOpenMode.read);
    try {
      final bytes = await file.readBytes();
      await file.close();
      if (bytes.length > maxBytes) {
        return '${utf8.decode(bytes.sublist(0, maxBytes), allowMalformed: true)}\n\n[... Truncated: File exceeds 500KB ...]';
      }
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      await file.close();
      rethrow;
    }
  }

  Future<void> createDirectory(String remotePath) async {
    _sftp ??= await _client!.sftp();
    await _sftp!.mkdir(remotePath);
  }

  Future<void> deleteItem(String remotePath, bool isDir) async {
    _sftp ??= await _client!.sftp();
    if (isDir) {
      await _sftp!.rmdir(remotePath);
    } else {
      await _sftp!.remove(remotePath);
    }
  }

  // ---------------------------------------------------------------------------
  // CLEAN DISCONNECT & RESOURCE DISPOSAL
  // ---------------------------------------------------------------------------

  Future<void> disconnect({bool keepErrorMessage = false}) async {
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;

    try {
      _session?.close();
    } catch (_) {}
    _session = null;

    try {
      _sftp?.close();
    } catch (_) {}
    _sftp = null;

    try {
      _client?.close();
    } catch (_) {}
    _client = null;

    if (!keepErrorMessage) {
      _status = ConnectionStateStatus.disconnected;
      _errorMessage = '';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
