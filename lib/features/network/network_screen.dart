import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kvman/features/profile/network_repository.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  int _selectedWanIndex = 0;

  @override
  Widget build(BuildContext context) {
    final opticalAsync = ref.watch(opticalParameterProvider);
    final wanAsync = ref.watch(wanDetailsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Router Diagnostics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(opticalParameterProvider);
              ref.invalidate(wanDetailsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(opticalParameterProvider);
          ref.invalidate(wanDetailsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'Optical Power & Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Card(
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
                padding: const EdgeInsets.all(20),
                child: opticalAsync.when(
                  skipLoadingOnRefresh: false,
                  loading: () => _buildOpticalSkeleton(context, isDark),
                  error: (e, st) => Text('Failed to load optical data: $e'),
                  data: (optical) {
                    if (optical == null) {
                      return const Text('No optical data available');
                    }

                    Color rxColor = Colors.green;
                    String rxQuality = "Excellent";
                    if (optical.opticalParamRece < -27) {
                      rxColor = Colors.red;
                      rxQuality = "Poor (Critical)";
                    } else if (optical.opticalParamRece < -25) {
                      rxColor = Colors.orange;
                      rxQuality = "Average";
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.router,
                              color: Colors.blueAccent,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    optical.deviceId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'IPv4: ${optical.connectionStatusIpv4}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Optical Rx Power',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${optical.opticalParamRece} dBm',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: rxColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: rxColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rxQuality,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: rxColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Optical Tx Power',
                          '${optical.opticalParamTrans} dBm',
                        ),
                        _buildDetailRow(
                          context,
                          'Connection Type',
                          optical.connectionType,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'WAN Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Card(
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
                padding: const EdgeInsets.all(20),
                child: wanAsync.when(
                  skipLoadingOnRefresh: false,
                  loading: () => _buildWanSkeleton(context, isDark),
                  error: (e, st) => Text('Failed to load WAN data: $e'),
                  data: (wan) {
                    if (wan == null || wan.interfaces.isEmpty) {
                      return const Text('No WAN data available');
                    }

                    if (_selectedWanIndex >= wan.interfaces.length) {
                      Future.microtask(
                        () => setState(() => _selectedWanIndex = 0),
                      );
                      return const SizedBox.shrink();
                    }

                    final pWan = wan.interfaces[_selectedWanIndex];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // always show
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Select WAN Interface',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedWanIndex,
                              isExpanded: true,
                              items: List.generate(wan.interfaces.length, (
                                index,
                              ) {
                                final w = wan.interfaces[index];
                                return DropdownMenuItem(
                                  value: index,
                                  child: Text(
                                    '${w.protocolGroup} - ${w.name}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedWanIndex = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // end dropdown
                        _buildDetailRow(
                          context,
                          'Interface Protocol',
                          pWan.protocolGroup,
                        ),
                        _buildDetailRow(context, 'Interface Name', pWan.name),
                        _buildDetailRow(
                          context,
                          'IP Address',
                          pWan.externalIpAddress,
                        ),
                        _buildDetailRow(
                          context,
                          'Connection',
                          pWan.connectionStatus,
                        ),
                        _buildDetailRow(context, 'Type', pWan.connectionType),
                        _buildDetailRow(
                          context,
                          'DNS Servers',
                          pWan.dnsServers.replaceAll(',', ', '),
                        ),
                        _buildDetailRow(
                          context,
                          'Transport',
                          pWan.transportType,
                        ),
                        _buildDetailRow(
                          context,
                          'LAN Binding',
                          pWan.landBinding,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOpticalSkeleton(BuildContext context, bool isDark) {
    final baseColor = isDark
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(20);
    final highlightColor = isDark
        ? Colors.white.withAlpha(40)
        : Colors.black.withAlpha(40);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
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
                    Container(width: 100, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 120, height: 14, color: Colors.white),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSkeletonRow(),
          _buildSkeletonRow(),
        ],
      ),
    );
  }

  Widget _buildWanSkeleton(BuildContext context, bool isDark) {
    final baseColor = isDark
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(20);
    final highlightColor = isDark
        ? Colors.white.withAlpha(40)
        : Colors.black.withAlpha(40);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          _buildSkeletonRow(),
          _buildSkeletonRow(),
          _buildSkeletonRow(),
          _buildSkeletonRow(),
          _buildSkeletonRow(),
          _buildSkeletonRow(),
        ],
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
