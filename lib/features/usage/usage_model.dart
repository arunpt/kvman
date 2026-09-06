class UsageSummary {
  final String totalTime;
  final String totalVolume;
  final String downloadData;
  final String uploadData;

  const UsageSummary({
    required this.totalTime,
    required this.totalVolume,
    required this.downloadData,
    required this.uploadData,
  });

  factory UsageSummary.fromJson(Map<String, dynamic> json) {
    return UsageSummary(
      totalTime: json['TotalUsageTime']?.toString() ?? '0 Hrs',
      totalVolume: json['TotalUsageVolume']?.toString() ?? '0 GB',
      downloadData: json['TotalDownloadData']?.toString() ?? '0 GB',
      uploadData: json['TotalUploadData']?.toString() ?? '0 GB',
    );
  }
}

class SessionItem {
  final String sessionId;
  final String startDateStr;
  final String endDateStr;
  final String usageStr;
  final String uploadStr;
  final String downloadStr;
  final String duration;
  final String macId;
  final String terminationCause;

  const SessionItem({
    required this.sessionId,
    required this.startDateStr,
    required this.endDateStr,
    required this.usageStr,
    required this.uploadStr,
    required this.downloadStr,
    required this.duration,
    required this.macId,
    required this.terminationCause,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) {
    return SessionItem(
      sessionId: json['SessionId']?.toString() ?? '',
      startDateStr: json['SessionStartDate']?.toString() ?? '',
      endDateStr: json['SessionEndDate']?.toString() ?? '',
      usageStr: json['UsageMB']?.toString() ?? '',
      uploadStr: json['UploadMB']?.toString() ?? '',
      downloadStr: json['DownloadMB']?.toString() ?? '',
      duration: json['Duration']?.toString() ?? '',
      macId: json['MacId']?.toString() ?? '',
      terminationCause: json['TerminationCause']?.toString() ?? '',
    );
  }
}

class UsageData {
  final UsageSummary summary;
  final List<SessionItem> sessions;

  const UsageData({
    required this.summary,
    required this.sessions,
  });
}

