import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureNotesPage extends ConsumerStatefulWidget {
  const SecureNotesPage({super.key});

  @override
  ConsumerState<SecureNotesPage> createState() => _SecureNotesPageState();
}

class _SecureNotesPageState extends ConsumerState<SecureNotesPage> {
  final _searchCtrl = TextEditingController();
  String _filter = '';

  // Demo notes — replace with real Isar-backed provider
  final List<_NoteItem> _notes = [
    _NoteItem(
      id: '1',
      title: 'WiFi Passwords',
      preview: 'Home: hunter2\nOffice: correct-horse-battery...',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      color: Colors.blue,
    ),
    _NoteItem(
      id: '2',
      title: 'Secret recipes',
      preview: '1 cup flour, 2 eggs, pinch of mystery...',
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      color: Colors.green,
    ),
    _NoteItem(
      id: '3',
      title: 'Recovery codes',
      preview: 'GitHub: a1b2-c3d4-e5f6\nGoogle: 9f8e-7d6c...',
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      color: Colors.orange,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_NoteItem> get _filtered => _filter.isEmpty
      ? _notes
      : _notes
          .where((n) =>
              n.title.toLowerCase().contains(_filter.toLowerCase()) ||
              n.preview.toLowerCase().contains(_filter.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Notes'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search notes…',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_filter.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _filter = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(height: 8),

          // Notes grid
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(hasFilter: _filter.isNotEmpty)
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) =>
                        _NoteCard(note: _filtered[i], onTap: _openNote),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNote,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New note'),
      ),
    );
  }

  void _openNote(_NoteItem note) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _NoteEditorPage(note: note),
      ),
    ).then((_) => setState(() {}));
  }

  void _createNote() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _NoteEditorPage(note: null),
      ),
    ).then((_) => setState(() {}));
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort by',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.access_time_rounded),
              title: const Text('Last modified'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded),
              title: const Text('Title (A–Z)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Date created'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Note Editor Page ────────────────────────────────────────────────────────

class _NoteEditorPage extends StatefulWidget {
  const _NoteEditorPage({this.note});
  final _NoteItem? note;

  @override
  State<_NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<_NoteEditorPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.note?.preview ?? '');
    _titleCtrl.addListener(_markDirty);
    _bodyCtrl.addListener(_markDirty);
  }

  void _markDirty() => setState(() => _isDirty = true);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isNew = widget.note == null;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final save = await _showUnsavedDialog();
          if (save == true && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNew ? 'New note' : 'Edit note'),
          actions: [
            if (_isDirty)
              FilledButton.tonal(
                onPressed: _save,
                child: const Text('Save'),
              ),
            if (!isNew)
              IconButton(
                icon: Icon(Icons.delete_rounded, color: cs.error),
                tooltip: 'Delete note',
                onPressed: _confirmDelete,
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title field
              TextField(
                controller: _titleCtrl,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 1,
                textCapitalization: TextCapitalization.sentences,
              ),
              const Divider(),
              // Body field
              Expanded(
                child: TextField(
                  controller: _bodyCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Write your note here…',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    // TODO: encrypt with session key and persist to Isar
    setState(() => _isDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved & encrypted')),
    );
  }

  void _confirmDelete() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content:
            const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) Navigator.pop(context);
    });
  }

  Future<bool?> _showUnsavedDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Do you want to save before leaving?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard')),
          FilledButton(
              onPressed: () {
                _save();
                Navigator.pop(context, true);
              },
              child: const Text('Save')),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});
  final _NoteItem note;
  final void Function(_NoteItem) onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: note.color.withOpacity(0.08),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(note),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_rounded, size: 18, color: note.color),
              const SizedBox(height: 8),
              Text(
                note.title,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note.preview,
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                  maxLines: 5,
                  overflow: TextOverflow.fade,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _timeAgo(note.updatedAt),
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurface.withOpacity(0.45)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No matching notes' : 'No notes yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 6),
            const Text('Tap + to create your first secure note'),
          ],
        ],
      ),
    );
  }
}

// ── Data model (replace with Isar entity) ───────────────────────────────────

class _NoteItem {
  const _NoteItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.color,
  });
  final String id;
  final String title;
  final String preview;
  final DateTime updatedAt;
  final Color color;
}
