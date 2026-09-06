class AppNotification {
  final String title;
  final String module;
  final DateTime? date;
  final String imagePath;
  final String messageBody;

  const AppNotification({
    required this.title,
    required this.module,
    this.date,
    required this.imagePath,
    required this.messageBody,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: json['Title']?.toString() ?? '',
      module: json['Module']?.toString() ?? '',
      date: _parseDotNetDate(json['Date']?.toString() ?? ''),
      imagePath: json['ImagePath']?.toString() ?? '',
      messageBody: json['MessageBody']?.toString() ?? '',
    );
  }

  static DateTime? _parseDotNetDate(dynamic value) {
    if (value == null) return null;
    final match = RegExp(r'/Date\((-?\d+)\)/').firstMatch(value.toString());
    if (match == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      int.parse(match.group(1)!),
      isUtc: true,
    ).toLocal(); // Converting to local time for display
  }
}

