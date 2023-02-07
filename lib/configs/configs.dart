import 'package:aad_oauth/model/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigEnvironmentVariable {
  static final clientId = dotenv.get('AZURE_CLIENT_ID');
  static final tenantId = dotenv.get('AZURE_TENANT_ID');
  static final redirectUri = dotenv.get('AZURE_REDIRECT_URI');
  static final azureContainerImageUrl = dotenv.get('AZURE_CONTAINER_IMAGE_URL');
  static final serviceURL = dotenv.get('SERVICE_URL');
  static final environment = dotenv.get('ENVIRONMENT');
  static final version = dotenv.get('VERSION', fallback: null);
}

class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();
}

class PreferencesKeys {
  static const accessToken = 'access_token';
}

class OAuthConfig {
  static final Config config = Config(
    tenant: ConfigEnvironmentVariable.tenantId,
    clientId: ConfigEnvironmentVariable.clientId,
    scope: "openid profile offline_access",
    redirectUri: ConfigEnvironmentVariable.redirectUri,
    navigatorKey: NavigationService.navigatorKey,
    webUseRedirect: true,
    loader: const Center(child: CircularProgressIndicator()),
  );
}
