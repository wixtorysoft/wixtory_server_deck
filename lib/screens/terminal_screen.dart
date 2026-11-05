import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../models/server_profile.dart';
import '../services/ssh_service.dart';
import '../theme/app_colors.dart';
import '../widgets/quick_command_sheet.dart';
import '../widgets/terminal_accessory_bar.dart';

/// Cyber Obsidian Dark Theme for xterm terminal emulator.
const TerminalTheme cyberTerminalTheme = TerminalTheme(
  cursor: AppColors.terminalCursor,
  selection: Color(0x4038BDF8),
  foreground: AppColors.textPrimary,
  background: AppColors.terminalBg,
  black: Color(0xFF1E293B),
  red: Color(0xFFEF4444),
  green: Color(0xFF10B981),
  yellow: Color(0xFFF59E0B),
  blue: Color(0xFF3B82F6),
  magenta: Color(0xFF8B5CF6),
  cyan: Color(0xFF06B6D4),
  white: Color(0xFFE2E8F0),
  brightBlack: Color(0xFF475569),
  brightRed: Color(0xFFF87171),
  brightGreen: Color(0xFF34D399),
  brightYellow: Color(0xFFFBBF24),
  brightBlue: Color(0xFF60A5FA),
  brightMagenta: Color(0xFFA78BFA),
  brightCyan: Color(0xFF22D3EE),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: Color(0xFFFBBF24),
  searchHitBackgroundCurrent: Color(0xFFF97316),
  searchHitForeground: Color(0xFF000000),
);

/// Fullscreen production-grade SSH Terminal Screen with MITM defense,
/// dynamic PTY resizing, and virtual keyboard accessories.
class TerminalScreen extends StatefulWidget {
  final ServerProfile profile;

  const TerminalScreen({
    super.key,
    required this.profile,
  });

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  double _fontSize = 13.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndConnect();
    });
  }

  void _initAndConnect() {
    final sshService = Provider.of<SshService>(context, listen: false);

    // Setup Trust-On-First-Use (TOFU) host key approval prompt
    sshService.onPromptNewHostKey = _showTofuHostKeyPrompt;

    // Trigger connection with complete error handling
    connectToServer(context, sshService, widget.profile);
  }

  // ---------------------------------------------------------------------------
  // ROBUST CONNECTION & MITM ERROR HANDLING
  // ---------------------------------------------------------------------------

  /// Connects to the server while catching specific network & security exceptions.
  static Future<void> connectToServer(
    BuildContext context,
    SshService sshService,
    ServerProfile profile,
  ) async {
    try {
      await sshService.connect(profile);
    } on HostKeyMismatchException catch (mismatchErr) {
      if (context.mounted) {
        _showMitmAlertModal(context, mismatchErr);
      }
    } on SocketException catch (socketErr) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Network Error: Unable to reach host (${socketErr.message})',
        );
      }
    } on TimeoutException {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Connection Timeout: Remote host ${profile.host}:${profile.port} did not respond.',
        );
      }
    } on FormatException catch (keyErr) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Private Key Error: ${keyErr.message}');
      }
    } on HostKeyUntrustedException {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Connection cancelled: Untrusted host key.');
      }
    } catch (generalErr) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'SSH Connection Failed: $generalErr');
      }
    }
  }

  /// Displays a critical MITM Security Warning dialog when a host key mismatch occurs.
  static void _showMitmAlertModal(BuildContext context, HostKeyMismatchException err) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF180A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.error, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'CRITICAL SECURITY ALERT',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'REMOTE HOST IDENTIFICATION HAS CHANGED!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!\n'
                'Someone could be eavesdropping on you right now (Man-in-the-Middle attack) or the host key was replaced.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Host: ${err.host}:${err.port} (${err.keyType})',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    const Text('Expected Fingerprint:',
                        style: TextStyle(fontSize: 11, color: AppColors.cyberGreen, fontWeight: FontWeight.bold)),
                    SelectableText(err.expectedFingerprint,
                        style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace')),
                    const SizedBox(height: 6),
                    const Text('Received (Offered) Fingerprint:',
                        style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                    SelectableText(err.actualFingerprint,
                        style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abort Connection Immediately'),
          ),
        ],
      ),
    );
  }

  /// Displays Trust-On-First-Use (TOFU) host key approval prompt.
  Future<bool> _showTofuHostKeyPrompt({
    required String host,
    required int port,
    required String keyType,
    required String fingerprint,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.amber, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: AppColors.amber, size: 24),
            SizedBox(width: 10),
            Text(
              'Trust Host Key?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The authenticity of host \'$host:$port\' can\'t be established.',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Key Type: $keyType',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.voidBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: SelectableText(
                fingerprint,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.cyberCyan,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to continue connecting? This fingerprint will be securely saved.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Reject', style: TextStyle(color: AppColors.rose)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyberGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Trust & Connect'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final sshService = Provider.of<SshService>(context, listen: false);
    if (!sshService.isConnected) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect SSH Session?'),
        content: Text('Disconnect from ${widget.profile.name} (${widget.profile.host})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              sshService.disconnect();
              Navigator.pop(ctx, true);
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  void _openQuickCommands() {
    final sshService = Provider.of<SshService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickCommandSheet(sshService: sshService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sshService = Provider.of<SshService>(context);

    return PopScope(
      canPop: !sshService.isConnected,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final shouldLeave = await _onWillPop();
        if (shouldLeave && mounted) {
          nav.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.terminalBg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () async {
              final nav = Navigator.of(context);
              final shouldLeave = await _onWillPop();
              if (shouldLeave && mounted) {
                nav.pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(widget.profile.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.profile.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Text(
                '${widget.profile.username}@${widget.profile.host}:${widget.profile.port}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            // Status Indicator
            _buildStatusDot(sshService.status),
            const SizedBox(width: 8),
            // Font size controls
            IconButton(
              icon: const Text('A-', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              tooltip: 'Smaller Font',
              onPressed: _fontSize > 8 ? () => setState(() => _fontSize -= 1.0) : null,
            ),
            IconButton(
              icon: const Text('A+', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              tooltip: 'Larger Font',
              onPressed: _fontSize < 24 ? () => setState(() => _fontSize += 1.0) : null,
            ),
            // Disconnect button
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: AppColors.rose, size: 20),
              tooltip: 'Disconnect',
              onPressed: () async {
                final nav = Navigator.of(context);
                final shouldLeave = await _onWillPop();
                if (shouldLeave && mounted) {
                  nav.pop();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Terminal Canvas with LayoutBuilder for automatic orientation & keyboard geometry updates
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      color: AppColors.terminalBg,
                      child: TerminalView(
                        sshService.terminal,
                        theme: cyberTerminalTheme,
                        autofocus: true,
                        textStyle: TerminalStyle(
                          fontSize: _fontSize,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Ergonomic Mobile Accessory Keyboard Toolbar
              TerminalAccessoryBar(
                sshService: sshService,
                onOpenQuickCommands: _openQuickCommands,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(ConnectionStateStatus status) {
    Color color;
    switch (status) {
      case ConnectionStateStatus.connected:
        color = AppColors.online;
        break;
      case ConnectionStateStatus.connecting:
        color = AppColors.connecting;
        break;
      case ConnectionStateStatus.failed:
        color = AppColors.error;
        break;
      case ConnectionStateStatus.disconnected:
        color = AppColors.offline;
        break;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
