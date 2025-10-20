import 'package:dio/dio.dart';
import '../models/receipt_payload.dart';

/// API client for receipt operations
class ReceiptsApi {
  final Dio dio;
  final String baseUrl;

  ReceiptsApi({
    required this.dio,
    required this.baseUrl,
  });

  /// Acknowledge message receipts to the backend
  /// 
  /// [receipt] - The receipt payload to send
  /// 
  /// Returns the response from the server
  Future<Response> ack(ReceiptPayload receipt) async {
    try {
      final response = await dio.post(
        '$baseUrl/v1/receipts.ack',
        data: receipt.toJson(),
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timeout: ${e.message}');
      case DioExceptionType.badResponse:
        return Exception(
          'Server error: ${e.response?.statusCode} - ${e.response?.data}',
        );
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
