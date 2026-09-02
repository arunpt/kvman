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
  final String ekycStatus;

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
    );
  }
}

