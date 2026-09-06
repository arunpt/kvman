import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kvman/features/home/home_repository.dart';
import 'package:kvman/features/home/subscriber_plan.dart';
import 'package:kvman/features/profile/profile_repository.dart';
import 'package:kvman/features/profile/customer_detail.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentPlanProvider);
    final customerDetailAsync = ref.watch(customerDetailProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await Future.wait([
              ref.refresh(currentPlanProvider.future),
              ref.refresh(customerDetailProvider.future),
            ]);
          } catch (_) {}
        },
        child: planAsync.when(
          skipLoadingOnRefresh: false,
          data: (planData) {
            if (planData.currentPlans.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(child: Text('No active plan found.')),
                ],
              );
            }

            final plan = planData.currentPlans.first;
            final isActive = plan.status.toLowerCase() == 'active';

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildPlanCard(context, plan, isActive, isDark),
                const SizedBox(height: 16),
                
                // Data Usage & Expiry Section
                customerDetailAsync.when(
                  skipLoadingOnRefresh: false,
                  data: (customerData) => Column(
                    children: [
                      _buildDataUsageCard(context, ref, customerData, isDark),
                      const SizedBox(height: 16),
                      _buildExpiryCard(context, customerData, isDark),
                    ],
                  ),
                  loading: () => Column(
                    children: [
                      _buildUsageSkeleton(context, isDark),
                      const SizedBox(height: 16),
                      _buildExpirySkeleton(context, isDark),
                    ],
                  ),
                  error: (e, st) => Center(child: Text('Failed to load usage details: $e')),
                ),
              ],
            );
          },
          loading: () => _buildFullSkeleton(context, isDark),
          error: (e, st) => ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SizedBox(height: 100),
              Center(child: Text('Error: $e')),
              const SizedBox(height: 16),
              Center(
                child: FilledButton(
                  onPressed: () {
                    ref.invalidate(currentPlanProvider);
                    ref.invalidate(customerDetailProvider);
                  },
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, CurrentPlan plan, bool isActive, bool isDark) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    // Status colors
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusIcon = isActive ? Icons.check : Icons.close;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Icon Indicator
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark 
                          ? Colors.white.withAlpha(8) 
                          : primaryColor.withAlpha(12),
                      border: Border.all(
                        color: isDark 
                            ? Colors.white.withAlpha(12) 
                            : primaryColor.withAlpha(25),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.wifi,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        statusIcon,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Plan Details Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Plan',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.planName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${plan.mrp} / month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${plan.status}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
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
  }

  Widget _buildDataUsageCard(BuildContext context, WidgetRef ref, CustomerDetail customer, bool isDark) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final totalGB = (customer.primaryAllocatedQuotaMB / 1024).round();
    final usedGB = (customer.primaryUsedQuotaMB / 1024).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    
    final totalDataFormatted = totalGB == 0 ? 'Unlimited' : '$totalGB GB';
    final usedDataStr = '$usedGB GB';
    
    double progress = 0.0;
    if (customer.primaryAllocatedQuotaMB > 0) {
      progress = (customer.primaryUsedQuotaMB / customer.primaryAllocatedQuotaMB).clamp(0.0, 1.0);
    } else {
      progress = 1.0; 
    }

    String cycleRange = 'Current cycle';
    if (customer.planActivationDate != null && customer.planExpiryDate != null) {
      final start = _formatDate(customer.planActivationDate!);
      final end = _formatDate(customer.planExpiryDate!);
      cycleRange = '$start – $end';
    }

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data Usage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => ref.invalidate(customerDetailProvider),
                  icon: Icon(Icons.refresh, color: primaryColor, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Refresh Usage',
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Middle Body Row
            Row(
              children: [
                // Circular Progress
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progress),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 12,
                              backgroundColor: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
                              color: primaryColor,
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Used',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            usedDataStr,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'of $totalDataFormatted',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Text description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data limit: $totalDataFormatted',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep track of your usage to avoid overages.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom Cycle Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current cycle',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cycleRange,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.iconTheme.color?.withAlpha(128),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryCard(BuildContext context, CustomerDetail customer, bool isDark) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    int totalDays = 1;
    int elapsedDays = 0;
    int remainingDays = 0;
    String startText = '';
    String endText = '';
    
    if (customer.planActivationDate != null && customer.planExpiryDate != null) {
      final startDate = customer.planActivationDate!;
      final endDate = customer.planExpiryDate!;
      
      startText = _formatDate(startDate);
      endText = _formatDate(endDate);
      
      totalDays = endDate.difference(startDate).inDays;
      if (totalDays <= 0) totalDays = 1;
      
      final now = DateTime.now();
      elapsedDays = now.difference(startDate).inDays;
      remainingDays = endDate.difference(now).inDays;
    }
    
    final progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
    final remainingStr = remainingDays < 0 ? 'Expired' : '$remainingDays days left';

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plan Expiry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  remainingStr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 12,
                    backgroundColor: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  startText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  endText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullSkeleton(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPlanCardSkeleton(context, isDark),
        const SizedBox(height: 16),
        _buildUsageSkeleton(context, isDark),
        const SizedBox(height: 16),
        _buildExpirySkeleton(context, isDark),
      ],
    );
  }

  Widget _buildUsageSkeleton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data Usage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: null,
                  icon: Icon(Icons.refresh, color: theme.disabledColor, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Middle Body Row
            Row(
              children: [
                // Circular Progress
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: 0.0,
                          strokeWidth: 12,
                          backgroundColor: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
                          color: primaryColor,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Used',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _shimmerBox(60, 24, isDark),
                          const SizedBox(height: 6),
                          _shimmerBox(80, 12, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Text description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(110, 16, isDark),
                      const SizedBox(height: 12),
                      Text(
                        'Keep track of your usage to avoid overages.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom Cycle Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current cycle',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _shimmerBox(140, 14, isDark),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.iconTheme.color?.withAlpha(128),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCardSkeleton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Icon Indicator (static outline)
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withAlpha(8) : primaryColor.withAlpha(12),
                      border: Border.all(
                        color: isDark ? Colors.white.withAlpha(12) : primaryColor.withAlpha(25),
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.wifi, color: primaryColor, size: 28),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.circle, size: 14, color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Plan Details Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Plan',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _shimmerBox(140, 18, isDark),
                  const SizedBox(height: 8),
                  _shimmerBox(100, 12, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpirySkeleton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plan Expiry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _shimmerBox(80, 14, isDark),
              ],
            ),
            const SizedBox(height: 20),
            _shimmerBox(double.infinity, 12, isDark),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(60, 12, isDark),
                _shimmerBox(60, 12, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, bool isDark) {
    final baseColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20);
    final highlightColor = isDark ? Colors.white.withAlpha(40) : Colors.black.withAlpha(40);
    
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
