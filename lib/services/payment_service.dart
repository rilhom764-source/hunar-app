import 'package:flutter/foundation.dart';

enum PaymentMethod { alifMobi, dcNext, cash }

enum PaymentStatus { pending, processing, completed, failed, refunded }

class PaymentResult {
  final bool success;
  final String transactionId;
  final PaymentStatus status;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    required this.transactionId,
    required this.status,
    this.errorMessage,
  });
}

class TransactionModel {
  final String id;
  final String taskId;
  final String payerId;
  final String payeeId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? externalTransactionId;

  const TransactionModel({
    required this.id,
    required this.taskId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.externalTransactionId,
  });
}

/// Payment Service with stubs for Tajikistan gateways
class PaymentService {
  /// Initialize payment with Alif Mobi
  /// In production: calls Alif Mobi API to initiate P2P transfer
  /// API Docs: https://alifmobi.tj/developer (hypothetical)
  Future<PaymentResult> payWithAlifMobi({
    required double amount,
    required String senderPhone,
    required String receiverPhone,
    required String description,
  }) async {
    debugPrint('[PaymentService] Alif Mobi payment initiated');
    debugPrint('  Amount: $amount TJS');
    debugPrint('  From: $senderPhone -> To: $receiverPhone');

    // STUB: Simulate API call to Alif Mobi
    await Future.delayed(const Duration(seconds: 2));

    // In production, this would be:
    // final response = await http.post(
    //   Uri.parse('https://api.alifmobi.tj/v1/payments/p2p'),
    //   headers: {
    //     'Authorization': 'Bearer $apiToken',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'amount': amount,
    //     'currency': 'TJS',
    //     'sender_phone': senderPhone,
    //     'receiver_phone': receiverPhone,
    //     'description': description,
    //     'callback_url': 'https://api.ustoconnect.tj/payments/alif/callback',
    //   }),
    // );

    return PaymentResult(
      success: true,
      transactionId: 'ALF-${DateTime.now().millisecondsSinceEpoch}',
      status: PaymentStatus.completed,
    );
  }

  /// Initialize payment with DC Next
  /// In production: calls DC Next gateway API
  /// API Docs: https://dc.tj/developer (hypothetical)
  Future<PaymentResult> payWithDCNext({
    required double amount,
    required String senderAccount,
    required String receiverAccount,
    required String description,
  }) async {
    debugPrint('[PaymentService] DC Next payment initiated');
    debugPrint('  Amount: $amount TJS');
    debugPrint('  From: $senderAccount -> To: $receiverAccount');

    // STUB: Simulate API call to DC Next
    await Future.delayed(const Duration(seconds: 2));

    // In production, this would be:
    // final response = await http.post(
    //   Uri.parse('https://api.dc.tj/v2/transfer'),
    //   headers: {
    //     'X-API-Key': '$dcApiKey',
    //     'X-Merchant-Id': '$merchantId',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'amount': amount,
    //     'currency': 'TJS',
    //     'from_account': senderAccount,
    //     'to_account': receiverAccount,
    //     'purpose': description,
    //     'webhook_url': 'https://api.ustoconnect.tj/payments/dc/webhook',
    //   }),
    // );

    return PaymentResult(
      success: true,
      transactionId: 'DC-${DateTime.now().millisecondsSinceEpoch}',
      status: PaymentStatus.completed,
    );
  }

  /// Record cash payment (no API call needed)
  Future<PaymentResult> recordCashPayment({
    required double amount,
    required String description,
  }) async {
    debugPrint('[PaymentService] Cash payment recorded: $amount TJS');

    return PaymentResult(
      success: true,
      transactionId: 'CASH-${DateTime.now().millisecondsSinceEpoch}',
      status: PaymentStatus.completed,
    );
  }

  /// Generic payment processor
  Future<PaymentResult> processPayment({
    required PaymentMethod method,
    required double amount,
    required String senderInfo,
    required String receiverInfo,
    required String description,
  }) async {
    switch (method) {
      case PaymentMethod.alifMobi:
        return payWithAlifMobi(
          amount: amount,
          senderPhone: senderInfo,
          receiverPhone: receiverInfo,
          description: description,
        );
      case PaymentMethod.dcNext:
        return payWithDCNext(
          amount: amount,
          senderAccount: senderInfo,
          receiverAccount: receiverInfo,
          description: description,
        );
      case PaymentMethod.cash:
        return recordCashPayment(
          amount: amount,
          description: description,
        );
    }
  }
}
