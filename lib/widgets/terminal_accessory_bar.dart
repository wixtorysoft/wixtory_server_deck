import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ssh_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class TerminalAccessoryBar extends StatelessWidget {
  final SshService sshService;
  final VoidCallback? onOpenQuickCommands;

  const TerminalAccessoryBar({
    super.key,
    required this.sshService,
    this.onOpenQuickCommands,
  });

  Widget _buildKeyButton({
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
    double minWidth = 44,
    bool isSpecial = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: isSpecial
            ? (color ?? AppColors.surfaceLight)
            : AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            constraints: BoxConstraints(minWidth: minWidth, minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSpecial
                    ? (textColor?.withValues(alpha: 0.4) ?? AppColors.borderHighlight)
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTheme.monospaceStyle(
                fontSize: 12,
                fontWeight: isSpecial ? FontWeight.w700 : FontWeight.w600,
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.voidBg.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          if (onOpenQuickCommands != null)
            _buildKeyButton(
              label: '⚡ Cmds',
              textColor: AppColors.amber,
              isSpecial: true,
              onTap: onOpenQuickCommands!,
            ),
          _buildKeyButton(
            label: 'ESC',
            textColor: AppColors.cyberCyan,
            isSpecial: true,
            onTap: sshService.sendEsc,
          ),
          _buildKeyButton(
            label: 'TAB',
            textColor: AppColors.cyberCyan,
            isSpecial: true,
            onTap: sshService.sendTab,
          ),
          _buildKeyButton(
            label: '^C',
            textColor: AppColors.rose,
            isSpecial: true,
            onTap: sshService.sendCtrlC,
          ),
          _buildKeyButton(
            label: '^D',
            textColor: AppColors.rose,
            isSpecial: true,
            onTap: sshService.sendCtrlD,
          ),
          _buildKeyButton(
            label: '^Z',
            textColor: AppColors.amber,
            onTap: sshService.sendCtrlZ,
          ),
          _buildKeyButton(
            label: '^L',
            textColor: AppColors.sky,
            onTap: sshService.sendCtrlL,
          ),
          const VerticalDivider(color: AppColors.divider, width: 12),
          _buildKeyButton(
            label: '▲',
            onTap: sshService.sendArrowUp,
            minWidth: 38,
          ),
          _buildKeyButton(
            label: '▼',
            onTap: sshService.sendArrowDown,
            minWidth: 38,
          ),
          _buildKeyButton(
            label: '◄',
            onTap: sshService.sendArrowLeft,
            minWidth: 38,
          ),
          _buildKeyButton(
            label: '►',
            onTap: sshService.sendArrowRight,
            minWidth: 38,
          ),
          const VerticalDivider(color: AppColors.divider, width: 12),
          _buildKeyButton(label: '|', onTap: () => sshService.sendInput('|')),
          _buildKeyButton(label: '~', onTap: () => sshService.sendInput('~')),
          _buildKeyButton(label: '/', onTap: () => sshService.sendInput('/')),
          _buildKeyButton(label: '-', onTap: () => sshService.sendInput('-')),
          _buildKeyButton(label: '_', onTap: () => sshService.sendInput('_')),
          _buildKeyButton(label: '&', onTap: () => sshService.sendInput('&')),
          _buildKeyButton(label: '>', onTap: () => sshService.sendInput('>')),
          _buildKeyButton(
            label: 'Clear Buffer',
            onTap: () {
              sshService.terminal.buffer.clear();
            },
            textColor: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
