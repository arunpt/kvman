class CustomerDetail {
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String gstNumber;
  final String macId;
  final String address;
  final String permanentAddress;
  final String? aadharNumber;
  final String partnerName;
  final String ekycStatus;
  final int primaryAllocatedQuotaMB;
  final int totalQuota;
  final int primaryUnusedQuotaMB;
  final int primaryUsedQuotaMB;
  final DateTime? customerActivationDate;
  final DateTime? planActivationDate;
  final DateTime? planExpiryDate;
  final int planRemainingDays;
  final int planActiveDays;
  final int planUsedDays;

  const CustomerDetail({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.gstNumber,
    required this.macId,
    required this.address,
    required this.permanentAddress,
    this.aadharNumber,
    required this.ekycStatus,
    required this.partnerName,
    required this.primaryAllocatedQuotaMB,
    required this.totalQuota,
    required this.primaryUnusedQuotaMB,
    required this.primaryUsedQuotaMB,
    this.customerActivationDate,
    this.planActivationDate,
    this.planExpiryDate,
    required this.planRemainingDays,
    required this.planActiveDays,
    required this.planUsedDays,

  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      userId: json['UserId']?.toString() ?? '',
      name: json['Name']?.toString() ?? '',
      phone: json['Phone']?.toString() ?? '',
      email: json['Email']?.toString() ?? '',
      gstNumber: json['GSTNumber']?.toString() ?? '',
      macId: json['MacId']?.toString() ?? '',
      address: json['Address']?.toString() ?? '',
      permanentAddress: json['ParmenentAddress']?.toString() ?? '',
      aadharNumber: json['AadharNumber']?.toString(),
      ekycStatus: json['EkycStatus']?.toString() ?? '',
      partnerName: json['PartnerName']?.toString() ?? '',
      primaryAllocatedQuotaMB:
          int.tryParse(json['PrimaryAllocatedQuotaMB']?.toString() ?? '') ?? 0,
      totalQuota: int.tryParse(json['TotalQuota']?.toString() ?? '') ?? 0,
      primaryUnusedQuotaMB:
          int.tryParse(json['PrimaryUnusedQuotaMB']?.toString() ?? '') ?? 0,
      primaryUsedQuotaMB:
          int.tryParse(json['PrimaryUsedQuotaMB']?.toString() ?? '') ?? 0,
      customerActivationDate:
          _parseDotNetDate(json['CustomerActivationDate']?.toString() ?? ''),
      planActivationDate:
          _parseDotNetDate(json['ActivationDate']?.toString() ?? ''),
      planExpiryDate:
          _parseDotNetDate(json['ExpiryDate']?.toString() ?? ''),
      planRemainingDays:
          int.tryParse(json['remainingDay']?.toString() ?? '') ?? 0,
      planActiveDays: int.tryParse(json['activeDay']?.toString() ?? '') ?? 0,
      planUsedDays: int.tryParse(json['UsedDays']?.toString() ?? '') ?? 0,

    );
  }

  static DateTime? _parseDotNetDate(dynamic value) {
    if (value == null) return null;

    final match = RegExp(r'/Date\((-?\d+)\)/').firstMatch(value.toString());

    if (match == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(
      int.parse(match.group(1)!),
      isUtc: true,
    );
  }
}
