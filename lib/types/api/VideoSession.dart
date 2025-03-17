class PostVideoSessionDTO {
  final List<String> videoNames;
  final String videoSessionName;

  PostVideoSessionDTO({
    required this.videoNames,
    required this.videoSessionName,
  });
}

class PostVideoSessionResponseDTO {
  final String videoSessionId;

  PostVideoSessionResponseDTO({
    required this.videoSessionId,
  });

  factory PostVideoSessionResponseDTO.fromJson(Map<String, dynamic> json) {
    return PostVideoSessionResponseDTO(
      videoSessionId: json['videoSessionId']
    );
  }
}

class UpdateVideoSessionDTO {
  final String videoSessionId;
  final int uploadProgressPercentage;

  UpdateVideoSessionDTO({
    required this.videoSessionId,
    required this.uploadProgressPercentage,
  });
}

class UpdateVideoSessionResponseDTO {
  final String message;

  UpdateVideoSessionResponseDTO({
    required this.message,
  });

  factory UpdateVideoSessionResponseDTO.fromJson(Map<String, dynamic> json) {
    return UpdateVideoSessionResponseDTO(
        message: json['message']
    );
  }
}