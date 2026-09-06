class SessionListResponse {
  final String totalUsageVolume;

  SessionListResponse({
    required this.totalUsageVolume,
  });

  factory SessionListResponse.fromJson(Map<String, dynamic> json) {
    return SessionListResponse(
      totalUsageVolume: json['TotalUsageVolume']?.toString() ?? '0 GB',
    );
  }
}

