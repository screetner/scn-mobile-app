
import '../providers/ApiClient.dart';
import '../types/api/Auth.dart';

class Auth {
  static final Auth _authService = Auth._internal();
  final ApiClient _apiClient = ApiClient();

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
}
