import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:kvman/features/billing/billing_model.dart';
import 'package:kvman/core/utils/logging.dart';

class BillingRepository {
  final Dio _dio;

  BillingRepository(this._dio);

  Future<List<TransactionItem>> getTransactionHistory(String username) async {
    try {
      final payload = {
        "maxRow": "50",
        "pageSize": "0",
        "pageCount": "0",
        "CurrentPageIndex": 0,
        "totalRecord": 0,
        "sortExpression": "",
        "sortingType": "DESC",
        "sourceType": 0,
        "dateFormate": "",
        "page": 0,
        "termsandconditions": "",
        "Amount": "",
        "UserName": username,
        "isBringAllRecord": true,
      };

      final response = await _dio.post('/PurchaseList', data: payload);
      final data = response.data;

      if (data != null && data is Map<String, dynamic>) {
        if (data.containsKey('AccountPurchaseList') &&
            data['AccountPurchaseList'] != null) {
          final list = data['AccountPurchaseList'] as List;
          return list
              .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      logger.e('Failed to fetch transaction history: $e');
      throw Exception('Failed to fetch transaction history');
    }
  }

  Future<List<PlanHistoryItem>> getPlanHistory(String username) async {
    try {
      final payload = {
        "currentPageIndex": 0,
        "id": "",
        "Name": "",
        "Validity": "",
        "ValidityMode": "",
        "Plan": "",
        "CarryForward": "",
        "Remain": "",
        "Used": "",
        "ActivationDate": "",
        "ExpireDate": "",
        "VoucherSrNo": "",
        "PlanSpeed": "",
        "SppedRights": "",
        "CurrentPlanStatus": "",
        "UserName": username,
      };

      final response = await _dio.post('/PlanHistoryList', data: payload);
      final data = response.data;

      if (data != null && data is Map<String, dynamic>) {
        if (data.containsKey('AccountPlanHistoryList') &&
            data['AccountPlanHistoryList'] != null) {
          final list = data['AccountPlanHistoryList'] as List;
          return list
              .map((e) => PlanHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      logger.e('Failed to fetch plan history: $e');
      throw Exception('Failed to fetch plan history');
    }
  }

  Future<String> downloadInvoicePDF(String paymentId, String templateId) async {
    try {
      final payload = {
        "id": paymentId,
        "templateId": templateId,
        "TemplateName": null,
        "CustomerId": null,
      };

      final response = await _dio.post(
        '/GetInvoicePrint',
        data: payload,
        options: Options(responseType: ResponseType.bytes),
      );

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/invoice_$paymentId.pdf';
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      return filePath;
    } catch (e) {
      logger.e('Failed to download invoice: $e');
      throw Exception('Failed to download invoice');
    }
  }
}
