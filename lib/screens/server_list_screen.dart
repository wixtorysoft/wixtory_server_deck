import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/server_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/server_form_dialog.dart';
import 'server_dashboard_screen.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  List<ServerProfile> _servers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() => _isLoading = true);
    final list = await StorageService.loadServers();
    if (mounted) {
      setState(() {
        _servers = list;
        _isLoading = false;
      });
    }
  }

  void _openAddServerDialog() {
    showDialog(
      context: context,
      builder: (_) => ServerFormDialog(
        onSave: (newProfile) async {
          await StorageService.upsertServer(newProfile);
          _loadServers();
        },
      ),
    );
  }

  void _openEditServerDialog(ServerProfile profile) {
    showDialog(
      context: context,
      builder: (_) => ServerFormDialog(
        initialProfile: profile,
        onSave: (updatedProfile) async {
          await StorageService.upsertServer(updatedProfile);
          _loadServers();
        },
      ),
    );
  }

  void _deleteServer(ServerProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Server?'),
        content: Text('Remove "${profile.name}" from your saved servers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteServer(profile.id);
      _loadServers();
    }
  }

  void _connectToServer(ServerProfile profile) {
    HapticFeedback.mediumImpact();
    // Update last connected timestamp
    final updated = profile.copyWith(lastConnectedAt: DateTime.now());
    StorageService.upsertServer(updated);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServerDashboardScreen(profile: updated),
      ),
    ).then((_) => _loadServers());
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.card.withValues(alpha: 0.4),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cyberGreen, AppColors.cyberCyan],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyberGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.terminal_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ServerDeck',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'SSH Terminal & Remote File Pilot',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dns_outlined, size: 14, color: AppColors.cyberCyan),
                    const SizedBox(width: 6),
                    Text(
                      '${_servers.length} Host${_servers.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeroHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.cyberGreen,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _servers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.card.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border, width: 1),
                                  ),
                                  child: const Icon(
                                    Icons.dns_rounded,
                                    size: 48,
                                    color: AppColors.cyberCyan,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'No Servers Added Yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add your server credentials to start SSH terminal sessions and browse files via SFTP.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.cyberGreen,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _openAddServerDialog,
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Add Your Server', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _servers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final server = _servers[index];
                            final tagColor = Color(server.colorValue);

                            return GlassCard(
                              padding: const EdgeInsets.all(16),
                              onTap: () => _connectToServer(server),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: tagColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: tagColor.withValues(alpha: 0.5),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          server.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          server.authType == AuthType.password ? 'Password' : 'Key',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.cyberCyan,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                                        color: AppColors.surface,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _openEditServerDialog(server);
                                          } else if (val == 'delete') {
                                            _deleteServer(server);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined, size: 16, color: AppColors.cyberCyan),
                                                SizedBox(width: 8),
                                                Text('Edit Profile'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.rose),
                                                SizedBox(width: 8),
                                                Text('Remove Server', style: TextStyle(color: AppColors.rose)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${server.username}@${server.host}:${server.port}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        server.lastConnectedAt != null
                                            ? 'Connected ${_timeAgo(server.lastConnectedAt!)}'
                                            : 'Not connected yet',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.cyberGreen.withValues(alpha: 0.15),
                                          foregroundColor: AppColors.cyberGreen,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: AppColors.cyberGreen.withValues(alpha: 0.3), width: 1),
                                          ),
                                        ),
                                        onPressed: () => _connectToServer(server),
                                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                        label: const Text('Connect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cyberGreen,
        foregroundColor: Colors.black,
        elevation: 4,
        onPressed: _openAddServerDialog,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Server', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
