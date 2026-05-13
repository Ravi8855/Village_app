import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Best-effort Play Store listing scrape for release notes.
/// Falls back gracefully when parsing fails or the app is not yet published.
class PlayStoreMetadataDataSource {
  PlayStoreMetadataDataSource(this._client);

  final http.Client _client;

  Future<String?> fetchReleaseNotes() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName&hl=en',
      );

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      return _parseWhatsNew(response.body);
    } catch (_) {
      return null;
    }
  }

  String? _parseWhatsNew(String html) {
    final whatsNewIndex = html.indexOf('What&#39;s new');
    if (whatsNewIndex != -1) {
      final slice = html.substring(whatsNewIndex, whatsNewIndex + 2500);
      final match = RegExp(
        r'<motion\.motion[^>]*>([\s\S]*?)</motion\.motion>',
        caseSensitive: false,
      ).firstMatch(slice);
      if (match != null) {
        final text = _cleanHtml(match.group(1) ?? '');
        if (text.isNotEmpty) return text;
      }
    }

    final descriptionMatch = RegExp(
      r'itemprop="description"[\s\S]*?<span[^>]*>([\s\S]*?)</span>',
      caseSensitive: false,
    ).firstMatch(html);
    if (descriptionMatch != null) {
      final text = _cleanHtml(descriptionMatch.group(1) ?? '');
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  String _cleanHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
