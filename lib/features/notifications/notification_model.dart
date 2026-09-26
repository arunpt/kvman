import 'package:kvman/core/utils/date_utils.dart';

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
      date: KVDateUtils.parseDotNetDate(
        json['Date']?.toString() ?? '',
        isUtc: true,
      )?.toLocal(),
      imagePath: json['ImagePath']?.toString() ?? '',
      messageBody: json['MessageBody']?.toString() ?? '',
    );
  }
}
