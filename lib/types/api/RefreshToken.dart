class RefreshTokenDTO {
  RefreshTokenDTO();
}

class RefreshTokenResponseDTO {
  final String accessToken;
  final String refreshToken;
  final String tusdToken;
  final DateTime accessTokenExpiry;
  final DateTime refreshTokenExpiry;
  final DateTime tusdTokenExpiry;

  RefreshTokenResponseDTO({
    required this.accessToken,
    required this.refreshToken,
    required this.tusdToken,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
    required this.tusdTokenExpiry,
  });

  factory RefreshTokenResponseDTO.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseDTO(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tusdToken: json['tusdToken'],
      accessTokenExpiry: DateTime.parse(json['accessTokenExpiry']),
      refreshTokenExpiry: DateTime.parse(json['refreshTokenExpiry']),
      tusdTokenExpiry: DateTime.parse(json['tusdTokenExpiry']),
    );
  }
}
