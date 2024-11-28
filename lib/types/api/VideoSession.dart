enum VideoSessionStateEnum {
  uploading,
  uploaded,
  processing,
  processed,
  canDelete,
}

class PostVideoSessionDTO {
  final List<String> videoNames;

  PostVideoSessionDTO({
    required this.videoNames,
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
  final VideoSessionStateEnum state;

  UpdateVideoSessionDTO({
    required this.videoSessionId,
    required this.uploadProgressPercentage,
    required this.state,
  });
}

class UpdateVideoSessionResponseDTO {
  final String videoSessionId;

  UpdateVideoSessionResponseDTO({
    required this.videoSessionId,
  });

  factory UpdateVideoSessionResponseDTO.fromJson(Map<String, dynamic> json) {
    return UpdateVideoSessionResponseDTO(
        videoSessionId: json['videoSessionId']
    );
  }
}