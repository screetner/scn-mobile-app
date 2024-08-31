import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  final Dio _dio = Dio();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio.options.baseUrl = dotenv.env['API_URL']!;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        final accessToken = await _getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        final refreshToken = await _getRefreshToken();
        if (refreshToken != null) {
          options.headers['AuthorizationRefresh'] = 'Bearer $refreshToken';
        }
        handler.next(options); // Continue with the request
      },
      onResponse: (Response response, ResponseInterceptorHandler handler) {
        // Handle successful response
        handler.next(response); // Continue with the response
      },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        // Handle errors
        handler.next(error); // Continue with the error
      },
    ));
  }

  Future<String?> _getAccessToken() async {
    final accessToken = await secureStorage.read(key: 'accessToken');
    return accessToken;
  }

  Future<String?> _getRefreshToken() async {
    final refreshToken = await secureStorage.read(key: 'refreshToken');
    return refreshToken;
  }

  Dio get dio => _dio;
}