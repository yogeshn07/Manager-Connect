class PipelineHealthDto {
  const PipelineHealthDto({
    required this.rawQueueByStatus,
    required this.rawTotal,
    required this.catalystByStatus,
    required this.catalystTotal,
    required this.failedEnrichmentCount,
    required this.stalledValidationCount,
    required this.scheduledCount,
    required this.archivedCount,
    required this.ingestedLast24h,
    this.avgTimeToPublishMs,
    required this.latencySampleSize,
    required this.checkedAt,
  });

  final Map<String, int> rawQueueByStatus;
  final int rawTotal;
  final Map<String, int> catalystByStatus;
  final int catalystTotal;
  final int failedEnrichmentCount;
  final int stalledValidationCount;
  final int scheduledCount;
  final int archivedCount;
  final int ingestedLast24h;
  final double? avgTimeToPublishMs;
  final int latencySampleSize;
  final DateTime checkedAt;
}

class PipelineJobDto {
  const PipelineJobDto({
    required this.id,
    required this.rawUrl,
    required this.status,
    required this.sourceId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String rawUrl;
  final String status;
  final String sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PipelineJobDto.fromJson(Map<String, dynamic> json) => PipelineJobDto(
        id: json['id'] as String,
        rawUrl: json['raw_url'] as String,
        status: json['status'] as String,
        sourceId: json['source_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
