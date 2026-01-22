import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'livekit_token_repository.g.dart';

@riverpod
LiveKitTokenRepository liveKitTokenRepository(Ref ref) {
  return LiveKitTokenRepository(Dio());
}

class LiveKitTokenRepository {
  final Dio _dio;
  final logger = Logger('LiveKitTokenRepository');

  LiveKitTokenRepository(this._dio);

  bool get isDevMode => dotenv.env['DEV_MODE'] == 'true';
  String get livekitTokenExchangeUrl => dotenv.env['LIVEKIT_TOKEN_EXCHANGE_URL']!;

  /// 取得 LiveKit token
  /// [accessToken] Keycloak access token
  /// [roomName] 房間名稱
  /// [nickName] 使用者暱稱（可選）
  Future<String> getToken(
    String accessToken,
    String roomName, {
    String? nickName,
  }) async {
    logger.info('Requesting LiveKit token for room: $roomName, nickName: $nickName');

    if (isDevMode) {
      final devToken = dotenv.env['LIVEKIT_TOKEN']?.replaceAll('"', '');
      return devToken!;
    }

    try {
      // 建立請求 body
      final Map<String, dynamic> requestBody = {
        'room': roomName,
      };
      
      // 如果有 nickName 才加入
      if (nickName != null && nickName.isNotEmpty) {
        requestBody['nickName'] = nickName;
      }

      // 拿 keycloak token 去取 livekit token
      final response = await _dio.post(
        livekitTokenExchangeUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.data != null && response.data is Map) {
        final token = response.data['token'];
        if (token == null || token is! String || token.isEmpty) {
          throw Exception('回應中缺少有效的 token');
        }
        logger.info('Successfully obtained LiveKit token');
        return token;
      }

      throw Exception('無效的回應格式');
    } on DioException catch (e) {
      // 針對不同的 HTTP 錯誤狀態碼處理
      final statusCode = e.response?.statusCode;
      // Check if data is a Map before accessing ['message']
      final responseData = e.response?.data;
      final errorMessage = (responseData is Map ? responseData['message'] : null) ?? e.message;

      switch (statusCode) {
        case 401:
          logger.severe('Token 已過期或無效');
          throw Exception('認證失敗：Token 已過期，請重新登入');
        case 403:
          logger.severe('權限不足');
          throw Exception('權限不足：無法加入此房間');
        case 404:
          logger.severe('端點不存在');
          throw Exception('服務暫時不可用');
        case 500:
        case 502:
        case 503:
          logger.severe('伺服器錯誤: $statusCode');
          throw Exception('伺服器錯誤，請稍後再試');
        default:
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            logger.severe('連線逾時');
            throw Exception('連線逾時，請檢查網路狀態');
          }
          if (e.type == DioExceptionType.connectionError) {
            logger.severe('無法連線到伺服器');
            throw Exception('無法連線到伺服器，請檢查網路');
          }
          logger.severe('取得 token 失敗: $errorMessage');
          throw Exception('取得 token 失敗: $errorMessage');
      }
    } catch (e) {
      logger.severe('未知錯誤: $e');
      throw Exception('取得 token 時發生錯誤: $e');
    }
  }
}
