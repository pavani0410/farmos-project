import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import '../api/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  static const FlutterAppAuth appAuth = FlutterAppAuth();

  static const String clientId = '4uocsbsm0nvcsb7dmjt23ph6vf';

  static const String redirectUrl =
      'com.farmos.app://oauthredirect';

  static const String issuer =
      'https://cognito-idp.ap-southeast-2.amazonaws.com/ap-southeast-2_e9SbsucDJ';

  /// Launches Cognito Hosted UI and returns the raw token response
  /// (access token, ID token, refresh token) from AWS.
  static Future<AuthorizationTokenResponse?> login({bool forceFresh = false}) async {
    return await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        redirectUrl,
        issuer: issuer,
        scopes: [
          'openid',
          'email',
          'phone',
        ],
        promptValues: forceFresh ? ['login'] : null,
      ),
    );
  }
/// Opens Cognito's logout endpoint in the browser, clearing the
  /// Hosted UI + Amazon session so the next login prompts fresh credentials.
  static Future<void> logout() async {
    const String cognitoDomain =
        'https://ap-southeast-2e9sbsucdj.auth.ap-southeast-2.amazoncognito.com';

    final logoutUrl = Uri.parse(
      '$cognitoDomain/logout'
      '?client_id=$clientId'
      '&logout_uri=${Uri.encodeComponent(redirectUrl)}',
    );

    if (await canLaunchUrl(logoutUrl)) {
      await launchUrl(logoutUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open logout page');
    }
  }

  /// Sends the Cognito ID token to our Spring Boot backend, which validates
  /// it and returns our own app's {id, username} — same shape as
  /// ApiService.login(), so it can be used identically for navigation.
  static Future<Map<String, dynamic>> exchangeWithBackend(
    String idToken,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/cognito'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body['error'] ?? 'Amazon login failed');
  }
}