import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/remote_file_item.dart';
import '../services/ssh_service.dart';
import '../theme/app_colors.dart';
import '../widgets/file_viewer_sheet.dart';
import '../widgets/glass_card.dart';

class SftpExplorerTab extends StatefulWidget {
  final SshService sshService;
  final Function(String path)? onOpenInTerminal;

  const SftpExplorerTab({
    super.key,
    required this.sshService,
    this.onOpenInTerminal,
  });

  @override
  State<SftpExplorerTab> createState() => _SftpExplorerTabState();
}

class _SftpExplorerTabState extends State<SftpExplorerTab> {
  String _currentPath = '/';
  List<RemoteFileItem> _items = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDirectory(_currentPath);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.sshService.listDirectory(path);
      if (mounted) {
        setState(() {
          _currentPath = path;
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateUp() {
    if (_currentPath == '/' || _currentPath.isEmpty) return;
    final lastSlash = _currentPath.lastIndexOf('/');
    final parent = lastSlash <= 0 ? '/' : _currentPath.substring(0, lastSlash);
    _loadDirectory(parent);
  }

  void _navigateToCrumb(int index, List<String> segments) {
    if (index == 0) {
      _loadDirectory('/');
      return;
    }
    final targetPath = '/${segments.sublist(1, index + 1).join('/')}';
    _loadDirectory(targetPath);
  }

  void _showJumpToPathDialog() {
    final controller = TextEditingController(text: _currentPath);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jump to Path', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '/var/log, /etc, /home, etc.',
            prefixIcon: Icon(Icons.folder_open_rounded, size: 20),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyberCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                _loadDirectory(path);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'folder_name',
            prefixIcon: Icon(Icons.create_new_folder_outlined, size: 20),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyberGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final folderName = controller.text.trim();
              if (folderName.isNotEmpty) {
                final newPath = _currentPath.endsWith('/')
                    ? '$_currentPath$folderName'
                    : '$_currentPath/$folderName';
                try {
                  await widget.sshService.createDirectory(newPath);
                  _loadDirectory(_currentPath);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create folder: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(RemoteFileItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.isDirectory ? 'Delete Directory?' : 'Delete File?'),
        content: Text('Are you sure you want to permanently delete:\n${item.fullPath}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.sshService.deleteItem(item.fullPath, item.isDirectory);
                _loadDirectory(_currentPath);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(RemoteFileItem item) {
    if (item.isDirectory) return Icons.folder_rounded;
    if (item.isSymlink) return Icons.link_rounded;

    final ext = item.extension;
    switch (ext) {
      case 'sh':
      case 'bash':
      case 'zsh':
        return Icons.terminal_rounded;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'conf':
      case 'config':
      case 'ini':
      case 'env':
        return Icons.tune_rounded;
      case 'log':
      case 'txt':
        return Icons.article_outlined;
      case 'tar':
      case 'gz':
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.inventory_2_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(RemoteFileItem item) {
    if (item.isDirectory) return AppColors.amber;
    if (item.isSymlink) return AppColors.cyberCyan;
    final ext = item.extension;
    if (['sh', 'bash', 'zsh'].contains(ext)) return AppColors.cyberGreen;
    if (['json', 'yaml', 'yml', 'conf', 'env'].contains(ext)) return AppColors.sky;
    if (['log'].contains(ext)) return AppColors.electricViolet;
    if (['tar', 'gz', 'zip'].contains(ext)) return AppColors.rose;
    return AppColors.textSecondary;
  }

  List<String> get _breadcrumbs {
    if (_currentPath == '/' || _currentPath.isEmpty) return ['/'];
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
    return ['/', ...parts];
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _searchQuery.isEmpty
        ? _items
        : _items.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        // Top Toolbar & Breadcrumb Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    tooltip: 'Parent Folder',
                    color: _currentPath == '/' ? AppColors.textMuted : AppColors.cyberCyan,
                    onPressed: _currentPath == '/' ? null : _navigateUp,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _breadcrumbs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final crumb = entry.value;
                          final isLast = idx == _breadcrumbs.length - 1;

                          return Row(
                            children: [
                              InkWell(
                                onTap: isLast ? null : () => _navigateToCrumb(idx, _breadcrumbs),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Text(
                                    crumb,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                                      color: isLast ? AppColors.cyberCyan : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isLast && idx != 0)
                                const Text('/', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_location_alt_outlined, size: 20),
                    tooltip: 'Jump to Path',
                    color: AppColors.textSecondary,
                    onPressed: _showJumpToPathDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                    tooltip: 'New Folder',
                    color: AppColors.cyberGreen,
                    onPressed: _showCreateFolderDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh',
                    color: AppColors.textSecondary,
                    onPressed: () => _loadDirectory(_currentPath),
                  ),
                ],
              ),
              // Search in Folder Bar
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      hintText: 'Filter files in this folder...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Files List / Loading / Error
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.cyberCyan, strokeWidth: 2),
                      SizedBox(height: 12),
                      Text('Listing remote directory...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 44),
                            const SizedBox(height: 12),
                            const Text(
                              'Unable to open directory',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceLight,
                                foregroundColor: AppColors.textPrimary,
                              ),
                              onPressed: () => _loadDirectory(_currentPath),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_open_outlined, color: AppColors.textMuted.withValues(alpha: 0.5), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty ? 'No matches found' : 'Folder is empty',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final icon = _getFileIcon(item);
                            final iconColor = _getFileColor(item);

                            return GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              borderRadius: 10,
                              onTap: () {
                                if (item.isDirectory) {
                                  _loadDirectory(item.fullPath);
                                } else if (item.isEditableText) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => FileViewerSheet(
                                      fileItem: item,
                                      sshService: widget.sshService,
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(icon, color: iconColor, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: item.isDirectory ? FontWeight.w600 : FontWeight.w400,
                                            color: item.isDirectory ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.9),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              item.formattedSize,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '•',
                                              style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4)),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item.formattedDate,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                                    color: AppColors.surface,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (val) {
                                      if (val == 'view') {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => FileViewerSheet(
                                            fileItem: item,
                                            sshService: widget.sshService,
                                          ),
                                        );
                                      } else if (val == 'terminal') {
                                        final targetDir = item.isDirectory ? item.fullPath : _currentPath;
                                        widget.onOpenInTerminal?.call(targetDir);
                                      } else if (val == 'copy_path') {
                                        Clipboard.setData(ClipboardData(text: item.fullPath));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Path copied to clipboard'), duration: Duration(seconds: 1)),
                                        );
                                      } else if (val == 'delete') {
                                        _confirmDelete(item);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      if (!item.isDirectory)
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.cyberCyan),
                                              SizedBox(width: 8),
                                              Text('View Content'),
                                            ],
                                          ),
                                        ),
                                      const PopupMenuItem(
                                        value: 'terminal',
                                        child: Row(
                                          children: [
                                            Icon(Icons.terminal_rounded, size: 16, color: AppColors.cyberGreen),
                                            SizedBox(width: 8),
                                            Text('Open in Terminal'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'copy_path',
                                        child: Row(
                                          children: [
                                            Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
                                            SizedBox(width: 8),
                                            Text('Copy Path'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.rose),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: AppColors.rose)),
                                          ],
                                        ),
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
    );
  }
}
