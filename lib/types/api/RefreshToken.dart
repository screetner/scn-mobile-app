class RefreshTokenDTO {
  RefreshTokenDTO();
}

class RefreshTokenResponseDTO {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiry;
  final DateTime refreshTokenExpiry;

  RefreshTokenResponseDTO({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiry,
    required this.refreshTokenExpiry,
  });

  factory RefreshTokenResponseDTO.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseDTO(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      accessTokenExpiry: DateTime.parse(json['accessTokenExpiry']),
      refreshTokenExpiry: DateTime.parse(json['refreshTokenExpiry']),
    );
  }
}
