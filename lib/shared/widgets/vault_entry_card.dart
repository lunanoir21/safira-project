import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/core/security/clipboard_manager.dart';

/// A Material 3 card representing a single vault entry.
///
/// Features:
/// - Animated entrance
/// - Swipe to favorite / delete
/// - Long press for context menu
/// - Copy password on tap
/// - Favicon / icon display
/// - TOTP badge indicator
class VaultEntryCard extends StatelessWidget {
  const VaultEntryCard({
    super.key,
    required this.title,
    required this.username,
    this.url,
    this.categoryIcon,
    this.categoryColor,
    this.isFavorite = false,
    this.hasTOTP = false,
    this.isDeleted = false,
    this.onTap,
    this.onFavoriteTap,
    this.onDeleteTap,
    this.onCopyPassword,
    this.animationDelay,
  });

  final String title;
  final String username;
  final String? url;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final bool isFavorite;
  final bool hasTOTP;
  final bool isDeleted;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onDeleteTap;
  final Future<String?> Function()? onCopyPassword;
  final Duration? animationDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = categoryColor ?? colorScheme.primary;

    Widget card = Dismissible(
      key: ValueKey(title + username),
      background: _buildSwipeBackground(
        context,
        icon: Icons.favorite,
        color: Colors.pink.shade400,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        icon: Icons.delete_outline,
        color: colorScheme.error,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onFavoriteTap?.call();
          return false; // Don't actually dismiss
        } else {
          return await _confirmDelete(context);
        }
      },
      onDismissed: (_) => onDeleteTap?.call(),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusLarge),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          borderRadius: BorderRadius.circular(UiConstants.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon / Avatar
                _EntryAvatar(
                  title: title,
                  icon: categoryIcon,
                  color: accentColor,
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Badges + actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasTOTP)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: 'Has TOTP',
                          child: Icon(
                            Icons.lock_clock_outlined,
                            size: 16,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ),
                    if (isFavorite)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.pink.shade400,
                        ),
                      ),
                    if (onCopyPassword != null)
                      Tooltip(
                        message: 'Copy password',
                        child: IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          iconSize: 18,
                          onPressed: () => _copyPassword(context),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Animate entrance
    if (animationDelay != null) {
      card = card
          .animate(delay: animationDelay)
          .fadeIn(duration: UiConstants.animationDurationNormal)
          .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
    }

    return card;
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Alignment alignment,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(UiConstants.radiusLarge),
        ),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(icon, color: Colors.white),
      );

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('"$title" will be moved to the trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(ctx);
                onTap?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy Password'),
              onTap: () {
                Navigator.pop(ctx);
                _copyPassword(context);
              },
            ),
            ListTile(
              leading: Icon(isFavorite ? Icons.favorite_border : Icons.favorite),
              title: Text(isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                Navigator.pop(ctx);
                onFavoriteTap?.call();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text(
                'Move to Trash',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDeleteTap?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyPassword(BuildContext context) async {
    if (onCopyPassword == null) return;
    final password = await onCopyPassword!();
    if (password != null && context.mounted) {
      await SecureClipboardManager.instance.copySecure(
        password,
        onCleared: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Clipboard cleared'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password copied — will clear in 30s'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

/// Circular avatar for vault entries.
class _EntryAvatar extends StatelessWidget {
  const _EntryAvatar({
    required this.title,
    required this.color,
    this.icon,
  });

  final String title;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: color, size: 22)
              : Text(
                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      );
}
