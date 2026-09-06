class CurrentPlan {
  final String planName;
  final String status;
  final String mrp;
  final String primaryData;
  final String period;

  CurrentPlan({
    required this.planName,
    required this.status,
    required this.mrp,
    required this.primaryData,
    required this.period,
  });

  factory CurrentPlan.fromJson(Map<String, dynamic> json) {
    return CurrentPlan(
      planName: json['PlanName']?.toString() ?? '',
      status: json['STATUS']?.toString() ?? '',
      mrp: json['MRP']?.toString() ?? '0',
      primaryData: json['PrimaryData']?.toString() ?? '',
      period: json['Period']?.toString() ?? '',
    );
  }
}

class CurrentVasPlan {
  final String vasPlanName;

  CurrentVasPlan({required this.vasPlanName});

  factory CurrentVasPlan.fromJson(Map<String, dynamic> json) {
    return CurrentVasPlan(
      vasPlanName: json['VasPlanName']?.toString() ?? '',
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

    return SubscriberPlanResponse(
      currentPlans: planList
          .map((e) => CurrentPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentVasPlans: vasList
          .map((e) => CurrentVasPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

