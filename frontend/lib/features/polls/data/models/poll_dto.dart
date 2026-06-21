class PollOptionDto {
  const PollOptionDto({
    required this.id,
    required this.pollId,
    required this.optionText,
    required this.displayOrder,
    this.voteCount = 0,
  });

  final String id;
  final String pollId;
  final String optionText;
  final int displayOrder;
  final int voteCount;

  factory PollOptionDto.fromJson(Map<String, dynamic> json) {
    final votes = json['poll_votes'];
    int count = 0;
    if (votes is List) {
      count = votes.length;
    } else if (votes is Map && votes.containsKey('count')) {
      count = votes['count'] as int;
    }
    return PollOptionDto(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      optionText: json['option_text'] as String,
      displayOrder: json['display_order'] as int,
      voteCount: count,
    );
  }
}

class PollDto {
  const PollDto({
    required this.id,
    this.activityId,
    required this.createdBy,
    required this.question,
    required this.closesAt,
    required this.isClosed,
    required this.createdAt,
    this.options = const [],
  });

  final String id;
  final String? activityId;
  final String createdBy;
  final String question;
  final DateTime closesAt;
  final bool isClosed;
  final DateTime createdAt;
  final List<PollOptionDto> options;

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);

  factory PollDto.fromJson(Map<String, dynamic> json) {
    final opts = json['poll_options'];
    return PollDto(
      id: json['id'] as String,
      activityId: json['activity_id'] as String?,
      createdBy: json['created_by'] as String,
      question: json['question'] as String,
      closesAt: DateTime.parse(json['closes_at'] as String),
      isClosed: json['is_closed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      options: opts is List
          ? (opts.map((o) => PollOptionDto.fromJson(o as Map<String, dynamic>)).toList()
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)))
          : [],
    );
  }
}
