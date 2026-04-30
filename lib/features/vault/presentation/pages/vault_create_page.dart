// lib/features/vault/presentation/pages/vault_create_page.dart
// Form to create a new vault entry — title, category, credentials, notes, TOTP.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/password_generator.dart';
import '../../../../shared/widgets/safira_button.dart';
import '../../../../shared/widgets/safira_text_field.dart';
import '../providers/vault_provider.dart';

// ─── Categories ───────────────────────────────────────────────────────────────

const _kCategories = [
  'Login',
  'Email',
  'Banking',
  'Social',
  'Work',
  'Shopping',
  'Crypto',
  'Note',
  'Other',
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class VaultCreatePage extends ConsumerStatefulWidget {
  const VaultCreatePage({super.key});

  @override
  ConsumerState<VaultCreatePage> createState() => _VaultCreatePageState();
}

class _VaultCreatePageState extends ConsumerState<VaultCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _totpCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  String _category = _kCategories.first;
  bool _showPassword = false;
  bool _addTotp = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _usernameCtrl.dispose();
    _urlCtrl.dispose();
    _passwordCtrl.dispose();
    _notesCtrl.dispose();
    _totpCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  // ── Generate password ─────────────────────────────────────────────────

  void _generatePassword() {
    final pw = PasswordGenerator.generate(
      length: 20,
      uppercase: true,
      lowercase: true,
      digits: true,
      symbols: true,
    );
    _passwordCtrl.text = pw;
  }

  // ── Save ─────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await ref.read(vaultNotifierProvider.notifier).createEntry(
            title: _titleCtrl.text.trim(),
            category: _category,
            username: _usernameCtrl.text.trim().isEmpty
                ? null
                : _usernameCtrl.text.trim(),
            url:
                _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
            password: _passwordCtrl.text,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            totpSecret:
                _addTotp && _totpCtrl.text.trim().isNotEmpty
                    ? _totpCtrl.text.trim()
                    : null,
            tags: tags,
          );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Entry'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Title ──────────────────────────────────────────────
            SafiraTextField(
              controller: _titleCtrl,
              label: 'Title',
              hint: 'e.g. Google Account',
              prefixIcon: Icons.title_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Category ───────────────────────────────────────────
            Text('Category', style: tt.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kCategories.map((cat) {
                final selected = _category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: cs.primaryContainer,
                  labelStyle: TextStyle(
                    color: selected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Username ───────────────────────────────────────────
            SafiraTextField(
              controller: _usernameCtrl,
              label: 'Username / Email',
              hint: 'optional',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── URL ────────────────────────────────────────────────
            SafiraTextField(
              controller: _urlCtrl,
              label: 'Website URL',
              hint: 'https://example.com',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Password ───────────────────────────────────────────
            SafiraTextField(
              controller: _passwordCtrl,
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.next,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    tooltip: _showPassword ? 'Hide' : 'Show',
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    tooltip: 'Generate password',
                    onPressed: _generatePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Notes ──────────────────────────────────────────────
            SafiraTextField(
              controller: _notesCtrl,
              label: 'Notes',
              hint: 'optional',
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16),

            // ── Tags ───────────────────────────────────────────────
            SafiraTextField(
              controller: _tagsCtrl,
              label: 'Tags',
              hint: 'work, personal, finance  (comma-separated)',
              prefixIcon: Icons.label_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // ── TOTP ───────────────────────────────────────────────
            SwitchListTile(
              value: _addTotp,
              onChanged: (v) => setState(() => _addTotp = v),
              title: const Text('Add TOTP (2FA)'),
              subtitle: const Text('Paste your TOTP secret key'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_addTotp) ...[
              const SizedBox(height: 8),
              SafiraTextField(
                controller: _totpCtrl,
                label: 'TOTP Secret',
                hint: 'JBSWY3DPEHPK3PXP',
                prefixIcon: Icons.qr_code_rounded,
                textInputAction: TextInputAction.done,
              ),
            ],
            const SizedBox(height: 32),

            // ── Save button ────────────────────────────────────────
            SafiraButton(
              label: 'Save Entry',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
