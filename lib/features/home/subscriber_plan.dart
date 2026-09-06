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

  factory CurrentVasPlan.fromJson(Map<String, dynamic> json, {Map<String, String>? remarksMap}) {
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
    if (remark == null && remarksMap != null && remarksMap.containsKey(vasName)) {
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

  SubscriberPlanResponse({
    required this.currentPlans,
    required this.currentVasPlans,
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
          .map((e) => CurrentVasPlan.fromJson(e as Map<String, dynamic>, remarksMap: remarksMap))
          .toList(),
    );
  }
}

