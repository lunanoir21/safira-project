import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safira/core/security/password_generator.dart';
import 'package:safira/features/vault/presentation/providers/vault_provider.dart';
import 'package:safira/shared/widgets/safira_button.dart';
import 'package:safira/shared/widgets/safira_text_field.dart';

/// Page for creating a new vault entry.
///
/// Supports:
/// - All standard fields (title, username, password, URL, notes)
/// - Inline password generator
/// - TOTP secret field
/// - Category selection
/// - Tags
class VaultCreatePage extends ConsumerStatefulWidget {
  const VaultCreatePage({super.key});

  @override
  ConsumerState<VaultCreatePage> createState() => _VaultCreatePageState();
}

class _VaultCreatePageState extends ConsumerState<VaultCreatePage> {
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Login';
  bool _isLoading = false;

  static const _categories = ['Login', 'Card', 'Identity', 'Note', 'Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Entry'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafiraTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. GitHub, Gmail',
                prefixIcon: const Icon(Icons.label_outline),
                showClearButton: true,
              ),
              const SizedBox(height: 16),

              SafiraTextField(
                controller: _usernameController,
                label: 'Username / Email',
                prefixIcon: const Icon(Icons.person_outline),
                keyboardType: TextInputType.emailAddress,
                showClearButton: true,
                showCopyButton: true,
              ),
              const SizedBox(height: 16),

              SafiraTextField(
                controller: _passwordController,
                label: 'Password',
                isPassword: true,
                showStrengthIndicator: true,
                showCopyButton: true,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome_outlined),
                  tooltip: 'Generate password',
                  onPressed: _generatePassword,
                ),
              ),
              const SizedBox(height: 16),

              SafiraTextField(
                controller: _urlController,
                label: 'Website URL',
                hint: 'https://example.com',
                prefixIcon: const Icon(Icons.link_outlined),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),

              SafiraTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Secure notes for this entry…',
                maxLines: 4,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              const SizedBox(height: 32),

              SafiraButton(
                label: 'Save Entry',
                icon: Icons.save_outlined,
                isLoading: _isLoading,
                onPressed: _canSave() ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSave() => _titleController.text.isNotEmpty && !_isLoading;

  void _generatePassword() {
    final password = PasswordGenerator.instance.generate(
      const PasswordOptions(length: 20),
    );
    _passwordController.text = password;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Create VaultEntryModel, encrypt, save
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.pop();
    } on Exception {
      setState(() => _isLoading = false);
    }
  }
}
