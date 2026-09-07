class ActiveSession {
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final String appPackage;
  final String platformBrand; // Demo1
  final String platformOs; // Demo2

  ActiveSession({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.appVersion,
    required this.appPackage,
    required this.platformBrand,
    required this.platformOs,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      sessionId: json['SessionId']?.toString() ?? '',
      deviceId: json['DeviceID']?.toString() ?? 'Unknown ID',
      deviceName: json['DeviceName']?.toString() ?? 'Unknown Device',
      appVersion: json['AppVersion']?.toString() ?? 'Unknown Version',
      appPackage: json['AppPackage']?.toString() ?? '',
      platformBrand: json['Demo1']?.toString() ?? '',
      platformOs: json['Demo2']?.toString() ?? '',
    );
  }

  DateTime? get loginTime {
    final ms = int.tryParse(sessionId);
    if (ms != null) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }
}
