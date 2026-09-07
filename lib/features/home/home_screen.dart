import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

            final customerData = customerDetailAsync.asData?.value;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (customerData != null)
                  _buildSmartBanner(context, customerData, isDark),
                _buildPlanCard(context, planData, isDark),
                const SizedBox(height: 16),

                // Data Usage & Expiry Section
                customerDetailAsync.when(
                  skipLoadingOnRefresh: false,
                  data: (customerData) => Column(
                    children: [
                      _buildDataUsageCard(context, ref, customerData, isDark),
                      const SizedBox(height: 16),
                      _buildExpiryCard(context, customerData, isDark),
                      const SizedBox(height: 24),
                      _buildQuickActions(context, isDark),
                    ],
                  ),
                  loading: () => Column(
                    children: [
                      _buildUsageSkeleton(context, isDark),
                      const SizedBox(height: 16),
                      _buildExpirySkeleton(context, isDark),
                    ],
                  ),
                  error: (e, st) =>
                      Center(child: Text('Failed to load usage details: $e')),
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

  Widget _buildSmartBanner(
    BuildContext context,
    CustomerDetail customer,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    final bool isLowData =
        customer.primaryAllocatedQuotaMB > 0 &&
        (customer.primaryUsedQuotaMB / customer.primaryAllocatedQuotaMB) >= 0.9;
    final bool isExpiringSoon =
        customer.planRemainingDays > 0 && customer.planRemainingDays <= 3;
    final bool isExpired = customer.planRemainingDays <= 0;

    if (!isLowData && !isExpiringSoon && !isExpired) {
      return const SizedBox.shrink();
    }

    String message;
    IconData icon;
    Color bgColor;
    Color fgColor;

    if (isExpired) {
      message = 'Your plan has expired. Please renew to continue services.';
      icon = Icons.error_outline;
      bgColor = Colors.red.withAlpha(isDark ? 50 : 30);
      fgColor = Colors.red;
    } else if (isExpiringSoon) {
      message = 'Your plan expires in ${customer.planRemainingDays} days.';
      icon = Icons.warning_amber_rounded;
      bgColor = Colors.orange.withAlpha(isDark ? 50 : 30);
      fgColor = Colors.orange.shade800;
    } else {
      message = 'You have used over 90% of your data quota.';
      icon = Icons.data_usage;
      bgColor = Colors.orange.withAlpha(isDark ? 50 : 30);
      fgColor = Colors.orange.shade800;
    }

    if (isDark && fgColor == Colors.orange.shade800) {
      fgColor = Colors.orange.shade400;
    } else if (isDark && fgColor == Colors.red) {
      fgColor = Colors.red.shade400;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fgColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: fgColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment gateway integration pending.'),
                ),
              );
            },
            child: Text(
              isLowData && !isExpiringSoon && !isExpired ? 'Top Up' : 'Renew',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriberPlanResponse planData,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final plan = planData.currentPlans.first;
    final isActive = plan.status.toLowerCase() == 'active';
    final hasVas = planData.currentVasPlans.isNotEmpty;

    // Status colors
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusIcon = isActive ? Icons.check : Icons.close;

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
      child: InkWell(
        onTap: () => _showPlanDetailsBottomSheet(context, planData, isDark),
        borderRadius: BorderRadius.circular(16),
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
                        child: Icon(Icons.wifi, color: primaryColor, size: 28),
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
                            color: isDark
                                ? const Color(0xFF16161E)
                                : theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(statusIcon, size: 14, color: Colors.white),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.planName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasVas)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+ VAS',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${plan.mrp} / month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withAlpha(
                              180,
                            ),
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
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlanDetailsBottomSheet(
    BuildContext context,
    SubscriberPlanResponse planData,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final plan = planData.currentPlans.first;
    final vasPlans = planData.currentVasPlans;

    Widget buildDetailItem(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha(150),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF16161E) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Plan Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Base Plan details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(10)
                      : Colors.black.withAlpha(5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(15)
                        : Colors.black.withAlpha(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Base Plan',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.planName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildDetailItem('Price', '₹${plan.mrp}'),
                        buildDetailItem(
                          'Speed',
                          plan.primarySpeed.isNotEmpty
                              ? plan.primarySpeed
                              : 'N/A',
                        ),
                        buildDetailItem(
                          'Validity',
                          plan.validity.isNotEmpty ? plan.validity : 'N/A',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (vasPlans.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: Colors.amber.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Value Added Services',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: vasPlans.length,
                    itemBuilder: (context, index) {
                      final vas = vasPlans[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(10)
                              : Colors.black.withAlpha(5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withAlpha(15)
                                : Colors.black.withAlpha(15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: Colors.amber,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vas.vasPlanName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (vas.vasPlanRemark != null &&
                                      vas.vasPlanRemark!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: vas.vasPlanRemark!
                                          .split(',')
                                          .where((e) => e.trim().isNotEmpty)
                                          .map((app) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white.withAlpha(20)
                                                    : Colors.black.withAlpha(
                                                        10,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.white.withAlpha(
                                                          30,
                                                        )
                                                      : Colors.black.withAlpha(
                                                          20,
                                                        ),
                                                ),
                                              ),
                                              child: Text(
                                                app.trim(),
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ] else if (vas.chargeName != null &&
                                      vas.chargeName!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      vas.chargeName!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withAlpha(180),
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (vas.noOfDaysRemaining > 0) ...[
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${vas.noOfDaysRemaining} Days',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Left',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withAlpha(180),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataUsageCard(
    BuildContext context,
    WidgetRef ref,
    CustomerDetail customer,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final totalGB = (customer.primaryAllocatedQuotaMB / 1024).round();
    final usedGB = (customer.primaryUsedQuotaMB / 1024)
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'\.00$'), '');

    final totalDataFormatted = totalGB == 0 ? 'Unlimited' : '$totalGB GB';
    final usedDataStr = '$usedGB GB';

    double progress = 0.0;
    if (customer.primaryAllocatedQuotaMB > 0) {
      progress =
          (customer.primaryUsedQuotaMB / customer.primaryAllocatedQuotaMB)
              .clamp(0.0, 1.0);
    } else {
      progress = 1.0;
    }

    String cycleRange = 'Current cycle';
    if (customer.planActivationDate != null &&
        customer.planExpiryDate != null) {
      final start = DateFormat("d MMM yyyy")
          .format(customer.planActivationDate!);
      final end = DateFormat("d MMM yyyy").format(customer.planExpiryDate!);
      cycleRange = '$start – $end';
    }

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(12),
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
                              backgroundColor: isDark
                                  ? Colors.white.withAlpha(12)
                                  : Colors.black.withAlpha(12),
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
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(180),
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
                              color: theme.textTheme.bodySmall?.color
                                  ?.withAlpha(180),
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
                          color: theme.textTheme.bodySmall?.color?.withAlpha(
                            180,
                          ),
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
            InkWell(
              onTap: () => context.go('/usage'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(12)
                      : Colors.black.withAlpha(12),
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
                              color: theme.textTheme.bodySmall?.color
                                  ?.withAlpha(180),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryCard(
    BuildContext context,
    CustomerDetail customer,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final calculatedTotal =
        customer.planRemainingDays + customer.planActiveDays;
    final totalDays = calculatedTotal > 0 ? calculatedTotal : 1;
    final progressDays = customer.planUsedDays;
    final remainingDays = customer.planRemainingDays;

    String startText = customer.planActivationDate != null
        ? DateFormat("d MMM yyyy").format(customer.planActivationDate!)
        : '';
    String endText = customer.planExpiryDate != null
        ? DateFormat("d MMM yyyy").format(customer.planExpiryDate!)
        : '';

    final progress = (progressDays / totalDays).clamp(0.0, 1.0);
    final remainingStr = remainingDays < 0
        ? 'Expired'
        : '$remainingDays days left';

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF16161E) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(12),
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
                    backgroundColor: isDark
                        ? Colors.white.withAlpha(12)
                        : Colors.black.withAlpha(12),
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

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => context.push('/diagnostics'),
                icon: const Icon(Icons.router),
                label: const Text('Router Diagnostics'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                ),
              ),
            ),
          ],
        ),
      ],
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
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(12),
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
                  icon: Icon(
                    Icons.refresh,
                    color: theme.disabledColor,
                    size: 22,
                  ),
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
                          backgroundColor: isDark
                              ? Colors.white.withAlpha(12)
                              : Colors.black.withAlpha(12),
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
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(180),
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
                          color: theme.textTheme.bodySmall?.color?.withAlpha(
                            180,
                          ),
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
                color: isDark
                    ? Colors.white.withAlpha(12)
                    : Colors.black.withAlpha(12),
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
                            color: theme.textTheme.bodySmall?.color?.withAlpha(
                              180,
                            ),
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
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(12),
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
                          color: isDark
                              ? const Color(0xFF16161E)
                              : theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.circle,
                        size: 14,
                        color: Colors.transparent,
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
          color: isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(12),
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
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
