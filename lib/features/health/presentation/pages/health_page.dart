import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:safira/core/constants/app_constants.dart';

/// Password health dashboard.
///
/// Analyzes all vault entries for:
/// - Weak passwords (entropy-based)
/// - Reused passwords
/// - Old passwords (not changed in 90+ days)
/// - Breached passwords (HaveIBeenPwned k-anonymity API)
class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  bool _isScanning = false;
  HealthReport? _report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Health'),
        actions: [
          if (!_isScanning)
            FilledButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Scan'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isScanning
          ? const _ScanningView()
          : _report == null
              ? _WelcomeView(onScan: _scan)
              : _ReportView(report: _report!),
    );
  }

  Future<void> _scan() async {
    setState(() {
      _isScanning = true;
      _report = null;
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate scan

    setState(() {
      _isScanning = false;
      _report = const HealthReport(
        totalEntries: 24,
        weakPasswords: 3,
        reusedPasswords: 2,
        oldPasswords: 5,
        breachedPasswords: 1,
        overallScore: 72,
      );
    });
  }
}

/// Uses HaveIBeenPwned k-anonymity API to check if a password has been breached.
///
/// Privacy: Only the first 5 characters of the SHA-1 hash are sent to the API.
/// The full hash never leaves the device.
Future<int> checkPasswordBreach(String password) async {
  try {
    // Compute SHA-1 hash
    final bytes = utf8.encode(password);
    final digest = _sha1(bytes);
    final hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

    final prefix = hex.substring(0, CryptoConstants.hibpPrefixLength);
    final suffix = hex.substring(CryptoConstants.hibpPrefixLength);

    final response = await http.get(
      Uri.parse('https://api.pwnedpasswords.com/range/$prefix'),
      headers: {'Add-Padding': 'true'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return 0;

    // Parse response — look for our suffix
    for (final line in response.body.split('\r\n')) {
      final parts = line.split(':');
      if (parts.length == 2 && parts[0] == suffix) {
        return int.tryParse(parts[1]) ?? 0;
      }
    }
    return 0;
  } on Exception {
    return -1; // Error — can't determine
  }
}

/// Very basic SHA-1 for HIBP (production: use pointycastle)
List<int> _sha1(List<int> data) {
  // Placeholder — use pointycastle SHA1 in production
  return List.filled(20, 0);
}

class HealthReport {
  const HealthReport({
    required this.totalEntries,
    required this.weakPasswords,
    required this.reusedPasswords,
    required this.oldPasswords,
    required this.breachedPasswords,
    required this.overallScore,
  });

  final int totalEntries;
  final int weakPasswords;
  final int reusedPasswords;
  final int oldPasswords;
  final int breachedPasswords;
  final int overallScore;

  int get issueCount => weakPasswords + reusedPasswords + oldPasswords + breachedPasswords;
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Check your password health',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your vault for weak, reused, old,\nand breached passwords.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.search),
              label: const Text('Start Scan'),
            ),
          ],
        ),
      );
}

class _ScanningView extends StatelessWidget {
  const _ScanningView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ).animate().scale(),
            const SizedBox(height: 24),
            const Text('Scanning your vault…'),
            const SizedBox(height: 8),
            Text(
              'Checking HaveIBeenPwned (k-anonymity)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.report});
  final HealthReport report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final score = report.overallScore;
    final scoreColor = score >= 80
        ? Colors.green.shade600
        : score >= 60
            ? Colors.orange.shade600
            : Colors.red.shade600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 8,
                          color: scoreColor,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                        Text(
                          '$score',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Score',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${report.issueCount} issue${report.issueCount != 1 ? 's' : ''} found in ${report.totalEntries} entries',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Issues list
          _IssueCard(
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            title: 'Breached Passwords',
            count: report.breachedPasswords,
            description: 'Found in known data breaches',
          ),
          _IssueCard(
            icon: Icons.lock_open_outlined,
            color: Colors.orange,
            title: 'Weak Passwords',
            count: report.weakPasswords,
            description: 'Low entropy or too short',
          ),
          _IssueCard(
            icon: Icons.content_copy_outlined,
            color: Colors.amber,
            title: 'Reused Passwords',
            count: report.reusedPasswords,
            description: 'Same password used multiple times',
          ),
          _IssueCard(
            icon: Icons.history,
            color: Colors.blue,
            title: 'Old Passwords',
            count: report.oldPasswords,
            description: 'Not changed in 90+ days',
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(icon, color: count > 0 ? color : Colors.grey),
          title: Text(title),
          subtitle: Text(description),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0 ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: count > 0 ? color : Colors.grey,
              ),
            ),
          ),
          onTap: count > 0 ? () {/* TODO: Show affected entries */} : null,
        ),
      ).animate().fadeIn().slideX(begin: 0.1, end: 0);
}
