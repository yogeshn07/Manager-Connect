import 'package:flutter/material.dart';

sealed class FeedItem {
  const FeedItem({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.authorRole,
    required this.timestamp,
    required this.avatarColor,
    required this.reactionCount,
    required this.commentCount,
    required this.repostCount,
  });

  final String id;
  final String authorName;
  final String authorInitials;
  final String authorRole;
  final String timestamp;
  final Color avatarColor;
  final int reactionCount;
  final int commentCount;
  final int repostCount;
}

class TextFeedPost extends FeedItem {
  const TextFeedPost({
    required super.id,
    required super.authorName,
    required super.authorInitials,
    required super.authorRole,
    required super.timestamp,
    required super.avatarColor,
    required super.reactionCount,
    required super.commentCount,
    required super.repostCount,
    required this.body,
    this.isVerified = false,
  });

  final String body;
  final bool isVerified;
}

class RecognitionFeedPost extends FeedItem {
  const RecognitionFeedPost({
    required super.id,
    required super.authorName,
    required super.authorInitials,
    required super.authorRole,
    required super.timestamp,
    required super.avatarColor,
    required super.reactionCount,
    required super.commentCount,
    required super.repostCount,
    required this.bannerLabel,
    required this.subjectName,
    required this.subjectInitials,
    required this.subjectRole,
    required this.subjectColor,
    required this.body,
    required this.proofNames,
    required this.proofInitials,
    required this.proofColors,
    required this.proofTotal,
    required this.proofVerb,
  });

  final String bannerLabel;
  final String subjectName;
  final String subjectInitials;
  final String subjectRole;
  final Color subjectColor;
  final String body;
  final List<String> proofNames;
  final List<String> proofInitials;
  final List<Color> proofColors;
  final int proofTotal;
  final String proofVerb;
}

class PollFeedPost extends FeedItem {
  const PollFeedPost({
    required super.id,
    required super.authorName,
    required super.authorInitials,
    required super.authorRole,
    required super.timestamp,
    required super.avatarColor,
    required super.reactionCount,
    required super.commentCount,
    required super.repostCount,
    required this.question,
    required this.options,
    required this.voteCount,
    required this.timeLeft,
  });

  final String question;
  final List<String> options;
  final int voteCount;
  final String timeLeft;
}

class AchievementFeedPost extends FeedItem {
  const AchievementFeedPost({
    required super.id,
    required super.authorName,
    required super.authorInitials,
    required super.authorRole,
    required super.timestamp,
    required super.avatarColor,
    required super.reactionCount,
    required super.commentCount,
    required super.repostCount,
    required this.body,
    required this.metrics,
    this.isVerified = false,
  });

  final String body;
  final List<AchievementMetric> metrics;
  final bool isVerified;
}

class AchievementMetric {
  const AchievementMetric({required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final IconData? icon;
}

class EventFeedPost extends FeedItem {
  const EventFeedPost({
    required super.id,
    required super.authorName,
    required super.authorInitials,
    required super.authorRole,
    required super.timestamp,
    required super.avatarColor,
    required super.reactionCount,
    required super.commentCount,
    required super.repostCount,
    required this.eventTitle,
    required this.eventMonth,
    required this.eventDay,
    required this.attendeeCount,
    required this.totalCapacity,
    required this.attendeeInitials,
    required this.attendeeColors,
    this.heroColor,
  });

  final String eventTitle;
  final String eventMonth;
  final String eventDay;
  final int attendeeCount;
  final int totalCapacity;
  final List<String> attendeeInitials;
  final List<Color> attendeeColors;
  final Color? heroColor;
}
