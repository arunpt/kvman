import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/features/billing/billing_provider.dart';
import 'package:shimmer/shimmer.dart';

class PlanHistoryScreen extends ConsumerWidget {
  const PlanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncData = ref.watch(planHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plan History')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(planHistoryProvider);
        },
        child: asyncData.when(
          loading: () => _buildSkeleton(isDark, theme),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load plans',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(planHistoryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (plans) {
            if (plans.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No plans found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = plans[index];
                return Card(
                  elevation: 0,
                  color: isDark
                      ? const Color(0xFF16161E)
                      : theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withAlpha(12)
                          : Colors.black.withAlpha(12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDateColumn(
                              context,
                              'Activated',
                              item.formattedActivationDate,
                              Icons.play_circle_outline,
                            ),
                            const Icon(
                              Icons.arrow_forward_outlined,
                              color: Colors.grey,
                              size: 16,
                            ),
                            _buildDateColumn(
                              context,
                              (item.expiryDate != null &&
                                      item.expiryDate!.isBefore(DateTime.now()))
                                  ? 'Expired'
                                  : 'Expires',
                              item.formattedExpiryDate,
                              Icons.stop_circle_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withAlpha(12)
                                : Colors.black.withAlpha(12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Used',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.usedQuota,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Remaining',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.remainQuota,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateColumn(
    BuildContext context,
    String label,
    String date,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(bool isDark, ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [_shimmerBox(180, 16, isDark)]),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(60, 12, isDark),
                        const SizedBox(height: 6),
                        _shimmerBox(100, 14, isDark),
                      ],
                    ),
                    _shimmerBox(16, 16, isDark),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(60, 12, isDark),
                        const SizedBox(height: 6),
                        _shimmerBox(100, 14, isDark),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _shimmerBox(double.infinity, 60, isDark, borderRadius: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerBox(
    double width,
    double height,
    bool isDark, {
    double borderRadius = 4,
    BoxShape shape = BoxShape.rectangle,
  }) {
    final baseColor = isDark
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(20);
    final highlightColor = isDark
        ? Colors.white.withAlpha(40)
        : Colors.black.withAlpha(40);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadius),
          shape: shape,
        ),
      ),
    );
  }
}
