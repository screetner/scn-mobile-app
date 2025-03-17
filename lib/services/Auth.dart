import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../providers/ApiClient.dart';
import '../types/api/Auth.dart';
import 'models/SecureStorageCache.dart';

class Auth {
  static final Auth _authService = Auth._internal();
  final ApiClient _apiClient = ApiClient();

  static final FlutterSecureStorage secureStorage = SecureStorageCache();

  factory Auth() {
    return _authService;
  }

  Auth._internal();

  Future<LoginResponseDTO> login(LoginDTO body) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': body.username,
          'password': body.password,
        },
      );
      return LoginResponseDTO.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  Future<RefreshResponseDTO> refresh() async {
    try {
      final accessToken = await secureStorage.read(key: 'accessToken');
      final refreshToken = await secureStorage.read(key: 'refreshToken');
      final tusdToken = await secureStorage.read(key: 'tusdToken');

      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'AuthorizationRefresh': 'Bearer $refreshToken',
            'AuthorizationTusd': 'Bearer $tusdToken',
          },
        ),
      );
      return RefreshResponseDTO.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }
}
