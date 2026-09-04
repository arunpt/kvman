class KvUser {
  final String id;
  final String customerId;
  final String userName;
  final String mobileNo;
  final String email;
  final String status;
  final bool isSwitchLogin;

  const KvUser({
    required this.id,
    required this.customerId,
    required this.userName,
    required this.mobileNo,
    required this.email,
    required this.status,
    required this.isSwitchLogin,
  });

  factory KvUser.fromJson(Map<String, dynamic> json) {
    return KvUser(
      id: json['ID']?.toString() ?? '',
      customerId: json['CustomerID']?.toString() ?? '',
      userName: json['UserName']?.toString() ?? '',
      mobileNo: json['MobileNo']?.toString() ?? '',
      email: json['Email']?.toString() ?? '',
      status: json['Status']?.toString() ?? '',
      isSwitchLogin: json['IsSwitchLogin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CustomerID': customerId,
      'UserName': userName,
      'MobileNo': mobileNo,
      'Email': email,
      'Status': status,
      'IsSwitchLogin': isSwitchLogin,
    };
  }
}
