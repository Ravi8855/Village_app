import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/auth_repository.dart';
import '../../../../core/config/env_config.dart';
import '../../../../shared/widgets/announcement_category_chip.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_status_widgets.dart';
import '../../domain/announcement.dart';
import '../../domain/announcement_category.dart';
import '../news_providers.dart';
import 'admin_login_page.dart';
import '../widgets/admin_announcement_form.dart';

class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncNews = ref.watch(newsListNotifierProvider);
    final query = ref.watch(newsSearchQueryProvider);
    final categoryFilter = ref.watch(newsCategoryFilterProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News & announcements'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout_rounded),
            )
          else
            IconButton(
              tooltip: 'Admin sign in',
              onPressed: () async {
                final signedIn = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                );
                if (signedIn == true && mounted) {
                  ref.invalidate(authStateProvider);
                  ref.invalidate(isAdminProvider);
                  ref.invalidate(newsListNotifierProvider);
                }
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openComposer(context),
              icon: const Icon(Icons.post_add_rounded),
              label: const Text('Post update'),
            )
          : null,
      body: Column(
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.verified_user, size: 18),
                  label: Text('Admin: ${authUser?.email ?? ''}'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search announcements…',
              leading: const Icon(Icons.search),
              trailing: [
                if (query.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(newsSearchQueryProvider.notifier).state = '';
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
              onChanged: (value) {
                ref.read(newsSearchQueryProvider.notifier).state =
                    value.trim().toLowerCase();
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: categoryFilter == null,
                    onSelected: (_) {
                      ref.read(newsCategoryFilterProvider.notifier).state = null;
                    },
                  ),
                ),
                for (final category in AnnouncementCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.label),
                      selected: categoryFilter == category,
                      onSelected: (_) {
                        ref.read(newsCategoryFilterProvider.notifier).state =
                            category;
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: asyncNews.when(
              data: (items) {
                final filtered = items.where((a) {
                  if (categoryFilter != null && a.category != categoryFilter) {
                    return false;
                  }
                  if (query.isEmpty) return true;
                  final hay = '${a.title} ${a.description}'.toLowerCase();
                  return hay.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: 'No announcements match',
                    message: isAdmin
                        ? 'Tap Post update to publish the first village notice.'
                        : 'Check back later for Panchayat updates.',
                    icon: Icons.newspaper_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(newsListNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final a = filtered[index];
                      return _AnnouncementCard(
                        announcement: a,
                        isAdmin: isAdmin,
                        onEdit: () => _openComposer(context, existing: a),
                        onDelete: () => _confirmDelete(a),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const AppLoading(message: 'Fetching village updates…'),
              error: (e, _) => AppError(
                message: e.toString(),
                onRetry: () => ref.invalidate(newsListNotifierProvider),
              ),
            ),
          ),
          if (!EnvConfig.supabaseEnabled)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Offline demo mode — connect Supabase for live sync.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openComposer(
    BuildContext context, {
    Announcement? existing,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AdminAnnouncementForm(existing: existing),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Announcement published.' : 'Announcement updated.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: Text('Remove “${announcement.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(newsListNotifierProvider.notifier)
          .deleteAnnouncement(announcement.id);
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final Announcement announcement;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement.imageUrl != null &&
                announcement.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    announcement.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Row(
              children: [
                AnnouncementCategoryChip(category: announcement.category),
                if (!announcement.isActive) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Hidden'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                const Spacer(),
                Text(
                  DateFormat('MMM d').format(announcement.createdAt),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              announcement.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              announcement.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
