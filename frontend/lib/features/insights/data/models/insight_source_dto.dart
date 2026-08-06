/// DTO for a row from the `insights_sources` allow-list table.
/// Only [is_active] == true rows are fetched (server-side filter).
class InsightSourceDto {
  const InsightSourceDto({
    required this.id,
    required this.name,
    required this.approvedDomain,
    required this.tier,
  });

  final String id;
  final String name;
  final String approvedDomain;

  /// 1 = Premier, 2 = Validated, 3 = Trade
  final int tier;

  String get tierLabel => switch (tier) {
        1 => 'Premier',
        2 => 'Validated',
        _ => 'Trade',
      };

  factory InsightSourceDto.fromJson(Map<String, dynamic> json) {
    return InsightSourceDto(
      id:             json['id'] as String,
      name:           json['name'] as String,
      approvedDomain: json['approved_domain'] as String,
      tier:           json['tier'] as int,
    );
  }
}
