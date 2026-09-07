import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kvman/features/settings/active_sessions_repository.dart';
import 'package:kvman/features/settings/active_session_model.dart';

class TerminatingSessionNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setTerminatingId(String? id) => state = id;
}

final terminatingSessionIdProvider =
    NotifierProvider<TerminatingSessionNotifier, String?>(
      TerminatingSessionNotifier.new,
    );

class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(activeSessionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeSessionsProvider),
          ),
        ],
      ),
      body: sessionsAsync.when(
        skipLoadingOnRefresh: false,
        loading: () => _buildShimmer(context, isDark),
        error: (err, stack) => ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading sessions:\n$err', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(activeSessionsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(32),
              children: const [
                Center(child: Text('No active sessions found.')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionCard(context, ref, session, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer(BuildContext context, bool isDark) {
    final baseColor = isDark
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(20);
    final highlightColor = isDark
        ? Colors.white.withAlpha(40)
        : Colors.black.withAlpha(40);
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(20),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                              margin: const EdgeInsets.only(right: 64),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: Colors.white),
                  const SizedBox(height: 16),
                  _buildSkeletonRow(),
                  _buildSkeletonRow(),
                  _buildSkeletonRow(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 14,
              color: Colors.white,
              margin: const EdgeInsets.only(right: 32),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: 14,
              color: Colors.white,
              margin: const EdgeInsets.only(left: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    ActiveSession session,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Determine icon based on platform
    IconData deviceIcon = Icons.device_unknown;
    if (session.platformOs.toLowerCase().contains('android')) {
      deviceIcon = Icons.phone_android;
    } else if (session.platformOs.toLowerCase().contains('ios') ||
        session.platformBrand.toLowerCase().contains('apple')) {
      deviceIcon = Icons.phone_iphone;
    } else if (session.platformOs.toLowerCase().contains('web')) {
      deviceIcon = Icons.language;
    } else {
      deviceIcon = Icons.devices;
    }

    String formattedDate = 'Unknown Time';
    if (session.loginTime != null) {
      formattedDate = DateFormat("MMM d, yyyy • h:mm a")
          .format(session.loginTime!);
    }

    // Determine display name
    String displayName = session.platformBrand.isNotEmpty
        ? session.platformBrand
        : session.deviceName;
    if (displayName.isEmpty) displayName = 'Unknown Device';

    final terminatingId = ref.watch(terminatingSessionIdProvider);
    final isTerminating = terminatingId == session.sessionId;
    final isAnyTerminating = terminatingId != null;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(deviceIcon, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.platformOs.isNotEmpty
                            ? session.platformOs
                            : 'Unknown OS',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'App Version', session.appVersion),
            _buildDetailRow(context, 'Device', session.deviceName),
            _buildDetailRow(context, 'Login Time', formattedDate),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: isAnyTerminating
                  ? null
                  : () async {
                      ref
                          .read(terminatingSessionIdProvider.notifier)
                          .setTerminatingId(session.sessionId);
                      try {
                        await ref
                            .read(activeSessionsRepositoryProvider)
                            .logoutSession(session.sessionId);
                        ref.invalidate(activeSessionsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Session successfully terminated.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                            ),
                          );
                        }
                      } finally {
                        ref
                            .read(terminatingSessionIdProvider.notifier)
                            .setTerminatingId(null);
                      }
                    },
              icon: isTerminating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout, size: 18),
              label: Text(
                isTerminating ? 'Terminating...' : 'Terminate Session',
              ),
              style: FilledButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.red.withAlpha(isDark ? 20 : 30),
              ),
            ),
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
