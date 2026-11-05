import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server_profile.dart';
import '../services/ssh_service.dart';
import '../theme/app_colors.dart';
import 'sftp_explorer_tab.dart';
import 'terminal_view_tab.dart';

class ServerDashboardScreen extends StatefulWidget {
  final ServerProfile profile;

  const ServerDashboardScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ServerDashboardScreen> createState() => _ServerDashboardScreenState();
}

class _ServerDashboardScreenState extends State<ServerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Automatically trigger connection when entering dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sshService = Provider.of<SshService>(context, listen: false);
      sshService.connect(widget.profile);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onOpenFolderInTerminal(String path) {
    final sshService = Provider.of<SshService>(context, listen: false);
    _tabController.animateTo(0); // Switch to Terminal tab
    sshService.sendInput('cd "$path" && pwd && ls -la\n');
  }

  Future<bool> _showDisconnectConfirm() async {
    final sshService = Provider.of<SshService>(context, listen: false);
    if (!sshService.isConnected) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Session?'),
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

  void _exitDashboard() async {
    final nav = Navigator.of(context);
    final shouldLeave = await _showDisconnectConfirm();
    if (shouldLeave && mounted) {
      nav.pop();
    }
  }

  Widget _buildStatusBadge(ConnectionStateStatus status) {
    Color color;
    String label;
    switch (status) {
      case ConnectionStateStatus.connected:
        color = AppColors.online;
        label = 'Connected';
        break;
      case ConnectionStateStatus.connecting:
        color = AppColors.connecting;
        label = 'Connecting...';
        break;
      case ConnectionStateStatus.failed:
        color = AppColors.error;
        label = 'Failed';
        break;
      case ConnectionStateStatus.disconnected:
        color = AppColors.offline;
        label = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
        final shouldLeave = await _showDisconnectConfirm();
        if (shouldLeave && mounted) {
          nav.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _exitDashboard,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(widget.profile.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.profile.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildStatusBadge(sshService.status),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: AppColors.rose),
              tooltip: 'Disconnect',
              onPressed: _exitDashboard,
            ),
            const SizedBox(width: 6),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.cyberCyan,
            indicatorWeight: 3,
            labelColor: AppColors.cyberCyan,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(
                icon: Icon(Icons.terminal_rounded, size: 20),
                text: 'SSH Terminal',
              ),
              Tab(
                icon: Icon(Icons.folder_copy_outlined, size: 20),
                text: 'Files & SFTP',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), // Prevent terminal gestures from swiping tabs
          children: [
            TerminalViewTab(sshService: sshService),
            SftpExplorerTab(
              sshService: sshService,
              onOpenInTerminal: _onOpenFolderInTerminal,
            ),
          ],
        ),
      ),
    );
  }
}
