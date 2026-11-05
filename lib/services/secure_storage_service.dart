import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service tailored for zero-trust mobile SSH environments.
/// 
/// Sensitive credentials (Private Keys, Passwords, Host Key Fingerprints) are stored
/// via platform-level hardware-backed keystores (Android Keystore / iOS Keychain).
/// Non-sensitive user preferences are kept in SharedPreferences.
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  late final FlutterSecureStorage _secureStorage;

  SecureStorageService._internal() {
    // Android: EncryptedSharedPreferences with MasterKey Keystore
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    );

    // iOS: Accessible only after device is unlocked; not backed up to iCloud
    const iosOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    );

    // macOS: Keychain with first_unlock
    const macOsOptions = MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    );

    // Linux: Secret Service API
    const linuxOptions = LinuxOptions();

    // Windows: DPAPI Credential Manager
    const windowsOptions = WindowsOptions();

    // Web: SubtleCrypto encrypted storage
    const webOptions = WebOptions();

    _secureStorage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
      mOptions: macOsOptions,
      lOptions: linuxOptions,
      wOptions: windowsOptions,
      webOptions: webOptions,
    );
  }

  // ---------------------------------------------------------------------------
  // SENSITIVE CREDENTIAL MANAGEMENT (Hardware-Backed Keystore)
  // ---------------------------------------------------------------------------

  static String _keyPassword(String serverId) => 'sec_srv_${serverId}_pwd';
  static String _keyPrivateKey(String serverId) => 'sec_srv_${serverId}_pkey';
  static String _keyPassphrase(String serverId) => 'sec_srv_${serverId}_passphrase';
  static String _keyHostKey(String host, int port) => 'sec_hk_${host.trim().toLowerCase()}_$port';

  /// Saves sensitive credentials for a specific server profile.
  Future<void> saveServerCredentials({
    required String serverId,
    String? password,
    String? privateKey,
    String? passphrase,
  }) async {
    if (password != null && password.isNotEmpty) {
      await _secureStorage.write(key: _keyPassword(serverId), value: password);
    }
    if (privateKey != null && privateKey.isNotEmpty) {
      await _secureStorage.write(key: _keyPrivateKey(serverId), value: privateKey);
    }
    if (passphrase != null && passphrase.isNotEmpty) {
      await _secureStorage.write(key: _keyPassphrase(serverId), value: passphrase);
    }
  }

  /// Retrieves password securely from platform Keychain / Keystore.
  Future<String?> getServerPassword(String serverId) async {
    return await _secureStorage.read(key: _keyPassword(serverId));
  }

  /// Retrieves private key PEM string securely.
  Future<String?> getServerPrivateKey(String serverId) async {
    return await _secureStorage.read(key: _keyPrivateKey(serverId));
  }

  /// Retrieves optional private key passphrase.
  Future<String?> getServerPassphrase(String serverId) async {
    return await _secureStorage.read(key: _keyPassphrase(serverId));
  }

  /// Deletes all secure credentials associated with a server profile.
  Future<void> deleteServerCredentials(String serverId) async {
    await _secureStorage.delete(key: _keyPassword(serverId));
    await _secureStorage.delete(key: _keyPrivateKey(serverId));
    await _secureStorage.delete(key: _keyPassphrase(serverId));
  }

  // ---------------------------------------------------------------------------
  // TOFU (TRUST-ON-FIRST-USE) HOST KEY FINGERPRINT STORAGE
  // ---------------------------------------------------------------------------

  /// Retrieves the trusted SHA-256 host key fingerprint for host:port.
  Future<String?> getHostKeyFingerprint({
    required String host,
    required int port,
  }) async {
    final key = _keyHostKey(host, port);
    return await _secureStorage.read(key: key);
  }

  /// Saves the verified SHA-256 host key fingerprint for host:port upon user trust.
  Future<void> saveHostKeyFingerprint({
    required String host,
    required int port,
    required String fingerprint,
  }) async {
    final key = _keyHostKey(host, port);
    await _secureStorage.write(key: key, value: fingerprint.trim());
  }

  /// Removes the host key fingerprint (e.g. if host key was intentionally re-generated on server).
  Future<void> removeHostKeyFingerprint({
    required String host,
    required int port,
  }) async {
    final key = _keyHostKey(host, port);
    await _secureStorage.delete(key: key);
  }

  /// Clears all secure storage (panic button / factory reset).
  Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
  }

  // ---------------------------------------------------------------------------
  // NON-SENSITIVE USER PREFERENCES (SharedPreferences)
  // ---------------------------------------------------------------------------

  static const String _prefTerminalFontSize = 'pref_term_font_size';
  static const String _prefTerminalTheme = 'pref_term_theme';
  static const String _prefAutoScroll = 'pref_term_auto_scroll';

  Future<double> getTerminalFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_prefTerminalFontSize) ?? 13.0;
  }

  Future<void> setTerminalFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefTerminalFontSize, size);
  }

  Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefTerminalTheme) ?? 'cyber_obsidian';
  }

  Future<void> setSelectedTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTerminalTheme, theme);
  }

  Future<bool> getAutoScroll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefAutoScroll) ?? true;
  }

  Future<void> setAutoScroll(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoScroll, enabled);
  }
}
