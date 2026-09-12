import 'package:intl/intl.dart';

class TransactionItem {
  final int paymentId;
  final String plan;
  final DateTime? purchaseDate;
  final String amount;
  final String invoiceNo;
  final String status;
  final String purchaseMode;

  TransactionItem({
    required this.paymentId,
    required this.plan,
    required this.purchaseDate,
    required this.amount,
    required this.invoiceNo,
    required this.status,
    required this.purchaseMode,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateStr = json['PurchaseDate'] as String?;
    if (dateStr != null && dateStr.contains('/Date(')) {
      final match = RegExp(r'/Date\((\d+)\)/').firstMatch(dateStr);
      if (match != null && match.groupCount >= 1) {
        final timestamp = int.tryParse(match.group(1)!);
        if (timestamp != null) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
    }

    return TransactionItem(
      paymentId: json['PaymentId'] ?? 0,
      plan: json['Plan'] ?? '',
      purchaseDate: parsedDate,
      amount: json['Amount'] ?? '',
      invoiceNo: json['InvoiceNo'] ?? '',
      status: json['Status'] ?? '',
      purchaseMode: json['PurchaseMode'] ?? '',
    );
  }

  String get formattedDate {
    if (purchaseDate == null) return 'Unknown Date';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(purchaseDate!);
  }

  String get cleanAmount {
    // Usually amounts come as "Dr 836.62", let's strip "Dr " if present
    String amt = amount.replaceAll('Dr ', '').replaceAll('Cr ', '').trim();
    if (!amt.startsWith('₹')) {
      amt = '₹$amt';
    }
    return amt;
  }

  double get parsedAmount {
    String amt = amount.replaceAll(RegExp(r'[a-zA-Z₹\s]+'), '');
    return double.tryParse(amt) ?? 0.0;
  }
}

class PlanHistoryItem {
  final int planId;
  final String name;
  final String planType;
  final DateTime? activationDate;
  final DateTime? expiryDate;
  final String remainQuota;
  final String usedQuota;

  PlanHistoryItem({
    required this.planId,
    required this.name,
    required this.planType,
    required this.activationDate,
    required this.expiryDate,
    required this.remainQuota,
    required this.usedQuota,
  });

  factory PlanHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr != null && dateStr.contains('/Date(')) {
        final match = RegExp(r'/Date\((\d+)\)/').firstMatch(dateStr);
        if (match != null && match.groupCount >= 1) {
          final timestamp = int.tryParse(match.group(1)!);
          if (timestamp != null) {
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
        }
      }
      return null;
    }

    return PlanHistoryItem(
      planId: json['PlanId'] ?? 0,
      name: json['Name'] ?? '',
      planType: json['PlanType'] ?? '',
      activationDate: parseDate(json['ActivationDate'] as String?),
      expiryDate: parseDate(json['ExpiryDate'] as String?),
      remainQuota: json['RemainQuota'] ?? '',
      usedQuota: json['UsedQuota'] ?? '',
    );
  }

  String get formattedActivationDate {
    if (activationDate == null) return '-';
    return DateFormat('MMM dd, yyyy').format(activationDate!);
  }

  String get formattedExpiryDate {
    if (expiryDate == null) return '-';
    return DateFormat('MMM dd, yyyy').format(expiryDate!);
  }
}
