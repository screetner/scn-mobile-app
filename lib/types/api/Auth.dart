
class LoginDTO {
  final String username;
  final String password;

  LoginDTO({
    required this.username,
    required this.password,
  });
}

class LoginResponseDTO {
  final String accessToken;
  final String refreshToken;
  final String tusdToken;
  final String username;
  final String userId;
  final String email;
  final String roleName;
  final String orgName;
  final String accessTokenExpiry;
  final String refreshTokenExpiry;
  final String tusdTokenExpiry;

  LoginResponseDTO({
    required this.accessToken,
    required this.refreshToken,
    required this.tusdToken,
    required this.username,
    required this.userId,
    required this.email,
    required this.roleName,
    required this.orgName,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
    required this.tusdTokenExpiry,
  });

  factory LoginResponseDTO.fromJson(Map<String, dynamic> json) {
    return LoginResponseDTO(
      accessToken: json['user']['accessToken'],
      refreshToken: json['user']['refreshToken'],
      tusdToken: json['user']['tusdToken'],
      username: json['user']['username'],
      userId: json['user']['userId'],
      email: json['user']['email'],
      roleName: json['user']['roleName'],
      orgName: json['user']['orgName'],
      accessTokenExpiry: json['user']['accessTokenExpiry'],
      refreshTokenExpiry: json['user']['refreshTokenExpiry'],
      tusdTokenExpiry: json['user']['tusdTokenExpiry'],
    );
  }
}

class RefreshResponseDTO {
  final String accessToken;
  final String accessTokenExpiry;
  final String refreshToken;
  final String refreshTokenExpiry;
  final String tusdToken;
  final String tusdTokenExpiry;

  RefreshResponseDTO({
    required this.accessToken,
    required this.accessTokenExpiry,
    required this.refreshToken,
    required this.refreshTokenExpiry,
    required this.tusdToken,
    required this.tusdTokenExpiry,
  });

  factory RefreshResponseDTO.fromJson(Map<String, dynamic> json) {
    return RefreshResponseDTO(
      accessToken: json['accessToken'],
      accessTokenExpiry: json['accessTokenExpiry'],
      refreshToken: json['refreshToken'],
      refreshTokenExpiry: json['refreshTokenExpiry'],
      tusdToken: json['tusdToken'],
      tusdTokenExpiry: json['tusdTokenExpiry'],
    );
  }
}