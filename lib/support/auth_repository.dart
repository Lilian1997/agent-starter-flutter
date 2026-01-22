import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config.dart';

part 'auth_repository.g.dart';

// Singleton instances to prevent state loss during OAuth flow
final FlutterAppAuth _sharedAppAuth = FlutterAppAuth();
const FlutterSecureStorage _sharedSecureStorage = FlutterSecureStorage();

/// User information extracted from the ID token
class UserInfo {
  final String? name;
  final String? preferredUsername;
  final String? email;
  final String? givenName;
  final String? familyName;

  const UserInfo({
    this.name,
    this.preferredUsername,
    this.email,
    this.givenName,
    this.familyName,
  });

  /// Returns the best available display name
  String get displayName => name ?? preferredUsername ?? email ?? 'User';
}

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
  static const _idTokenKey = 'auth_id_token';

  bool get isDevMode => dotenv.env['DEV_MODE'] == 'true';

  AuthRepository._internal();

  Future<String?> checkAuth() async {
    if (isDevMode) {
      final devToken = dotenv.env['AUTH_TOKEN'];
      print('🔐 [AuthRepository] Dev token: $devToken');
      if (devToken != null) {
        await _secureStorage.write(key: _tokenKey, value: devToken);
        return devToken;
      }
    }
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get user information from the stored ID token
  Future<UserInfo?> getUserInfo() async {
    try {
      final idToken = await _secureStorage.read(key: _idTokenKey);
      if (idToken == null) return null;

      // JWT format: header.payload.signature
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (middle part)
      // Add padding if needed for base64 decoding
      String payload = parts[1];
      payload = base64.normalize(payload);
      
      final payloadJson = utf8.decode(base64.decode(payload));
      final Map<String, dynamic> claims = jsonDecode(payloadJson);

      return UserInfo(
        name: claims['name'] as String?,
        preferredUsername: claims['preferred_username'] as String?,
        email: claims['email'] as String?,
        givenName: claims['given_name'] as String?,
        familyName: claims['family_name'] as String?,
      );
    } catch (e) {
      print('⚠️ [AuthRepository] Failed to parse ID token: $e');
      return null;
    }
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
      // final result = await _appAuth.authorizeAndExchangeCode(
      //   AuthorizationTokenRequest(
      //     _keycloakConfig.clientId,
      //     _keycloakConfig.redirectUrl,
      //     discoveryUrl: _keycloakConfig.discoveryUrl,
      //     scopes: ['openid', 'profile', 'email'],
      //     promptValues: ['login'], // Use promptValues instead of additionalParameters
      //   ),
      // );

      // print('🔐 [AuthRepository] OAuth result: $result');

      // if (result != null && result.accessToken != null) {
      //   print('🔐 [AuthRepository] Got access token successfully!');
      //   await _secureStorage.write(key: _tokenKey, value: result.accessToken);
      //   if (result.idToken != null) {
      //     await _secureStorage.write(key: _idTokenKey, value: result.idToken);
      //   }
      //   print('🔐 [AuthRepository] access token: ${result.accessToken}');
      //   return result.accessToken;
      // }

      final devAccessToken = dotenv.env['AUTH_TOKEN'];
      final devIdToken = dotenv.env['AUTH_ID_TOKEN'];

      if (devAccessToken != null && devIdToken != null) {
        print('🔐 [AuthRepository] Got access token successfully!');
        await _secureStorage.write(key: _tokenKey, value: devAccessToken);
        await _secureStorage.write(key: _idTokenKey, value: devIdToken);
        print('🔐 [AuthRepository] access token: $devAccessToken');
        return devAccessToken;
      }

      print('🔐 [AuthRepository] No access token in result');
      return null;
    } on FlutterAppAuthUserCancelledException {
      print('ℹ️ [AuthRepository] User cancelled login');
      throw AuthCancelledException();
    } catch (e, stackTrace) {
      print('❌ [AuthRepository] OAuth error: $e');
      print('❌ [AuthRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      // 1. Get ID Token for hint
      String? idToken;
      try {
        idToken = await _secureStorage.read(key: _idTokenKey);
      } catch (_) {}

      // 2. Local Cleanup
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _idTokenKey);

      // 3. End Session at Provider (Keycloak)
      if (idToken != null) {
        print('🔐 [AuthRepository] Ending session with provider...');
        await _appAuth.endSession(
          EndSessionRequest(
            idTokenHint: idToken,
            postLogoutRedirectUrl: _keycloakConfig.redirectUrl,
            discoveryUrl: _keycloakConfig.discoveryUrl,
          ),
        );
        print('✅ [AuthRepository] Provider session ended');
      }
    } catch (e) {
      print('⚠️ [AuthRepository] Logout error: $e');
    }
  }
}

class AuthCancelledException implements Exception {}
