import 'package:tus_client_background_demo/types/api/VideoSession.dart';

import '../providers/ApiClient.dart';
import '../types/ImmutableUploadManagerContext.dart';

class VideoSession {
  static final VideoSession _authService = VideoSession._internal(ApiClient());
  final ApiClient _apiClient;

  factory VideoSession() {
    return _authService;
  }

  VideoSession._internal(this._apiClient);

  VideoSession._withApiClient(this._apiClient);

  static Future<VideoSession> createInstance(ApiClient apiClient) async {
    try {
      return VideoSession._withApiClient(apiClient);
    }  catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<PostVideoSessionResponseDTO> createVideoSession(PostVideoSessionDTO body) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/videoSession/create',
        data: {
          'uploadProgress': 0,
          'videoNames': body.videoNames,
        },
      );
      return PostVideoSessionResponseDTO.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  Future<UpdateVideoSessionResponseDTO> updateVideoSessionState(UpdateVideoSessionDTO body) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/videoSession/updateState',
        data: {
          'videoSessionId': body.videoSessionId,
          'uploadProgress': body.uploadProgressPercentage,
          'state': body.state.toString().split('.').last,
        },
      );
      return UpdateVideoSessionResponseDTO.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }
}
