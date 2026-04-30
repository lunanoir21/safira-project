import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safira/core/security/clipboard_manager.dart';
import 'package:safira/shared/widgets/safira_button.dart';
import 'package:safira/shared/widgets/safira_text_field.dart';

/// Detail view for a single vault entry.
class VaultEntryPage extends ConsumerWidget {
  const VaultEntryPage({super.key, required this.entryId});
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {/* TODO: navigate to edit */},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {/* TODO: delete with confirm */},
            color: colorScheme.error,
          ),
        ],
      ),
      body: const Center(child: Text('Entry detail — ID rendering here')),
    );
  }
}
