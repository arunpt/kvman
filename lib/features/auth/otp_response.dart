class OtpResponse {
  final int transactionId;
  final int returnCode;
  final String returnMessage;
  final String extTransactionId;

  const OtpResponse({
    required this.transactionId,
    required this.returnCode,
    required this.returnMessage,
    required this.extTransactionId,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      transactionId: json['transactionId'] as int,
      returnCode: json['returnCode'] as int,
      returnMessage: json['returnMessage'] as String,
      extTransactionId: json['extTransactionId'].toString(),
    );
  }

  bool get isSuccess => returnCode == 0;
}
