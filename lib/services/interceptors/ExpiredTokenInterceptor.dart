import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tus_client_background_demo/types/api/RefreshToken.dart';

import '../models/SecureStorageCache.dart';

class ExpiredTokenInterceptor extends Interceptor {
  final Dio _dio = Dio();
  static final FlutterSecureStorage secureStorage = SecureStorageCache();

  ExpiredTokenInterceptor() {
    _dio.options.baseUrl = dotenv.env['API_URL']!;
  }

  @override
  Future onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if(options.path == '/auth/login') return handler.next(options);

    if(await isRefreshTokenExpired()) {
      await _clearUserData();

      // TODO: handle response
      return handler.reject(DioException(
        requestOptions: options,
        error: 'Refresh token expired',
        type: DioExceptionType.cancel,
      ));
    }

    if(await isAccessTokenExpired()) {
      final refreshResponse = await _refreshAccessToken();
      final refreshStatus = refreshResponse.statusCode;

      if(refreshStatus != 401 && refreshStatus != 403) {
        final refreshResponseData = RefreshTokenResponseDTO.fromJson(refreshResponse.data!);
        await _storeTokenFromRefresh(refreshResponseData);

        options.headers['Authorization'] = 'Bearer ${refreshResponseData.accessToken}';
        return handler.next(options);
      } else {
        await _clearUserData();

        return handler.reject(DioException(
          requestOptions: options,
          error: 'Access token expired and refresh failed',
          type: DioExceptionType.cancel,
        ));
      }
    }

    return handler.next(options);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    if(statusCode != 401 && statusCode != 403) {
      return;
    }

    final refreshResponse = await _refreshAccessToken();
    final refreshStatus = refreshResponse.statusCode;

    if(refreshStatus != 401 && refreshStatus != 403) {
      final refreshResponseData = RefreshTokenResponseDTO.fromJson(refreshResponse.data!);
      _storeTokenFromRefresh(refreshResponseData);

      return handler.resolve(await _dio.fetch(err.requestOptions));
    }

    // TODO: refresh ScreetnerMainApp to redirect to LoginPage
    // Personally, I think the app must auto login every time the user opens the app
    // to get new access and refresh tokens So that it can be ensured that the app
    // stores a valid username and password and don't occasionally redirect the user
    // to the login page when the user is already inside the ScreetnerHome.
    //
    // However, we should still be able to redirect the user to the login page
    // from here in case the user somehow is unable to auto login.

    await _clearUserData();

    return handler.next(err);
  }

  Future<Response<Map<String, dynamic>>> _refreshAccessToken() async {
    final accessToken = await secureStorage.read(key: 'accessToken');
    final refreshToken = await secureStorage.read(key: 'refreshToken');

    return await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'AuthorizationRefresh': 'Bearer $refreshToken',
        },
      ),
    );
  }

  Future<void> _storeTokenFromRefresh(RefreshTokenResponseDTO response) async {
    final accessToken = response.accessToken;
    final refreshToken = response.refreshToken;

    await secureStorage.write(key: 'accessToken', value: accessToken);
    await secureStorage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<void> _clearUserData() async {
    await secureStorage.delete(key: 'accessToken');
    await secureStorage.delete(key: 'refreshToken');
    await secureStorage.delete(key: 'username');
  }

  static Future<bool> isAccessTokenExpired() async {
    final accessTokenExpiry = await secureStorage.read(key: 'accessTokenExpiry');
    return accessTokenExpiry == null || DateTime.now().isAfter(DateTime.parse(accessTokenExpiry));
  }

  static Future<bool> isRefreshTokenExpired() async {
    final refreshTokenExpiry = await secureStorage.read(key: 'refreshTokenExpiry');
    return refreshTokenExpiry == null || DateTime.now().isAfter(DateTime.parse(refreshTokenExpiry));
  }
}