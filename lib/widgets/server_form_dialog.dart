import 'package:flutter/material.dart';
import '../models/server_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ServerFormDialog extends StatefulWidget {
  final ServerProfile? initialProfile;
  final Function(ServerProfile profile) onSave;

  const ServerFormDialog({
    super.key,
    this.initialProfile,
    required this.onSave,
  });

  @override
  State<ServerFormDialog> createState() => _ServerFormDialogState();
}

class _ServerFormDialogState extends State<ServerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _privateKeyController;
  late TextEditingController _passphraseController;

  AuthType _authType = AuthType.password;
  int _selectedColor = AppColors.serverColorPalette.first;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _hostController = TextEditingController(text: p?.host ?? '');
    _portController = TextEditingController(text: (p?.port ?? 22).toString());
    _usernameController = TextEditingController(text: p?.username ?? 'root');
    _passwordController = TextEditingController(text: p?.password ?? '');
    _privateKeyController = TextEditingController(text: p?.privateKey ?? '');
    _passphraseController = TextEditingController(text: p?.passphrase ?? '');
    _authType = p?.authType ?? AuthType.password;
    _selectedColor = p?.colorValue ?? AppColors.serverColorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final profile = ServerProfile(
      id: widget.initialProfile?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty ? _hostController.text.trim() : _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 22,
      username: _usernameController.text.trim(),
      authType: _authType,
      password: _passwordController.text,
      privateKey: _privateKeyController.text,
      passphrase: _passphraseController.text,
      colorValue: _selectedColor,
      lastConnectedAt: widget.initialProfile?.lastConnectedAt,
    );

    widget.onSave(profile);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialProfile != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(_selectedColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                        color: Color(_selectedColor),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Server Profile' : 'New SSH Server',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Name / Label
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Server Name / Label',
                    hintText: 'e.g. Production VPS, AWS EC2, Home Server',
                    prefixIcon: Icon(Icons.label_outline_rounded, size: 20, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 14),

                // Host & Port Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host / IP Address *',
                          hintText: '192.168.1.50 or my-server.com',
                          prefixIcon: Icon(Icons.dns_rounded, size: 20, color: AppColors.textMuted),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Host is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '22',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    hintText: 'root, ubuntu, etc.',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textMuted),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Auth Type Switcher
                const Text(
                  'Authentication Method',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.password_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Password'),
                          ],
                        ),
                        selected: _authType == AuthType.password,
                        selectedColor: AppColors.cyberCyan.withValues(alpha: 0.2),
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: _authType == AuthType.password
                              ? AppColors.cyberCyan
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _authType = AuthType.password);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.key_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Private Key'),
                          ],
                        ),
                        selected: _authType == AuthType.privateKey,
                        selectedColor: AppColors.cyberCyan.withValues(alpha: 0.2),
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: _authType == AuthType.privateKey
                              ? AppColors.cyberCyan
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _authType = AuthType.privateKey);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Auth Fields
                if (_authType == AuthType.password)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  )
                else ...[
                  TextFormField(
                    controller: _privateKeyController,
                    maxLines: 4,
                    style: AppTheme.monospaceStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      labelText: 'Private Key (PEM / OpenSSH)',
                      hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passphraseController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Passphrase (Optional)',
                      prefixIcon: Icon(Icons.vpn_key_outlined, size: 20, color: AppColors.textMuted),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Color Tag Picker
                const Text(
                  'Color Badge',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: AppColors.serverColorPalette.map((colorVal) {
                    final isSelected = _selectedColor == colorVal;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorVal),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(colorVal).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Submit Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyberGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        isEditing ? 'Save Changes' : 'Add Server',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
