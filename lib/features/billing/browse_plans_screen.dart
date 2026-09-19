import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kvman/features/home/home_repository.dart';
import 'package:kvman/features/home/subscriber_plan.dart';
import 'package:kvman/features/billing/billing_provider.dart';
import 'package:kvman/features/billing/billing_model.dart';
import 'package:shimmer/shimmer.dart';

class BrowsePlansScreen extends ConsumerStatefulWidget {
  const BrowsePlansScreen({super.key});

  @override
  ConsumerState<BrowsePlansScreen> createState() => _BrowsePlansScreenState();
}

enum PlanFilter { all, internet, ott }

enum PlanSort { priceAsc, priceDesc, speedAsc, speedDesc }

class _BrowsePlansScreenState extends ConsumerState<BrowsePlansScreen> {
  PlanFilter _planFilter = PlanFilter.all;
  PlanSort _planSort = PlanSort.priceAsc;

  double _extractSpeed(String speedString) {
    final match = RegExp(r'([0-9.]+)').firstMatch(speedString);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  bool _isTransposed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final planAsync = ref.watch(currentPlanProvider);
    final vasAsync = ref.watch(vasPlansProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Available Plans'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Broadband Plans'),
              Tab(text: 'Add-ons'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Merged Broadband & OTT Plans
                  planAsync.when(
                    data: (planData) {
                      final allPlans = planData.availablePlans;
                      List<AvailablePlan> filteredPlans = allPlans;

                      if (_planFilter == PlanFilter.internet) {
                        filteredPlans = allPlans
                            .where((p) => !p.isOtt)
                            .toList();
                      } else if (_planFilter == PlanFilter.ott) {
                        filteredPlans = allPlans.where((p) => p.isOtt).toList();
                      }

                      // Injecting Sort Logic Here
                      if (_planSort == PlanSort.priceAsc) {
                        filteredPlans.sort(
                          (a, b) => a.price.compareTo(b.price),
                        );
                      } else if (_planSort == PlanSort.priceDesc) {
                        filteredPlans.sort(
                          (a, b) => b.price.compareTo(a.price),
                        );
                      } else if (_planSort == PlanSort.speedAsc) {
                        filteredPlans.sort(
                          (a, b) =>
                              _extractSpeed(a.speed)
                                  .compareTo(_extractSpeed(b.speed)),
                        );
                      } else if (_planSort == PlanSort.speedDesc) {
                        filteredPlans.sort(
                          (a, b) =>
                              _extractSpeed(b.speed)
                                  .compareTo(_extractSpeed(a.speed)),
                        );
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        ChoiceChip(
                                          label: const Text('All Plans'),
                                          selected:
                                              _planFilter == PlanFilter.all,
                                          onSelected: (_) => setState(
                                            () => _planFilter = PlanFilter.all,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ChoiceChip(
                                          label: const Text('Internet Only'),
                                          selected:
                                              _planFilter ==
                                              PlanFilter.internet,
                                          onSelected: (_) => setState(
                                            () => _planFilter =
                                                PlanFilter.internet,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ChoiceChip(
                                          label: const Text('With OTT'),
                                          selected:
                                              _planFilter == PlanFilter.ott,
                                          onSelected: (_) => setState(
                                            () => _planFilter = PlanFilter.ott,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                PopupMenuButton<PlanSort>(
                                  icon: const Icon(Icons.sort),
                                  tooltip: 'Sort Plans',
                                  onSelected: (PlanSort result) {
                                    setState(() {
                                      _planSort = result;
                                    });
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<PlanSort>>[
                                        const PopupMenuItem<PlanSort>(
                                          value: PlanSort.priceAsc,
                                          child: Text('Price: Low to High'),
                                        ),
                                        const PopupMenuItem<PlanSort>(
                                          value: PlanSort.priceDesc,
                                          child: Text('Price: High to Low'),
                                        ),
                                        const PopupMenuItem<PlanSort>(
                                          value: PlanSort.speedAsc,
                                          child: Text('Speed: Low to High'),
                                        ),
                                        const PopupMenuItem<PlanSort>(
                                          value: PlanSort.speedDesc,
                                          child: Text('Speed: High to Low'),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildPlanList(
                              context,
                              filteredPlans,
                              isDark,
                              true,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        _buildLoadingSkeleton(isDark, hasTopWidget: true),
                    error: (error, _) =>
                        Center(child: Text('Error loading plans: $error')),
                  ),

                  // Tab 2: Add-ons
                  vasAsync.when(
                    data: (vasPlans) {
                      return _buildVasPlanList(context, vasPlans, isDark);
                    },
                    loading: () =>
                        _buildLoadingSkeleton(isDark, hasTopWidget: true),
                    error: (err, st) =>
                        Center(child: Text('Failed to load add-ons: $err')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark, {bool hasTopWidget = true}) {
    final baseColor = isDark
        ? Colors.white.withAlpha(20)
        : Colors.black.withAlpha(20);
    final highlightColor = isDark
        ? Colors.white.withAlpha(40)
        : Colors.black.withAlpha(40);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5 + (hasTopWidget ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (hasTopWidget && index == 0) {
          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanList(
    BuildContext context,
    List<AvailablePlan> plans,
    bool isDark,
    bool showChart,
  ) {
    if (plans.isEmpty) {
      return const Center(child: Text('No plans available in this category.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentPlanProvider);
        try {
          await ref.read(currentPlanProvider.future);
        } catch (_) {}
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length + (showChart ? 1 : 0),
        itemBuilder: (context, index) {
          if (showChart && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildBroadbandChart(context, plans, isDark),
            );
          }

          final planIndex = showChart ? index - 1 : index;
          final plan = plans[planIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildPlanCard(context, plan, isDark),
          );
        },
      ),
    );
  }

  Widget _buildVasPlanList(
    BuildContext context,
    List<VasPlan> plans,
    bool isDark,
  ) {
    if (plans.isEmpty) {
      return const Center(child: Text('No add-ons available.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(vasPlansProvider);
        try {
          await ref.read(vasPlansProvider.future);
        } catch (_) {}
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildVasComparisonMatrix(context, plans, isDark),
            );
          }

          final plan = plans[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildVasPlanCard(context, plan, isDark),
          );
        },
      ),
    );
  }

  Widget _buildBroadbandChart(
    BuildContext context,
    List<AvailablePlan> plans,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    double maxPrice = 0;
    double maxSpeed = 0;
    List<ScatterSpot> spots = [];

    for (int i = 0; i < plans.length; i++) {
      final p = plans[i];
      if (p.price > maxPrice) maxPrice = p.price;

      double s = 0.0;
      final speedMatch = RegExp(r'([0-9.]+)').firstMatch(p.speed);
      if (speedMatch != null) {
        s = double.tryParse(speedMatch.group(1)!) ?? 0.0;
      }

      if (s > maxSpeed) maxSpeed = s;

      spots.add(
        ScatterSpot(
          p.price,
          s,
          dotPainter: FlDotCirclePainter(
            color: p.isOtt
                ? Colors.purple.withAlpha(200)
                : primaryColor.withAlpha(200),
            radius: 8,
            strokeWidth: 1.5,
            strokeColor: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      );
    }

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Speed vs. Price',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0, top: 8.0),
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: spots,
                  minX: 0,
                  maxX: maxPrice + (maxPrice * 0.1),
                  minY: 0,
                  maxY: maxSpeed + (maxSpeed * 0.15),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameSize: 24,
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Price (₹)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min)
                            return const SizedBox.shrink();
                          String formatted = value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}k'
                              : value.toInt().toString();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              formatted,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameSize: 24,
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Speed (Mbps)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipColor: (_) =>
                          isDark ? Colors.grey[800]! : Colors.white,
                      getTooltipItems: (ScatterSpot touchedSpot) {
                        final index = spots.indexOf(touchedSpot);
                        if (index == -1) return null;
                        final plan = plans[index];
                        return ScatterTooltipItem(
                          '${plan.name}\n',
                          textStyle: TextStyle(
                            color: plan.isOtt ? Colors.purple : primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '₹${plan.price.toStringAsFixed(0)} | ${plan.speed}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 10, color: primaryColor.withAlpha(200)),
              const SizedBox(width: 4),
              const Text('Internet Only', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 16),
              Icon(Icons.circle, size: 10, color: Colors.purple.withAlpha(200)),
              const SizedBox(width: 4),
              const Text('With OTT', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVasComparisonMatrix(
    BuildContext context,
    List<VasPlan> plans,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    final sortedPlans = List<VasPlan>.from(plans)
      ..sort((a, b) => a.price.compareTo(b.price));
    final Set<String> allApps = {};
    for (var p in sortedPlans) {
      allApps.addAll(p.ottBenefits);
    }
    final sortedApps = allApps.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 8.0,
              top: 8.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_chart_outlined,
                  size: 20,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Compare OTT Plans',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Flip Matrix Axis',
                  child: IconButton(
                    icon: Icon(
                      Icons.swap_calls,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isTransposed = !_isTransposed;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isTransposed)
            _buildTransposedTable(sortedPlans, sortedApps, isDark)
          else
            _buildDenseTable(sortedPlans, sortedApps, isDark),
        ],
      ),
    );
  }

  Widget _buildTransposedTable(
    List<VasPlan> sortedPlans,
    List<String> sortedApps,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky Column (Left)
        DataTable(
          headingRowHeight: 52,
          dataRowMinHeight: 30,
          dataRowMaxHeight: 30,
          columnSpacing: 0,
          horizontalMargin: 12,
          columns: [
            const DataColumn(
              label: Text(
                'OTT Apps',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
          rows: sortedApps.map((app) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    app,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),

        // Scrollable Columns (Right)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 52,
              dataRowMinHeight: 30,
              dataRowMaxHeight: 30,
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: sortedPlans
                  .map(
                    (plan) => DataColumn(
                      label: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            plan.name.replaceAll('KEE ', ''),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${plan.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              rows: sortedApps.map((app) {
                return DataRow(
                  cells: sortedPlans.map((plan) {
                    final hasApp = plan.ottBenefits.contains(app);
                    return DataCell(
                      Center(
                        child: hasApp
                            ? const Icon(
                                Icons.circle,
                                color: Colors.amber,
                                size: 12,
                              )
                            : Icon(
                                Icons.circle_outlined,
                                color: Colors.grey.withAlpha(100),
                                size: 12,
                              ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDenseTable(
    List<VasPlan> sortedPlans,
    List<String> sortedApps,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky Column (Left)
        DataTable(
          headingRowHeight: 100,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 36,
          columnSpacing: 0,
          horizontalMargin: 12,
          columns: [
            const DataColumn(
              label: Text(
                'Plan & Price',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
          rows: sortedPlans.map((plan) {
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        plan.name.replaceAll('KEE ', ''),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${plan.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),

        // Scrollable Columns (Right)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 100,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 36,
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: sortedApps
                  .map(
                    (app) => DataColumn(
                      label: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          app,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      tooltip: app,
                    ),
                  )
                  .toList(),
              rows: sortedPlans.map((plan) {
                return DataRow(
                  cells: sortedApps.map((app) {
                    final hasApp = plan.ottBenefits.contains(app);
                    return DataCell(
                      Center(
                        child: hasApp
                            ? const Icon(
                                Icons.circle,
                                color: Colors.amber,
                                size: 14,
                              )
                            : Icon(
                                Icons.circle_outlined,
                                color: Colors.grey.withAlpha(100),
                                size: 14,
                              ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, AvailablePlan plan, bool isDark) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${plan.price.toStringAsFixed(2)} / ${plan.validity}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: plan.isOtt
                        ? Colors.purple.withAlpha(25)
                        : primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    plan.isOtt ? Icons.subscriptions_outlined : Icons.wifi,
                    color: plan.isOtt ? Colors.purple : primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSpecItem(context, Icons.speed, plan.speed),
                const SizedBox(width: 24),
                _buildSpecItem(context, Icons.data_usage, plan.dataLimit),
              ],
            ),
            if (plan.isOtt && plan.ottBenefits.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Included Subscriptions:',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plan.ottBenefits.map((app) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(10)
                          : Colors.black.withAlpha(5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(15)
                            : Colors.black.withAlpha(15),
                      ),
                    ),
                    child: Text(
                      app,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVasPlanCard(BuildContext context, VasPlan plan, bool isDark) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${plan.price.toStringAsFixed(2)} / ${plan.validity}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.amber),
                ),
              ],
            ),
            if (plan.ottBenefits.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: isDark ? Colors.white10 : Colors.black12),
              const SizedBox(height: 12),
              Text(
                'Included Apps:',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plan.ottBenefits.map((app) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(10)
                          : Colors.black.withAlpha(5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(15)
                            : Colors.black.withAlpha(15),
                      ),
                    ),
                    child: Text(
                      app,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
