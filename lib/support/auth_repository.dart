import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(const FlutterAppAuth(), const FlutterSecureStorage(), KeycloakConfig());
}

class AuthRepository {
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _secureStorage;
  final KeycloakConfig _keycloakConfig;
  static const _tokenKey = 'auth_token';

  bool get isDevMode => dotenv.env['DEV_MODE'] == 'true';

  AuthRepository(this._appAuth, this._secureStorage, this._keycloakConfig);

  Future<String?> checkAuth() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> login() async {
    if (isDevMode) {
      final devToken = dotenv.env['AUTH_TOKEN'];
      if (devToken == null) return null;

      await _secureStorage.write(key: _tokenKey, value: devToken);
      return devToken;
    }

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _keycloakConfig.clientId,
          _keycloakConfig.redirectUrl,
          discoveryUrl: _keycloakConfig.discoveryUrl,
          scopes: ['openid', 'profile', 'email'],
        ),
      );

      if (result != null && result.accessToken != null) {
        await _secureStorage.write(key: _tokenKey, value: result.accessToken);
        return result.accessToken;
      }

      return null;
    } catch (e) {
      // Create a specific failure or return null
      return null;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
