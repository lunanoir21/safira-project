import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportExportPage extends ConsumerStatefulWidget {
  const ImportExportPage({super.key});

  @override
  ConsumerState<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends ConsumerState<ImportExportPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import & Export'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.download_rounded), text: 'Import'),
            Tab(icon: Icon(Icons.upload_rounded), text: 'Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ImportTab(),
          _ExportTab(),
        ],
      ),
    );
  }
}

// ── Import Tab ───────────────────────────────────────────────────────────────

class _ImportTab extends StatefulWidget {
  const _ImportTab();

  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab> {
  _ImportFormat? _selectedFormat;
  bool _isImporting = false;
  int _importedCount = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info banner
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.info_rounded, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Imports are processed locally — your data never leaves the device.',
                  style:
                      TextStyle(color: cs.onPrimaryContainer, fontSize: 13),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        Text('Choose format',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),

        // Format picker
        ..._ImportFormat.values.map((fmt) => _FormatCard(
              format: fmt,
              selected: _selectedFormat == fmt,
              onTap: () => setState(() => _selectedFormat = fmt),
            )),

        const SizedBox(height: 24),

        if (_importedCount > 0) ...[
          Card(
            color: cs.secondaryContainer,
            child: ListTile(
              leading: Icon(Icons.check_circle_rounded,
                  color: cs.secondary),
              title: Text('$_importedCount entries imported'),
              subtitle: const Text('All entries have been added to your vault'),
            ),
          ),
          const SizedBox(height: 16),
        ],

        FilledButton.icon(
          icon: _isImporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.folder_open_rounded),
          label: Text(_isImporting ? 'Importing…' : 'Select file to import'),
          onPressed: _selectedFormat == null || _isImporting
              ? null
              : _pickAndImport,
        ),
      ],
    );
  }

  Future<void> _pickAndImport() async {
    if (_selectedFormat == null) return;
    setState(() => _isImporting = true);

    // Simulate import — wire up real file_picker + parser in production
    await Future<void>.delayed(const Duration(seconds: 2));

    setState(() {
      _isImporting = false;
      _importedCount = 42; // demo value
    });
  }
}

// ── Export Tab ───────────────────────────────────────────────────────────────

class _ExportTab extends StatefulWidget {
  const _ExportTab();

  @override
  State<_ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends State<_ExportTab> {
  _ExportFormat _selectedFormat = _ExportFormat.encrypted;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Warning
        if (_selectedFormat != _ExportFormat.encrypted)
          Card(
            color: cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: cs.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unencrypted exports contain your passwords in plain text. '
                    'Handle the file with care.',
                    style:
                        TextStyle(color: cs.onErrorContainer, fontSize: 13),
                  ),
                ),
              ]),
            ),
          ),

        if (_selectedFormat == _ExportFormat.encrypted)
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.lock_rounded, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Encrypted backup — protected with your master password.',
                    style:
                        TextStyle(color: cs.onPrimaryContainer, fontSize: 13),
                  ),
                ),
              ]),
            ),
          ),

        const SizedBox(height: 24),
        Text('Export format',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),

        ..._ExportFormat.values.map((fmt) => RadioListTile<_ExportFormat>(
              value: fmt,
              groupValue: _selectedFormat,
              onChanged: (v) => setState(() => _selectedFormat = v!),
              title: Text(fmt.label),
              subtitle: Text(fmt.description),
              secondary: Icon(fmt.icon,
                  color: fmt == _ExportFormat.encrypted
                      ? cs.primary
                      : cs.outline),
            )),

        const SizedBox(height: 24),

        FilledButton.icon(
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_alt_rounded),
          label: Text(_isExporting ? 'Exporting…' : 'Export vault'),
          onPressed: _isExporting ? null : _export,
        ),
      ],
    );
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault exported successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.format,
    required this.selected,
    required this.onTap,
  });
  final _ImportFormat format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? cs.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide(color: cs.outline.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (selected ? cs.primary : cs.outline).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(format.icon,
                  color: selected ? cs.primary : cs.outline),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(format.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                              color: selected ? cs.primary : null,
                              fontWeight: FontWeight.w600)),
                  Text(format.description,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: cs.primary),
          ]),
        ),
      ),
    );
  }
}

// ── Enums ────────────────────────────────────────────────────────────────────

enum _ImportFormat {
  bitwarden(
    label: 'Bitwarden',
    description: 'JSON export from Bitwarden / Vaultwarden',
    icon: Icons.shield_rounded,
  ),
  keepass(
    label: 'KeePass',
    description: 'KeePass CSV or XML export',
    icon: Icons.vpn_key_rounded,
  ),
  onePassword(
    label: '1Password',
    description: '1Password 1PUX or CSV export',
    icon: Icons.looks_one_rounded,
  ),
  csv(
    label: 'Generic CSV',
    description: 'Columns: name, username, password, url, notes',
    icon: Icons.table_chart_rounded,
  );

  const _ImportFormat(
      {required this.label,
      required this.description,
      required this.icon});
  final String label;
  final String description;
  final IconData icon;
}

enum _ExportFormat {
  encrypted(
    label: 'Encrypted backup (.safira)',
    description: 'AES-256-GCM encrypted, requires master password to restore',
    icon: Icons.lock_rounded,
  ),
  bitwardenJson(
    label: 'Bitwarden JSON (unencrypted)',
    description: 'Compatible with Bitwarden / Vaultwarden import',
    icon: Icons.code_rounded,
  ),
  csv(
    label: 'CSV (unencrypted)',
    description: 'Plain-text spreadsheet — handle with care',
    icon: Icons.table_chart_rounded,
  );

  const _ExportFormat(
      {required this.label,
      required this.description,
      required this.icon});
  final String label;
  final String description;
  final IconData icon;
}
