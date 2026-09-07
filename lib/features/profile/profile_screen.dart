import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/features/profile/profile_repository.dart';
import 'package:kvman/features/profile/customer_detail.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerDetailAsync = ref.watch(customerDetailProvider);
    final authState = ref.watch(authNotifierProvider);
    final users = authState.users;
    final activeUser = authState.activeUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerDetailProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Customer Detail Section
                customerDetailAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading details: $err',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: () =>
                                ref.refresh(customerDetailProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (customer) =>
                      _buildCustomerDetailCard(context, customer),
                ),

                const SizedBox(height: 32),

                // Accounts Section
                if (activeUser != null) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Accounts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Card(
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
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: users.map((u) {
                        final isActive = u.id == activeUser.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            child: Text(
                              u.userName.substring(0, 1).toUpperCase(),
                            ),
                          ),
                          title: Text(u.userName),
                          subtitle: Text(u.customerId),
                          trailing: isActive
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: isActive
                              ? null
                              : () {
                                  ref
                                      .read(authNotifierProvider.notifier)
                                      .switchUser(u.id);
                                },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),

        // Pinned Logout Button
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonalIcon(
              onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetailCard(
    BuildContext context,
    CustomerDetail customer,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
            const SizedBox(height: 16),
            Text(
              customer.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (customer.email.isNotEmpty)
              Text(
                customer.email,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              customer.phone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'User ID', customer.userId),
            _buildDetailRow(
              context,
              'MAC Address',
              customer.macId.isEmpty ? 'N/A' : customer.macId,
            ),
            _buildDetailRow(
              context,
              'GST Number',
              customer.gstNumber.isEmpty ? 'N/A' : customer.gstNumber,
            ),
            _buildDetailRow(
              context,
              'Aadhar',
              customer.aadharNumber?.isEmpty ?? true
                  ? 'N/A'
                  : customer.aadharNumber!,
            ),
            _buildDetailRow(context, 'Ekyc Status', customer.ekycStatus),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Address', customer.address),
            _buildDetailRow(
              context,
              'Permanent Address',
              customer.permanentAddress,
            ),
            _buildDetailRow(context, 'Partner Name', customer.partnerName),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
