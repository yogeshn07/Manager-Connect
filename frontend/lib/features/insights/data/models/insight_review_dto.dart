import 'package:manager_connect/features/insights/data/models/insight_dto.dart';

/// DTO for a single item returned by the review-insight 'list' action.
/// Fields mirror the ReviewInsight TypeScript interface in review-insight/use-case.ts.
class InsightReviewDto {
  const InsightReviewDto({
    required this.id,
    this.aiHeadline,
    this.aiSummary,
    this.aiWhyMatters,
    this.aiKeyTakeaway,
    this.aiTags = const [],
    this.aiConfidence,
    required this.category,
    this.sourceName,
    this.sourceUrl,
    this.articleDate,
    this.readingTimeMinutes,
    this.heroImageUrl,
    required this.isEvergreen,
    required this.createdAt,
  });

  final String id;
  final String? aiHeadline;
  final String? aiSummary;
  final String? aiWhyMatters;
  final String? aiKeyTakeaway;
  final List<String> aiTags;
  final double? aiConfidence;
  final String category;
  final String? sourceName;
  final String? sourceUrl;
  final String? articleDate;
  final int? readingTimeMinutes;
  final String? heroImageUrl;
  final bool isEvergreen;
  final DateTime createdAt;

  InsightCategory get insightCategory => InsightCategory.fromJson(category);

  factory InsightReviewDto.fromJson(Map<String, dynamic> json) =>
      InsightReviewDto(
        id: json['id'] as String,
        aiHeadline: json['ai_headline'] as String?,
        aiSummary: json['ai_summary'] as String?,
        aiWhyMatters: json['ai_why_matters'] as String?,
        aiKeyTakeaway: json['ai_key_takeaway'] as String?,
        aiTags: (json['ai_tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
        category: json['category'] as String,
        sourceName: json['source_name'] as String?,
        sourceUrl: json['source_url'] as String?,
        articleDate: json['article_date'] as String?,
        readingTimeMinutes: json['reading_time_minutes'] as int?,
        heroImageUrl: json['hero_image_url'] as String?,
        isEvergreen: json['is_evergreen'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
