import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/features/vault/presentation/providers/vault_provider.dart';
import 'package:safira/shared/widgets/safira_button.dart';
import 'package:safira/shared/widgets/vault_entry_card.dart';

/// Main dashboard — the app's primary screen after unlock.
///
/// Features:
/// - Searchable, filterable vault list
/// - Category tabs
/// - FAB for new entry
/// - Linux keyboard shortcuts (Ctrl+N, Ctrl+F, Ctrl+L)
/// - Responsive layout (sidebar on desktop)
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late final TabController _tabController;

  static const _categories = ['All', 'Login', 'Card', 'Identity', 'Note', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedCategory = _categories[_tabController.index]);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= UiConstants.desktopBreakpoint;

    return CallbackShortcuts(
      bindings: {
        // Ctrl+N: New entry
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            context.push(RoutePaths.vaultCreate),
        // Ctrl+F: Focus search
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            FocusScope.of(context).requestFocus(FocusNode()),
        // Ctrl+L: Lock
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): () =>
            ref.read(appStateProvider.notifier).lock(),
        // Ctrl+G: Generator
        const SingleActivator(LogicalKeyboardKey.keyG, control: true): () =>
            context.push(RoutePaths.generator),
      },
      child: Focus(
        autofocus: true,
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() => Scaffold(
        appBar: _buildAppBar(),
        drawer: _buildNavigationDrawer(),
        body: _buildBody(),
        floatingActionButton: _buildFAB(),
      );

  Widget _buildDesktopLayout() => Scaffold(
        body: Row(
          children: [
            // Sidebar navigation
            NavigationRail(
              selectedIndex: 0,
              onDestinationSelected: _onNavRailDestination,
              extended: MediaQuery.sizeOf(context).width > 1200,
              leading: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.lock_outline),
                  selectedIcon: Icon(Icons.lock),
                  label: Text('Vault'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.password_outlined),
                  selectedIcon: Icon(Icons.password),
                  label: Text('Generator'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.lock_clock_outlined),
                  selectedIcon: Icon(Icons.lock_clock),
                  label: Text('TOTP'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.health_and_safety_outlined),
                  selectedIcon: Icon(Icons.health_and_safety),
                  label: Text('Health'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
              trailing: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.lock_outline),
                  tooltip: 'Lock vault (Ctrl+L)',
                  onPressed: () => ref.read(appStateProvider.notifier).lock(),
                ),
              ),
            ),
            const VerticalDivider(width: 1),

            // Main content
            Expanded(
              child: Scaffold(
                appBar: _buildAppBar(showMenuButton: false),
                body: _buildBody(),
                floatingActionButton: _buildFAB(),
              ),
            ),
          ],
        ),
      );

  AppBar _buildAppBar({bool showMenuButton = true}) => AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined),
            tooltip: 'Password Health',
            onPressed: () => context.push(RoutePaths.health),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      );

  Widget _buildBody() {
    final vaultState = ref.watch(vaultProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search passwords…',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Vault list
        Expanded(
          child: switch (vaultState) {
            VaultLoading() => const Center(child: CircularProgressIndicator()),
            VaultError(:final message) => _ErrorView(message: message),
            VaultLoaded(:final entries) => entries.isEmpty
                ? _EmptyVault(onAdd: () => context.push(RoutePaths.vaultCreate))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final entry = entries[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: VaultEntryCard(
                          title: entry.title,
                          username: entry.username,
                          url: entry.url,
                          hasTOTP: entry.hasTOTP,
                          animationDelay: Duration(milliseconds: i * 50),
                          onTap: () => context.push('/dashboard/vault/entry/${entry.id}'),
                          onFavoriteTap: () => ref
                              .read(vaultProvider.notifier)
                              .toggleFavorite(entry.id.toString()),
                          onDeleteTap: () => ref
                              .read(vaultProvider.notifier)
                              .deleteEntry(entry.id.toString()),
                        ),
                      );
                    },
                  ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }

  Widget _buildFAB() => FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.vaultCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
        tooltip: 'New entry (Ctrl+N)',
      );

  Widget _buildNavigationDrawer() => NavigationDrawer(
        selectedIndex: 0,
        onDestinationSelected: _onNavRailDestination,
        children: const [
          NavigationDrawerDestination(
            icon: Icon(Icons.lock_outline),
            label: Text('Vault'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.password_outlined),
            label: Text('Generator'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.lock_clock_outlined),
            label: Text('TOTP'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            label: Text('Health'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            label: Text('Settings'),
          ),
        ],
      );

  void _onNavRailDestination(int index) {
    switch (index) {
      case 0: break; // Already on vault
      case 1: context.push(RoutePaths.generator);
      case 2: context.push(RoutePaths.totp);
      case 3: context.push(RoutePaths.health);
      case 4: context.push(RoutePaths.settings);
    }
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ).animate().fadeIn(duration: 600.ms).scale(),
            const SizedBox(height: 16),
            Text(
              'Your vault is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Add your first password to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            SafiraButton(
              label: 'Add Password',
              icon: Icons.add,
              isFullWidth: false,
              onPressed: onAdd,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      );
}

// Placeholder — will be replaced by actual appStateProvider import
extension _AppStateX on WidgetRef {
  dynamic get appStateProvider => throw UnimplementedError();
}
