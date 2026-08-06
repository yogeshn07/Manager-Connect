import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manager_connect/features/gi_news/data/models/gi_news_item.dart';

class GINewsFeed {
  const GINewsFeed({required this.label, required this.url});
  final String label;
  final String url;
}

/// Fetches news from direct industry RSS feeds.
/// Descriptions come embedded in each feed item — no secondary fetch needed.
class GINewsService {
  static const feeds = [
    // IEEE Spectrum — authoritative source covering all of electrical &
    // electronics engineering: power systems, smart grid, semiconductors,
    // robotics, and emerging tech.
    GINewsFeed(
      label: 'EEE',
      url: 'https://spectrum.ieee.org/feeds/feed.rss',
    ),
    // Power Magazine — power generation, utility operations, grid reliability,
    // turbines, substations, and energy markets.
    GINewsFeed(
      label: 'Power Grid',
      url: 'https://www.powermag.com/feed/',
    ),
    // T&D World — transmission, distribution, substations, grid
    // modernization, protection & control, and line construction.
    GINewsFeed(
      label: 'T&D',
      url: 'https://www.tdworld.com/rss.xml',
    ),
    // Power Engineering — power plant engineering, energy systems, rotating
    // machines, protection, and major OEM coverage (Hitachi, ABB, Siemens…).
    GINewsFeed(
      label: 'Power Eng',
      url: 'https://www.power-eng.com/rss/',
    ),
    // Electrical Engineering Portal — technical EEE articles, protection
    // & control, drives, switchgear, cables, and industry standards.
    GINewsFeed(
      label: 'Industry',
      url: 'https://electrical-engineering-portal.com/feed',
    ),
    // Harvard Business Review — authoritative leadership, management, and
    // corporate strategy content for working managers and executives.
    GINewsFeed(
      label: 'Leadership',
      url: 'https://feeds.hbr.org/harvardbusiness',
    ),
    // MIT Sloan Management Review — research-backed management insights on
    // leadership qualities, team dynamics, and organisational culture.
    GINewsFeed(
      label: 'Leadership',
      url: 'https://sloanreview.mit.edu/feed/',
    ),
  ];

  Future<List<GINewsItem>> fetchAll() async {
    final results = await Future.wait(feeds.map(_fetchFeed));

    final seen = <String>{};
    final all = <GINewsItem>[];
    for (final batch in results) {
      for (final item in batch) {
        if (seen.add(item.articleUrl)) {
          all.add(item);
        }
      }
    }

    all.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return all;
  }

  Future<List<GINewsItem>> _fetchFeed(GINewsFeed feed) async {
    try {
      final uri = Uri.parse(feed.url);
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; GIInsightsApp/1.0)',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*',
      }).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return [];
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      return _parseRss(body, feed.label);
    } catch (_) {
      return [];
    }
  }

  List<GINewsItem> _parseRss(String xml, String topic) {
    final result = <GINewsItem>[];

    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    for (final match in itemRegex.allMatches(xml)) {
      final item = match.group(1)!;

      // Title
      var title = _cdata(item, 'title') ?? _text(item, 'title') ?? '';
      if (title.isEmpty) continue;
      title = _clean(title);

      // Article URL — prefer <link>, fallback to <guid> if it looks like a URL
      final link = _text(item, 'link') ?? '';
      final guid = _text(item, 'guid') ?? '';
      final articleUrl = link.startsWith('http') ? link
          : guid.startsWith('http') ? guid
          : null;
      if (articleUrl == null) continue;

      // Publication date
      final pubDateStr = _text(item, 'pubDate') ?? '';
      final publishedAt =
          pubDateStr.isNotEmpty ? _parseRfc2822(pubDateStr) : DateTime.now();

      // Description — strip HTML, keep as plain text summary (1-3 sentences)
      final rawDesc = _cdata(item, 'description') ?? _text(item, 'description') ?? '';
      final description = rawDesc.isNotEmpty ? _clean(rawDesc) : null;

      // Source name
      final sourceTag = RegExp(r'<source[^>]*>(.*?)</source>', dotAll: true)
          .firstMatch(item)?.group(1)?.trim();
      final dcCreator = _text(item, 'dc:creator');
      final sourceName = (sourceTag?.isNotEmpty == true ? sourceTag! : null)
          ?? (dcCreator?.isNotEmpty == true ? dcCreator! : null)
          ?? _hostName(articleUrl);

      // Thumbnail image
      final imageUrl = _extractImage(item, rawDesc);

      result.add(GINewsItem(
        id: articleUrl,
        title: title,
        articleUrl: articleUrl,
        sourceName: sourceName,
        publishedAt: publishedAt,
        topic: topic,
        imageUrl: imageUrl,
        description: description,
      ));
    }

    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String? _extractImage(String item, String descRaw) {
    final mediaContent =
        RegExp(r'<media:content[^>]+url="([^"]+)"', caseSensitive: false)
            .firstMatch(item)?.group(1);
    if (mediaContent != null) return mediaContent;

    final mediaThumbnail =
        RegExp(r'<media:thumbnail[^>]+url="([^"]+)"', caseSensitive: false)
            .firstMatch(item)?.group(1);
    if (mediaThumbnail != null) return mediaThumbnail;

    final enclosure =
        RegExp(r'<enclosure[^>]+url="([^"]+)"[^>]+type="image/', caseSensitive: false)
            .firstMatch(item)?.group(1);
    if (enclosure != null) return enclosure;

    return RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false)
        .firstMatch(descRaw)?.group(1);
  }

  String _hostName(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Strip HTML, decode entities, collapse whitespace.
  String _clean(String s) {
    return _decodeEntities(
      s.replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    );
  }

  String? _cdata(String xml, String tag) {
    final r = RegExp('<$tag>\\s*<!\\[CDATA\\[(.*?)\\]\\]>\\s*</$tag>',
        dotAll: true);
    return r.firstMatch(xml)?.group(1)?.trim();
  }

  String? _text(String xml, String tag) {
    final r = RegExp('<$tag>(.*?)</$tag>', dotAll: true);
    return r.firstMatch(xml)?.group(1)?.trim();
  }

  String _decodeEntities(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#8230;', '…')
      .replaceAll('&#8216;', '‘')
      .replaceAll('&#8217;', '’')
      .replaceAll('&#8220;', '“')
      .replaceAll('&#8221;', '”');

  DateTime _parseRfc2822(String s) {
    try {
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final parts = s.trim().split(RegExp(r'\s+'));
      int i = 0;
      if (parts[i].endsWith(',')) i++;
      final day   = int.parse(parts[i++]);
      final month = months[parts[i++]] ?? 1;
      final year  = int.parse(parts[i++]);
      final tp    = parts[i].split(':');
      return DateTime.utc(year, month, day,
          int.parse(tp[0]), int.parse(tp[1]), int.parse(tp[2]));
    } catch (_) {
      return DateTime.now();
    }
  }
}
