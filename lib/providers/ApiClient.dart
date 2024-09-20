import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tus_client_background_demo/services/interceptors/ExpiredTokenInterceptor.dart';
import 'package:tus_client_background_demo/types/api/RefreshToken.dart';

import '../services/models/SecureStorageCache.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  final FlutterSecureStorage secureStorage = SecureStorageCache();

  final Dio _dio = Dio();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio.options.baseUrl = dotenv.env['API_URL']!;
    _dio.interceptors.add(ExpiredTokenInterceptor());
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        final accessToken = await getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        final refreshToken = await getRefreshToken();
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

  Future<void> refreshAccessToken() async {
    try {
      final accessToken = await secureStorage.read(key: 'accessToken');
      final refreshToken = await secureStorage.read(key: 'refreshToken');

      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'AuthorizationRefresh': 'Bearer $refreshToken',
          },
        ),
      );

      final refreshStatus = refreshResponse.statusCode;

      if(refreshStatus != 401 && refreshStatus != 403) {
        final refreshResponseData = RefreshTokenResponseDTO.fromJson(refreshResponse.data!);
        await secureStorage.write(key: 'accessToken', value: refreshResponseData.accessToken);
        await secureStorage.write(key: 'refreshToken', value: refreshResponseData.refreshToken);
      } else {
        // TODO: handle error
        throw('refreshing access token error');
      }

    } catch (e, stackTrace) {
      // TODO: handle error
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final accessToken = await secureStorage.read(key: 'accessToken');
      return accessToken;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final refreshToken = await secureStorage.read(key: 'refreshToken');
      return refreshToken;
    } catch (e) {
      return null;
    }
  }

  Future <String?> getTusdToken() async {
    try {
      final refreshToken = await secureStorage.read(key: 'tusdToken');
      return refreshToken;
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getAccessTokenExpiry() async {
    try {
      final accessTokenExpiry = await secureStorage.read(key: 'accessTokenExpiry');
      return DateTime.parse(accessTokenExpiry!);
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getRefreshTokenExpiry() async {
    try {
      final refreshTokenExpiry = await secureStorage.read(key: 'refreshTokenExpiry');
      return DateTime.parse(refreshTokenExpiry!);
    } catch (e) {
      return null;
    }
  }

  Dio get dio => _dio;
}