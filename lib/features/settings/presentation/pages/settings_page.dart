import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/session_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _biometricEnabled = false;
  bool _clipboardAutoClear = true;
  int _autoLockMinutes = 5;
  int _clipboardClearSeconds = 30;
  SafiraThemeMode _themeMode = SafiraThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Security ──────────────────────────────────────────
          _SectionHeader(label: 'Security', icon: Icons.security_rounded),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.fingerprint_rounded,
              iconColor: cs.primary,
              title: 'Biometric unlock',
              subtitle: 'Use fingerprint or face to unlock the vault',
              value: _biometricEnabled,
              onChanged: (v) => setState(() => _biometricEnabled = v),
            ),
            const Divider(height: 1),
            _SliderTile(
              icon: Icons.lock_clock_rounded,
              iconColor: cs.primary,
              title: 'Auto-lock after',
              value: _autoLockMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 11,
              label: '$_autoLockMinutes min',
              onChanged: (v) => setState(() => _autoLockMinutes = v.round()),
            ),
            const Divider(height: 1),
            _ActionTile(
              icon: Icons.password_rounded,
              iconColor: cs.error,
              title: 'Change master password',
              subtitle: 'Re-derive vault encryption key',
              onTap: () => _showChangeMasterPassword(context),
            ),
            const Divider(height: 1),
            _ActionTile(
              icon: Icons.delete_forever_rounded,
              iconColor: cs.error,
              title: 'Wipe vault',
              subtitle: 'Permanently delete all vault data',
              onTap: () => _showWipeConfirmation(context),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Clipboard ────────────────────────────────────────
          _SectionHeader(label: 'Clipboard', icon: Icons.content_paste_rounded),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.timer_rounded,
              iconColor: cs.tertiary,
              title: 'Auto-clear clipboard',
              subtitle: 'Clear copied passwords automatically',
              value: _clipboardAutoClear,
              onChanged: (v) => setState(() => _clipboardAutoClear = v),
            ),
            if (_clipboardAutoClear) ...[
              const Divider(height: 1),
              _SliderTile(
                icon: Icons.hourglass_bottom_rounded,
                iconColor: cs.tertiary,
                title: 'Clear after',
                value: _clipboardClearSeconds.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                label: '${_clipboardClearSeconds}s',
                onChanged: (v) =>
                    setState(() => _clipboardClearSeconds = v.round()),
              ),
            ],
          ]),
          const SizedBox(height: 24),

          // ── Appearance ───────────────────────────────────────
          _SectionHeader(label: 'Appearance', icon: Icons.palette_rounded),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.dark_mode_rounded,
                        color: cs.secondary, size: 22),
                    const SizedBox(width: 12),
                    Text('Theme mode', style: tt.titleSmall),
                  ]),
                  const SizedBox(height: 12),
                  SegmentedButton<SafiraThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: SafiraThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded)),
                      ButtonSegment(
                          value: SafiraThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded)),
                      ButtonSegment(
                          value: SafiraThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded)),
                    ],
                    selected: {_themeMode},
                    onSelectionChanged: (s) =>
                        setState(() => _themeMode = s.first),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // ── Backup & Export ───────────────────────────────────
          _SectionHeader(
              label: 'Backup & Export', icon: Icons.backup_rounded),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _ActionTile(
              icon: Icons.upload_file_rounded,
              iconColor: cs.primary,
              title: 'Export vault',
              subtitle: 'Save an encrypted backup file',
              onTap: () => context.push(RoutePaths.importExport),
            ),
            const Divider(height: 1),
            _ActionTile(
              icon: Icons.download_rounded,
              iconColor: cs.primary,
              title: 'Import from file',
              subtitle: 'Bitwarden, KeePass, 1Password CSV',
              onTap: () => context.push(RoutePaths.importExport),
            ),
          ]),
          const SizedBox(height: 24),

          // ── About ────────────────────────────────────────────
          _SectionHeader(label: 'About', icon: Icons.info_rounded),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _InfoTile(
                label: 'Version', value: AppConstants.appVersion),
            const Divider(height: 1),
            _InfoTile(label: 'Build', value: 'open-source / MIT'),
            const Divider(height: 1),
            _ActionTile(
              icon: Icons.code_rounded,
              iconColor: cs.outline,
              title: 'Source code',
              subtitle: 'github.com/lunanoir21/safira-project',
              onTap: () {},
            ),
            const Divider(height: 1),
            _ActionTile(
              icon: Icons.bug_report_rounded,
              iconColor: cs.outline,
              title: 'Report an issue',
              subtitle: 'Open a GitHub issue',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),

          // ── Danger Zone ──────────────────────────────────────
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Lock vault now'),
              style:
                  TextButton.styleFrom(foregroundColor: cs.error),
              onPressed: () {
                ref.read(sessionProvider.notifier).lock();
                context.go(RoutePaths.lock);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────

  void _showChangeMasterPassword(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change master password'),
        content: const Text(
            'This will re-derive the vault encryption key and re-encrypt all entries. '
            'This feature will be available in v1.1.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  void _showWipeConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        title: const Text('Wipe vault?'),
        content: const Text(
            'This will permanently delete ALL vault data including passwords, '
            'notes and settings. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              // TODO: wipe Isar + navigate to onboarding
            },
            child: const Text('Wipe everything'),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, size: 16, color: cs.primary),
      const SizedBox(width: 6),
      Text(label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: Theme.of(context).colorScheme.primary)),
            ]),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.outline)),
    );
  }
}
