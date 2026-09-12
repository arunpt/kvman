import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/features/billing/billing_provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncData = ref.watch(filteredTransactionHistoryProvider);
    final filterRange = ref.watch(transactionFilterRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          PopupMenuButton<TransactionDateRange>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by date range',
            onSelected: (range) {
              ref.read(transactionFilterRangeProvider.notifier).setRange(range);
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: TransactionDateRange.threeMonths,
                  child: Text('Last 3 Months'),
                ),
                const PopupMenuItem(
                  value: TransactionDateRange.sixMonths,
                  child: Text('Last 6 Months'),
                ),
                const PopupMenuItem(
                  value: TransactionDateRange.oneYear,
                  child: Text('Last 1 Year'),
                ),
                const PopupMenuItem(
                  value: TransactionDateRange.allTime,
                  child: Text('All Time'),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionHistoryProvider);
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
                  'Failed to load transactions',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(transactionHistoryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (transactions) {
            double totalSpent = 0;
            int count = 0;
            for (var t in transactions) {
              if (t.status.toLowerCase().contains('complete') ||
                  t.status.toLowerCase().contains('success')) {
                totalSpent += t.parsedAmount;
                count++;
              }
            }

            if (transactions.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (filterRange != TransactionDateRange.allTime)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSpendingSummary(
                        context,
                        totalSpent,
                        count,
                        filterRange,
                        isDark,
                      ),
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        if (filterRange != TransactionDateRange.allTime)
                          Text(
                            'for the selected period',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildSpendingSummary(
                      context,
                      totalSpent,
                      count,
                      filterRange,
                      isDark,
                    ),
                  );
                }

                final item = transactions[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.plan,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.formattedDate,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(item.status)
                                      .withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.cleanAmount,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: _getStatusColor(item.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoColumn(
                                context,
                                'Invoice',
                                item.invoiceNo,
                              ),
                              _buildInfoColumn(
                                context,
                                'Mode',
                                item.purchaseMode,
                              ),
                              _buildInfoColumn(context, 'Status', item.status),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildSpendingSummary(
    BuildContext context,
    double totalSpent,
    int count,
    TransactionDateRange filterRange,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    String label;
    switch (filterRange) {
      case TransactionDateRange.threeMonths:
        label = 'Last 3 Months Spending';
        break;
      case TransactionDateRange.sixMonths:
        label = 'Last 6 Months Spending';
        break;
      case TransactionDateRange.oneYear:
        label = 'Last 1 Year Spending';
        break;
      case TransactionDateRange.allTime:
        label = 'Total Spending';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(12)
            : theme.colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : theme.colorScheme.primary.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? Colors.grey
                      : theme.colorScheme.primary.withAlpha(200),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: isDark ? Colors.grey : theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormat.format(totalSpent),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              color: isDark ? Colors.white : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Across $count successful recharges',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? Colors.grey
                  : theme.colorScheme.primary.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('complete') ||
        status.toLowerCase().contains('success')) {
      return Colors.green;
    }
    if (status.toLowerCase().contains('fail') ||
        status.toLowerCase().contains('cancel')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(bool isDark, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _shimmerBox(double.infinity, 140, isDark, borderRadius: 20),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Card(
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _shimmerBox(160, 16, isDark),
                            const SizedBox(height: 8),
                            _shimmerBox(120, 12, isDark),
                          ],
                        ),
                      ),
                      _shimmerBox(70, 26, isDark, borderRadius: 8),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isDark ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(50, 10, isDark),
                          const SizedBox(height: 6),
                          _shimmerBox(100, 14, isDark),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(40, 10, isDark),
                          const SizedBox(height: 6),
                          _shimmerBox(60, 14, isDark),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(40, 10, isDark),
                          const SizedBox(height: 6),
                          _shimmerBox(70, 14, isDark),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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
