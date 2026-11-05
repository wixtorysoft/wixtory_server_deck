import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../services/ssh_service.dart';
import '../theme/app_colors.dart';
import '../widgets/quick_command_sheet.dart';
import '../widgets/terminal_accessory_bar.dart';

class TerminalViewTab extends StatefulWidget {
  final SshService sshService;

  const TerminalViewTab({
    super.key,
    required this.sshService,
  });

  @override
  State<TerminalViewTab> createState() => _TerminalViewTabState();
}

class _TerminalViewTabState extends State<TerminalViewTab> {
  double _fontSize = 13.0;

  void _openQuickCommands() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickCommandSheet(sshService: widget.sshService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Micro-Bar (Font size, Clear, Snippets)
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.terminal_rounded, size: 16, color: AppColors.cyberGreen),
              const SizedBox(width: 6),
              const Text(
                'SSH PTY Session',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Zoom out font
              InkWell(
                onTap: _fontSize > 9 ? () => setState(() => _fontSize -= 1.0) : null,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('A-', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              ),
              // Font size indicator
              Text(
                '${_fontSize.toInt()}pt',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              // Zoom in font
              InkWell(
                onTap: _fontSize < 24 ? () => setState(() => _fontSize += 1.0) : null,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('A+', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              ),
              const VerticalDivider(width: 14, color: AppColors.divider),
              // Quick Commands Button
              InkWell(
                onTap: _openQuickCommands,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: AppColors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Snippets',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.amber),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Terminal Emulator Canvas
        Expanded(
          child: Container(
            color: AppColors.terminalBg,
            child: TerminalView(
              widget.sshService.terminal,
              autofocus: true,
              textStyle: TerminalStyle(
                fontSize: _fontSize,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ),

        // Terminal Accessory Keyboard Row
        TerminalAccessoryBar(
          sshService: widget.sshService,
          onOpenQuickCommands: _openQuickCommands,
        ),
      ],
    );
  }
}
