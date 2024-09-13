
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
  final String username;
  final String email;
  final String roleName;
  final String orgName;
  final String accessTokenExpiry;
  final String refreshTokenExpiry;

  LoginResponseDTO({
    required this.accessToken,
    required this.refreshToken,
    required this.username,
    required this.email,
    required this.roleName,
    required this.orgName,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
  });

  factory LoginResponseDTO.fromJson(Map<String, dynamic> json) {
    return LoginResponseDTO(
      accessToken: json['user']['accessToken'],
      refreshToken: json['user']['refreshToken'],
      username: json['user']['username'],
      email: json['user']['email'],
      roleName: json['user']['roleName'],
      orgName: json['user']['orgName'],
      accessTokenExpiry: json['user']['accessTokenExpiry'],
      refreshTokenExpiry: json['user']['refreshTokenExpiry'],
    );
  }
}
