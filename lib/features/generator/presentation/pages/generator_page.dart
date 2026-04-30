import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safira/core/security/clipboard_manager.dart';
import 'package:safira/core/security/password_generator.dart';

/// Advanced password generator page.
///
/// Features:
/// - Real-time generation with all configurable options
/// - Entropy display
/// - Passphrase mode
/// - Copy with auto-clear
/// - Password history (session only)
class GeneratorPage extends ConsumerStatefulWidget {
  const GeneratorPage({super.key});

  @override
  ConsumerState<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends ConsumerState<GeneratorPage> {
  PasswordOptions _options = const PasswordOptions(length: 20);
  String _generated = '';
  final _history = <String>[];
  bool _passphraseMode = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final pw = _passphraseMode
        ? PasswordGenerator.instance.generatePassphrase()
        : PasswordGenerator.instance.generate(_options);
    setState(() {
      _generated = pw;
      if (_history.isEmpty || _history.last != pw) {
        _history.insert(0, pw);
        if (_history.length > 20) _history.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Password Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Generated password display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  SelectableText(
                    _generated,
                    style: textTheme.titleLarge?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          await SecureClipboardManager.instance.copySecure(_generated);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied! Will clear in 30s')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Regenerate'),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // Mode toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Random'), icon: Icon(Icons.shuffle)),
                ButtonSegment(value: true, label: Text('Passphrase'), icon: Icon(Icons.text_fields)),
              ],
              selected: {_passphraseMode},
              onSelectionChanged: (s) {
                setState(() => _passphraseMode = s.first);
                _generate();
              },
            ),

            const SizedBox(height: 24),

            if (!_passphraseMode) ...[
              // Length slider
              Text('Length: ${_options.length}', style: textTheme.titleSmall),
              Slider(
                value: _options.length.toDouble(),
                min: 8,
                max: 64,
                divisions: 56,
                label: '${_options.length}',
                onChanged: (v) {
                  setState(() => _options = _options.copyWith(length: v.toInt()));
                  _generate();
                },
              ),

              const SizedBox(height: 16),

              // Character options
              Text('Character Types', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Lowercase'),
                    selected: _options.includeLowercase,
                    onSelected: (v) {
                      setState(() => _options = _options.copyWith(includeLowercase: v));
                      _generate();
                    },
                  ),
                  FilterChip(
                    label: const Text('Uppercase'),
                    selected: _options.includeUppercase,
                    onSelected: (v) {
                      setState(() => _options = _options.copyWith(includeUppercase: v));
                      _generate();
                    },
                  ),
                  FilterChip(
                    label: const Text('Numbers'),
                    selected: _options.includeDigits,
                    onSelected: (v) {
                      setState(() => _options = _options.copyWith(includeDigits: v));
                      _generate();
                    },
                  ),
                  FilterChip(
                    label: const Text('Symbols'),
                    selected: _options.includeSymbols,
                    onSelected: (v) {
                      setState(() => _options = _options.copyWith(includeSymbols: v));
                      _generate();
                    },
                  ),
                  FilterChip(
                    label: const Text('Exclude Ambiguous'),
                    selected: _options.excludeAmbiguous,
                    onSelected: (v) {
                      setState(() => _options = _options.copyWith(excludeAmbiguous: v));
                      _generate();
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // History
            if (_history.length > 1) ...[
              Text('Recent', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._history.skip(1).take(5).map(
                    (pw) => ListTile(
                      dense: true,
                      title: Text(
                        pw,
                        style: const TextStyle(fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => Clipboard.setData(ClipboardData(text: pw)),
                      ),
                      onTap: () => setState(() => _generated = pw),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
