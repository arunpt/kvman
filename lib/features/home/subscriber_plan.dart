class AvailablePlan {
  final String name;
  final String speed;
  final String dataLimit;
  final double price;
  final String validity;
  final bool isOtt;
  final List<String> ottBenefits;

  AvailablePlan({
    required this.name,
    required this.speed,
    required this.dataLimit,
    required this.price,
    required this.validity,
    required this.isOtt,
    this.ottBenefits = const [],
  });

  factory AvailablePlan.fromJson(Map<String, dynamic> json) {
    String name = json['NAME']?.toString() ?? 'Unknown Plan';
    String planSpeed = json['plan_Speed']?.toString() ?? 'N/A';
    String quota = json['Quota']?.toString() ?? 'Unlimited';
    if (quota == 'UL GB') quota = 'Unlimited';

    double price = 0.0;
    if (json['MRP'] != null) {
      price = double.tryParse(json['MRP'].toString()) ?? 0.0;
    }

    String validity = json['Validity']?.toString() ?? 'N/A';

    bool isOtt = false;
    List<String> ottBenefits = [];

    final vasList = json['VASList'] as List<dynamic>?;
    if (vasList != null && vasList.isNotEmpty) {
      isOtt = true;
      for (var v in vasList) {
        if (v is Map<String, dynamic>) {
          final remark = v['VasPlanRemark']?.toString();
          if (remark != null && remark.isNotEmpty) {
            ottBenefits.addAll(
              remark.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
            );
          }
        }
      }
    }

    return AvailablePlan(
      name: name,
      speed: planSpeed,
      dataLimit: quota,
      price: price,
      validity: validity,
      isOtt: isOtt,
      ottBenefits: ottBenefits.toSet().toList(),
    );
  }
}

class CurrentPlan {
  final String planName;
  final String status;
  final String mrp;
  final String primaryData;
  final String period;
  final String primarySpeed;
  final String validity;

  CurrentPlan({
    required this.planName,
    required this.status,
    required this.mrp,
    required this.primaryData,
    required this.period,
    required this.primarySpeed,
    required this.validity,
  });

  factory CurrentPlan.fromJson(Map<String, dynamic> json) {
    return CurrentPlan(
      planName: json['PlanName']?.toString() ?? '',
      status: json['STATUS']?.toString() ?? '',
      mrp: json['MRP']?.toString() ?? '0',
      primaryData: json['PrimaryData']?.toString() ?? '',
      period: json['Period']?.toString() ?? '',
      primarySpeed: json['PrimarySpeed']?.toString() ?? '',
      validity: json['Validity']?.toString() ?? '',
    );
  }
}

class CurrentVasPlan {
  final String vasPlanName;
  final int noOfDaysRemaining;
  final int totalOfDaysOfPlan;
  final DateTime? expiryDate;
  final String? vasPlanRemark;
  final String? chargeName;

  CurrentVasPlan({
    required this.vasPlanName,
    required this.noOfDaysRemaining,
    required this.totalOfDaysOfPlan,
    this.expiryDate,
    this.vasPlanRemark,
    this.chargeName,
  });

  factory CurrentVasPlan.fromJson(
    Map<String, dynamic> json, {
    Map<String, String>? remarksMap,
  }) {
    DateTime? parsedExpiry;
    final dateStr = json['ExpiryDate']?.toString();
    if (dateStr != null) {
      final match = RegExp(r'/Date\((-?\d+)\)/').firstMatch(dateStr);
      if (match != null) {
        final ms = int.tryParse(match.group(1)!);
        if (ms != null) {
          parsedExpiry = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    }

    final vasName = json['VasPlanName']?.toString() ?? '';
    String? remark = json['VASPlanRemark']?.toString();
    if (remark == null &&
        remarksMap != null &&
        remarksMap.containsKey(vasName)) {
      remark = remarksMap[vasName];
    }

    return CurrentVasPlan(
      vasPlanName: vasName,
      noOfDaysRemaining: json['NoOfDaysRemaining'] as int? ?? 0,
      totalOfDaysOfPlan: json['TotalOfDaysOfPlan'] as int? ?? 0,
      expiryDate: parsedExpiry,
      vasPlanRemark: remark,
      chargeName: json['ChargeName']?.toString(),
    );
  }
}

class SubscriberPlanResponse {
  final List<CurrentPlan> currentPlans;
  final List<CurrentVasPlan> currentVasPlans;
  final List<AvailablePlan> availablePlans;

  SubscriberPlanResponse({
    required this.currentPlans,
    required this.currentVasPlans,
    this.availablePlans = const [],
  });

  factory SubscriberPlanResponse.fromJson(Map<String, dynamic> json) {
    final planList = json['CurrentPlanDetail'] as List<dynamic>? ?? [];
    final vasList = json['CurrentVasPlanDetail'] as List<dynamic>? ?? [];

    // Extract remarks from the main PlanList if available
    final fullPlanList = json['PlanList'] as List<dynamic>? ?? [];
    Map<String, String> remarksMap = {};
    for (var plan in fullPlanList) {
      if (plan is Map<String, dynamic>) {
        final pVasList = plan['VASList'] as List<dynamic>?;
        if (pVasList != null) {
          for (var v in pVasList) {
            if (v is Map<String, dynamic>) {
              final n = v['VASPlanName']?.toString();
              final r = v['VasPlanRemark']?.toString();
              if (n != null && r != null && r.isNotEmpty) {
                remarksMap[n] = r;
              }
            }
          }
        }
      }
    }

    return SubscriberPlanResponse(
      currentPlans: planList
          .map((e) => CurrentPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentVasPlans: vasList
          .map(
            (e) => CurrentVasPlan.fromJson(
              e as Map<String, dynamic>,
              remarksMap: remarksMap,
            ),
          )
          .toList(),
      availablePlans: fullPlanList
          .whereType<Map<String, dynamic>>()
          .map((e) => AvailablePlan.fromJson(e))
          .toList(),
    );
  }
}
