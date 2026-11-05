import 'package:intl/intl.dart';

enum FileType {
  directory,
  file,
  symlink,
  other,
}

class RemoteFileItem {
  final String name;
  final String fullPath;
  final FileType type;
  final int size;
  final DateTime? modifiedTime;
  final String? modeString;
  final String? longname;

  RemoteFileItem({
    required this.name,
    required this.fullPath,
    required this.type,
    this.size = 0,
    this.modifiedTime,
    this.modeString,
    this.longname,
  });

  bool get isDirectory => type == FileType.directory;
  bool get isFile => type == FileType.file;
  bool get isSymlink => type == FileType.symlink;

  String get formattedSize {
    if (isDirectory) return '--';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedDate {
    if (modifiedTime == null) return '--';
    return DateFormat('yyyy-MM-dd HH:mm').format(modifiedTime!);
  }

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toLowerCase();
    }
    return '';
  }

  bool get isEditableText {
    final ext = extension;
    const textExts = {
      'txt', 'md', 'json', 'yaml', 'yml', 'conf', 'config', 'sh', 'bash',
      'zsh', 'env', 'py', 'js', 'ts', 'dart', 'html', 'css', 'sql', 'log',
      'xml', 'ini', 'cfg', 'properties', 'java', 'kt', 'c', 'cpp', 'h',
      'go', 'rs', 'php', 'rb', 'dockerfile', 'gitignore'
    };
    if (textExts.contains(ext)) return true;
    if (name.startsWith('.') && !name.contains('/', 1)) return true; // .bashrc, .profile, etc.
    return false;
  }
}
