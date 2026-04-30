import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safira/core/security/totp_engine.dart';

/// TOTP authenticator page — like Google Authenticator, built into Safira.
///
/// Shows all TOTP entries with live countdown timers.
/// Tapping a code copies it to clipboard.
class TotpPage extends ConsumerStatefulWidget {
  const TotpPage({super.key});

  @override
  ConsumerState<TotpPage> createState() => _TotpPageState();
}

class _TotpPageState extends ConsumerState<TotpPage> {
  Timer? _refreshTimer;

  // Demo entries — will be loaded from vault in production
  final _entries = [
    _TotpEntry(name: 'GitHub', issuer: 'GitHub', secret: 'JBSWY3DPEHPK3PXP'),
    _TotpEntry(name: 'Google', issuer: 'Google', secret: 'JBSWY3DPEHPK3PXP'),
  ];

  @override
  void initState() {
    super.initState();
    // Refresh codes every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR code',
            onPressed: () {/* TODO: QR scanner */},
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add manually',
            onPressed: _addManually,
          ),
        ],
      ),
      body: _entries.isEmpty
          ? _EmptyTotpView(onAdd: _addManually)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TotpCard(entry: _entries[i])
                    .animate(delay: Duration(milliseconds: i * 80))
                    .fadeIn()
                    .slideX(begin: 0.1, end: 0),
              ),
            ),
    );
  }

  void _addManually() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddTotpSheet(),
    );
  }
}

class _TotpCard extends StatelessWidget {
  const _TotpCard({required this.entry});
  final _TotpEntry entry;

  @override
  Widget build(BuildContext context) {
    final engine = TotpEngine.instance;
    final code = engine.generateCode(entry.secret);
    final remaining = engine.remainingSeconds;
    final progress = 1 - engine.windowProgress;
    final isExpiring = remaining <= 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    entry.issuer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Format code as XXX XXX
                    '${code.substring(0, 3)} ${code.substring(3)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: isExpiring
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                          letterSpacing: 4,
                        ),
                  ),
                ],
              ),
            ),

            // Countdown
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: isExpiring
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  Text(
                    '$remaining',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isExpiring
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTotpSheet extends StatefulWidget {
  const _AddTotpSheet();

  @override
  State<_AddTotpSheet> createState() => _AddTotpSheetState();
}

class _AddTotpSheetState extends State<_AddTotpSheet> {
  final _nameCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add TOTP', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secretCtrl,
              decoration: const InputDecoration(
                labelText: 'Secret Key',
                border: OutlineInputBorder(),
                hintText: 'Base32 encoded secret',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Add'),
            ),
          ],
        ),
      );
}

class _TotpEntry {
  _TotpEntry({required this.name, required this.issuer, required this.secret});
  final String name;
  final String issuer;
  final String secret;
}

class _EmptyTotpView extends StatelessWidget {
  const _EmptyTotpView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_outlined,
                size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('No TOTP accounts yet'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
            ),
          ],
        ),
      );
}
