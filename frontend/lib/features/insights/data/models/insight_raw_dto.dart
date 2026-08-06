class InsightRawDto {
  const InsightRawDto({
    required this.id,
    required this.sourceId,
    required this.rawUrl,
    required this.urlFingerprint,
    this.titleFingerprint,
    required this.status,
    this.ogTitle,
    this.ogDescription,
    this.ogImageUrl,
    this.submittedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sourceId;
  final String rawUrl;
  final String urlFingerprint;
  final String? titleFingerprint;
  final String status;
  final String? ogTitle;
  final String? ogDescription;
  final String? ogImageUrl;
  final String? submittedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory InsightRawDto.fromJson(Map<String, dynamic> json) => InsightRawDto(
        id: json['id'] as String,
        sourceId: json['source_id'] as String,
        rawUrl: json['raw_url'] as String,
        urlFingerprint: json['url_fingerprint'] as String,
        titleFingerprint: json['title_fingerprint'] as String?,
        status: json['status'] as String,
        ogTitle: json['og_title'] as String?,
        ogDescription: json['og_description'] as String?,
        ogImageUrl: json['og_image_url'] as String?,
        submittedBy: json['submitted_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
