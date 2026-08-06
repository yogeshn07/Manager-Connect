// Catalyst Insights — Data Transfer Object
// Maps 1-to-1 with the `catalyst_insights` table columns.
// Members see only status='active' rows (RLS: catalyst_insights_select_active).
// Admins see all statuses via catalyst_insights_select_admin.

/// The 6 content categories produced by the AI enrichment pipeline.
enum InsightCategory {
  gridTechnology,
  energyTransition,
  industryStandards,
  engineeringLeadership,
  policyMarkets,
  innovation;

  static InsightCategory fromJson(String value) => switch (value) {
        'grid_technology'        => gridTechnology,
        'energy_transition'      => energyTransition,
        'industry_standards'     => industryStandards,
        'engineering_leadership' => engineeringLeadership,
        'policy_markets'         => policyMarkets,
        'innovation'             => innovation,
        _                        => innovation,
      };

  String toJson() => switch (this) {
        gridTechnology        => 'grid_technology',
        energyTransition      => 'energy_transition',
        industryStandards     => 'industry_standards',
        engineeringLeadership => 'engineering_leadership',
        policyMarkets         => 'policy_markets',
        innovation            => 'innovation',
      };

  String get displayLabel => switch (this) {
        gridTechnology        => 'Grid Technology',
        energyTransition      => 'Energy Transition',
        industryStandards     => 'Industry Standards',
        engineeringLeadership => 'Engineering Leadership',
        policyMarkets         => 'Policy & Markets',
        innovation            => 'Innovation',
      };
}

class InsightDto {
  const InsightDto({
    required this.id,
    required this.rawId,
    required this.sourceId,
    required this.urlFingerprint,
    this.aiHeadline,
    this.aiSummary,
    this.aiWhyMatters,
    this.aiKeyTakeaway,
    this.aiTags = const [],
    this.aiConfidence,
    this.sourceName,
    this.sourceUrl,
    this.articleDate,
    this.readingTimeMinutes,
    this.heroImageUrl,
    required this.category,
    required this.isAiGenerated,
    required this.status,
    this.scheduledFor,
    this.publishedAt,
    required this.isEvergreen,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String rawId;
  final String sourceId;
  final String urlFingerprint;
  final String? aiHeadline;
  final String? aiSummary;
  final String? aiWhyMatters;
  final String? aiKeyTakeaway;
  final List<String> aiTags;
  final double? aiConfidence;
  final String? sourceName;
  final String? sourceUrl;
  final String? articleDate;
  final int? readingTimeMinutes;
  final String? heroImageUrl;
  final InsightCategory category;
  final bool isAiGenerated;
  final String status;
  final DateTime? scheduledFor;
  final DateTime? publishedAt;
  final bool isEvergreen;
  final String? reviewedBy;
  final String? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory InsightDto.fromJson(Map<String, dynamic> json) {
    return InsightDto(
      id:               json['id'] as String,
      rawId:            json['raw_id'] as String,
      sourceId:         json['source_id'] as String,
      urlFingerprint:   json['url_fingerprint'] as String,
      aiHeadline:       json['ai_headline'] as String?,
      aiSummary:        json['ai_summary'] as String?,
      aiWhyMatters:     json['ai_why_matters'] as String?,
      aiKeyTakeaway:    json['ai_key_takeaway'] as String?,
      aiTags:           (json['ai_tags'] as List<dynamic>? ?? [])
                            .map((t) => t as String)
                            .toList(),
      aiConfidence:     (json['ai_confidence'] as num?)?.toDouble(),
      sourceName:       json['source_name'] as String?,
      sourceUrl:        json['source_url'] as String?,
      articleDate:      json['article_date'] as String?,
      readingTimeMinutes: json['reading_time_minutes'] as int?,
      heroImageUrl:     json['hero_image_url'] as String?,
      category:         InsightCategory.fromJson(json['category'] as String),
      isAiGenerated:    json['is_ai_generated'] as bool? ?? true,
      status:           json['status'] as String,
      scheduledFor:     json['scheduled_for'] != null
                            ? DateTime.parse(json['scheduled_for'] as String)
                            : null,
      publishedAt:      json['published_at'] != null
                            ? DateTime.parse(json['published_at'] as String)
                            : null,
      isEvergreen:      json['is_evergreen'] as bool? ?? false,
      reviewedBy:       json['reviewed_by'] as String?,
      reviewedAt:       json['reviewed_at'] as String?,
      createdAt:        DateTime.parse(json['created_at'] as String),
      updatedAt:        DateTime.parse(json['updated_at'] as String),
    );
  }
}
