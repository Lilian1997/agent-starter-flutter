import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config.dart';

part 'auth_repository.g.dart';

// Singleton instances to prevent state loss during OAuth flow
final FlutterAppAuth _sharedAppAuth = FlutterAppAuth();
const FlutterSecureStorage _sharedSecureStorage = FlutterSecureStorage();

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository.instance;
}

class AuthRepository {
  // Singleton pattern
  static final AuthRepository instance = AuthRepository._internal();
  
  FlutterAppAuth get _appAuth => _sharedAppAuth;
  FlutterSecureStorage get _secureStorage => _sharedSecureStorage;
  final KeycloakConfig _keycloakConfig = KeycloakConfig();
  static const _tokenKey = 'auth_token';

  bool get isDevMode => dotenv.env['DEV_MODE'] == 'true';

  AuthRepository._internal();

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

    print('🔐 [AuthRepository] Starting OAuth login...');
    print('🔐 [AuthRepository] Client ID: ${_keycloakConfig.clientId}');
    print('🔐 [AuthRepository] Redirect URL: ${_keycloakConfig.redirectUrl}');
    print('🔐 [AuthRepository] Discovery URL: ${_keycloakConfig.discoveryUrl}');

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _keycloakConfig.clientId,
          _keycloakConfig.redirectUrl,
          discoveryUrl: _keycloakConfig.discoveryUrl,
          scopes: ['openid', 'profile', 'email'],
          promptValues: ['login'], // Use promptValues instead of additionalParameters
        ),
      );

      print('🔐 [AuthRepository] OAuth result: $result');

      if (result != null && result.accessToken != null) {
        print('🔐 [AuthRepository] Got access token successfully!');
        await _secureStorage.write(key: _tokenKey, value: result.accessToken);
        print('🔐 [AuthRepository] access token: ${result.accessToken}');
        return result.accessToken;
      }

      print('🔐 [AuthRepository] No access token in result');
      return null;
    } catch (e, stackTrace) {
      print('❌ [AuthRepository] OAuth error: $e');
      print('❌ [AuthRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
