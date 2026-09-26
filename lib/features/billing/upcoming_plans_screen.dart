import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kvman/features/billing/billing_provider.dart';

class UpcomingPlansScreen extends ConsumerWidget {
  const UpcomingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final futurePlanAsync = ref.watch(futurePlanListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Plans'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(futurePlanListProvider);
        },
        child: futurePlanAsync.when(
          data: (response) {
            if (response == null ||
                (response.accountFuturePlanList.isEmpty &&
                    response.futureVasPlanDetail.isEmpty)) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Text(
                      'No upcoming plans queued.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (response.accountFuturePlanList.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'Broadband Plans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...response.accountFuturePlanList.map((plan) {
                    final activates = plan.activationDate != null
                        ? DateFormat('MMM dd, yyyy')
                              .format(plan.activationDate!)
                        : 'Pending';
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      color: isDark
                          ? const Color(0xFF16161E)
                          : theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.router,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    plan.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildRow('Activates On', activates, theme),
                            const SizedBox(height: 8),
                            _buildRow(
                              'Validity',
                              '${plan.validity} ${plan.validityMode}s',
                              theme,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                if (response.futureVasPlanDetail.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12, top: 16),
                    child: Text(
                      'VAS / Add-ons',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...response.futureVasPlanDetail.map((vas) {
                    final activates = vas.expiryDate != null
                        ? DateFormat('MMM dd, yyyy').format(vas.expiryDate!)
                        : 'Pending'; // Expiry of current? Typically activates on expiry of current.
                    // Wait, future plan vas has ExpiryDate, which might be the expiry date of the *future* plan, or when it activates. Let's just say "Expiry Date" or "Next Cycle".
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      color: isDark
                          ? const Color(0xFF16161E)
                          : theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.connected_tv,
                                  color: Colors.purpleAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    vas.vasPlanName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildRow('Config Name', vas.vasConfigName, theme),
                            const SizedBox(height: 8),
                            _buildRow(
                              'Validity',
                              '${vas.totalDaysOfPlan} Days',
                              theme,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Failed to load: $e')),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
