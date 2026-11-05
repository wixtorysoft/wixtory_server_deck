import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ssh_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class QuickCommandItem {
  final String title;
  final String command;
  final String description;
  final IconData icon;
  final Color color;

  const QuickCommandItem({
    required this.title,
    required this.command,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class QuickCommandSheet extends StatelessWidget {
  final SshService sshService;

  const QuickCommandSheet({
    super.key,
    required this.sshService,
  });

  static const List<QuickCommandItem> commands = [
    QuickCommandItem(
      title: 'Top Processes',
      command: 'top -b -n 1 | head -n 25\n',
      description: 'Snapshot of CPU, Memory & Top active processes',
      icon: Icons.speed_rounded,
      color: AppColors.cyberCyan,
    ),
    QuickCommandItem(
      title: 'Disk Space',
      command: 'df -h\n',
      description: 'Check mounted disks and free storage space',
      icon: Icons.storage_rounded,
      color: AppColors.amber,
    ),
    QuickCommandItem(
      title: 'Memory Usage',
      command: 'free -h\n',
      description: 'RAM and Swap memory breakdown',
      icon: Icons.memory_rounded,
      color: AppColors.cyberGreen,
    ),
    QuickCommandItem(
      title: 'Docker Containers',
      command: 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"\n',
      description: 'List currently running Docker containers',
      icon: Icons.grid_view_rounded,
      color: AppColors.sky,
    ),
    QuickCommandItem(
      title: 'System Uptime & Load',
      command: 'uptime\n',
      description: 'System running duration & load average',
      icon: Icons.timer_outlined,
      color: AppColors.electricViolet,
    ),
    QuickCommandItem(
      title: 'Listening Ports',
      command: 'ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null\n',
      description: 'Active TCP/UDP listening services & ports',
      icon: Icons.lan_outlined,
      color: AppColors.cyberCyan,
    ),
    QuickCommandItem(
      title: 'System Info & Kernel',
      command: 'uname -a && cat /etc/os-release | grep PRETTY_NAME\n',
      description: 'Linux kernel and OS distribution details',
      icon: Icons.terminal_rounded,
      color: AppColors.textSecondary,
    ),
    QuickCommandItem(
      title: 'Systemd Failed Units',
      command: 'systemctl --failed\n',
      description: 'Check any background system services that crashed',
      icon: Icons.warning_amber_rounded,
      color: AppColors.rose,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.amber, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Quick Commands',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: commands.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cmd = commands[index];
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    sshService.sendInput(cmd.command);
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cmd.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cmd.color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(cmd.icon, color: cmd.color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cmd.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cmd.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cmd.command.trim(),
                              style: AppTheme.monospaceStyle(
                                fontSize: 11,
                                color: AppColors.cyberCyan.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.cyberGreen,
                        size: 22,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
