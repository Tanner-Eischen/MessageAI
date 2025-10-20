import 'package:dio/dio.dart';
import '../models/message_payload.dart';

/// API client for message operations
class MessagesApi {
  final Dio dio;
  final String baseUrl;

  MessagesApi({
    required this.dio,
    required this.baseUrl,
  });

  /// Send a message to the backend
  /// 
  /// [message] - The message payload to send
  /// 
  /// Returns the response from the server
  Future<Response> send(MessagePayload message) async {
    try {
      final response = await dio.post(
        '$baseUrl/v1/messages.send',
        data: message.toJson(),
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
