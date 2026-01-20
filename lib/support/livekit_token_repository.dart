import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'livekit_token_repository.g.dart';

@riverpod
LiveKitTokenRepository liveKitTokenRepository(Ref ref) {
  return LiveKitTokenRepository(Dio());
}

class LiveKitTokenRepository {
  final Dio _dio;

  LiveKitTokenRepository(this._dio);

  bool get isDevMode => dotenv.env['DEV_MODE'] == 'true';

  Future<String> getToken(String accessToken, String roomName) async {
    if (isDevMode) {
      return dotenv.env['LIVEKIT_TOKEN']!;
    }
// 因為後端還沒串接，先用 hardcode 的 token
    return dotenv.env['LIVEKIT_TOKEN']!;
    
    try {
      // 拿 keycloak token 去取 livekit token
      final response = await _dio.post(
        '/api/livekit/token',
        data: {'roomName': roomName},
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.data != null && response.data is Map) {
        return response.data['token'] as String;
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get token: $e');
    }
  }
}
