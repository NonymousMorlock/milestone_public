import 'package:milestone/core/utils/core_utils.dart';
import 'package:url_launcher/url_launcher.dart';

sealed class UrlLauncherUtils {
  static Future<void> openLink(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      CoreUtils.showSnackBar(
        logLevel: .error,
        message: 'This link is not available right now.',
      );
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      CoreUtils.showSnackBar(
        logLevel: .error,
        message: 'That link is not formatted correctly.',
      );
      return;
    }

    final launched = await launchUrl(uri);
    if (!launched) {
      CoreUtils.showSnackBar(
        logLevel: .error,
        message: 'Unable to open the link right now.',
      );
    }
  }
}
