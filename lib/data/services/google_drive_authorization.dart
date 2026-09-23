import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import 'token_storage.dart';

class GoogleDriveAuthorization {
  const GoogleDriveAuthorization({
    required AppConfig config,
    required TokenStore tokenStorage,
  })  : _config = config,
        _tokenStorage = tokenStorage;

  final AppConfig _config;
  final TokenStore _tokenStorage;

  Future<Uri?> authorizationUri() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    return Uri.parse('${_config.apiBaseUrl}/google/authorize').replace(
      queryParameters: {'token': token},
    );
  }

  Future<bool> launch() async {
    final uri = await authorizationUri();
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
