import 'package:aad_oauth/model/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final clientId = dotenv.get(
  'AZURE_CLIENT_ID',
  fallback: '9e02c5ef-9fad-46e0-adc3-e674f7427987',
);
final tenantId = dotenv.get(
  'AZURE_TENANT_ID',
  fallback: '0babbab9-2561-48f0-a5de-0b4ac6473951',
);
final redirectUri = dotenv.get(
  'AZURE_REDIRECT_URI',
  fallback:
      'msauth://io.anyline.flutter.examples/VzSiQcXRmi2kyjzcA%2BmYLEtbGVs%3D',
);

class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();
}

class PreferencesKeys {
  static const accessToken = 'access_token';
}

class OAuthConfig {
  static final Config config = Config(
    tenant: tenantId,
    clientId: clientId,
    scope:
        "api://9e02c5ef-9fad-46e0-adc3-e674f7427987/User.Read openid profile offline_access",
    redirectUri: redirectUri,
    navigatorKey: NavigationService.navigatorKey,
    loader: const Center(child: CircularProgressIndicator()),
  );
}
