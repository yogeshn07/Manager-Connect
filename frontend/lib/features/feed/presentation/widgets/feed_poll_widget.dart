import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/events/data/repositories/activity_repository.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class FeedPollWidget extends ConsumerStatefulWidget {
  const FeedPollWidget({required this.poll, required this.userId, super.key});

  final PollDto poll;
  final String userId;

  @override
  ConsumerState<FeedPollWidget> createState() => _FeedPollWidgetState();
}

class _FeedPollWidgetState extends ConsumerState<FeedPollWidget> {
  late String? _myVoteId;
  late Map<String, int> _voteCounts;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _myVoteId = null;
    for (final option in widget.poll.options) {
      for (final vote in option.votes) {
        if (vote.userId == widget.userId) {
          _myVoteId = option.id;
          break;
        }
      }
      if (_myVoteId != null) break;
    }
    _voteCounts = {for (final o in widget.poll.options) o.id: o.votes.length};
  }

  Future<void> _vote(String optionId) async {
    if (_voting || !widget.poll.isActive || widget.userId.isEmpty) return;
    setState(() => _voting = true);

    final prevVote = _myVoteId;
    // Optimistic update
    setState(() {
      if (prevVote != null && _voteCounts.containsKey(prevVote)) {
        _voteCounts[prevVote] = (_voteCounts[prevVote]! - 1).clamp(0, 999999);
      }
      _voteCounts[optionId] = (_voteCounts[optionId] ?? 0) + 1;
      _myVoteId = optionId;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      await FeedRepository(client).castVote(
        pollId: widget.poll.id,
        optionId: optionId,
        userId: widget.userId,
      );
      // Sync RSVP when poll is linked to an activity
      final activityId = widget.poll.activityId;
      if (activityId != null && widget.userId.isNotEmpty) {
        PollOptionDto? votedOption;
        for (final o in widget.poll.options) {
          if (o.id == optionId) { votedOption = o; break; }
        }
        final rsvpStatus = _mapOptionToRsvp(votedOption?.optionText);
        if (rsvpStatus != null) {
          try {
            await ActivityRepository(client).upsertRsvp(
              activityId: activityId,
              userId: widget.userId,
              status: rsvpStatus,
            );
          } catch (_) {}
        }
      }
    } catch (_) {
      // Revert
      setState(() {
        _voteCounts[optionId] = (_voteCounts[optionId]! - 1).clamp(0, 999999);
        if (prevVote != null) {
          _voteCounts[prevVote] = (_voteCounts[prevVote] ?? 0) + 1;
        }
        _myVoteId = prevVote;
      });
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  static String? _mapOptionToRsvp(String? optionText) {
    if (optionText == null) return null;
    final t = optionText.toLowerCase();
    if (t.contains('not') || t.contains('unavailable')) return 'not_going';
    if (t.contains('maybe')) return 'maybe';
    if (t.contains('available') || t.contains('going') || t.contains('yes')) return 'going';
    return null;
  }

  void _showVoters(PollOptionDto option) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _VotersSheet(option: option),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _voteCounts.values.fold(0, (a, b) => a + b);
    final hasVoted = _myVoteId != null;
    final showResults = hasVoted || !widget.poll.isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.poll.options.map((option) {
          final count = _voteCounts[option.id] ?? 0;
          final isMyVote = _myVoteId == option.id;
          final pct = total == 0 ? 0.0 : count / total;

          if (showResults) {
            return GestureDetector(
              onTap: () {
                if (isMyVote || !widget.poll.isActive) {
                  _showVoters(option);
                } else {
                  _vote(option.id);
                }
              },
              child: _ResultRow(
                option: option,
                count: count,
                pct: pct,
                isMyVote: isMyVote,
              ),
            );
          } else {
            return GestureDetector(
              onTap: _voting ? null : () => _vote(option.id),
              child: _ChoiceRow(option: option, voting: _voting),
            );
          }
        }),
        const SizedBox(height: 8),
        Text(
          '$total vote${total == 1 ? '' : 's'} · '
          '${widget.poll.isActive ? _closesInLabel(widget.poll.closesAt) : 'Poll closed'}',
          style: MCTypography.caption,
        ),
      ],
    );
  }

  String _closesInLabel(DateTime closesAt) {
    final diff = closesAt.difference(DateTime.now());
    if (diff.inDays > 1) return 'Closes in ${diff.inDays}d';
    if (diff.inHours > 1) return 'Closes in ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Closes soon';
    return 'Closing';
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.option,
    required this.count,
    required this.pct,
    required this.isMyVote,
  });

  final PollOptionDto option;
  final int count;
  final double pct;
  final bool isMyVote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Background
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
              border: Border.all(
                color: isMyVote ? MCColors.primary : MCColors.border,
                width: isMyVote ? 1.5 : 1,
              ),
              color: isMyVote
                  ? MCColors.primaryPale
                  : MCColors.background,
            ),
          ),
          // Fill bar
          FractionallySizedBox(
            widthFactor: pct.clamp(0.02, 1.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
                color: isMyVote
                    ? MCColors.primary.withValues(alpha: 0.18)
                    : MCColors.primaryPale.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  if (isMyVote) ...[
                    const Icon(Icons.check_circle, size: 14, color: MCColors.primary),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      option.optionText,
                      style: MCTypography.body.copyWith(
                        fontWeight: isMyVote ? FontWeight.w600 : null,
                        color: isMyVote ? MCColors.primary : MCColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(pct * 100).round()}%',
                    style: MCTypography.captionBold
                        .copyWith(color: MCColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· $count',
                    style: MCTypography.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.option, required this.voting});

  final PollOptionDto option;
  final bool voting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
          border: Border.all(color: MCColors.border),
          color: MCColors.background,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              option.optionText,
              style: MCTypography.body.copyWith(
                color: voting ? MCColors.textMuted : MCColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _VotersSheet extends StatelessWidget {
  const _VotersSheet({required this.option});

  final PollOptionDto option;

  @override
  Widget build(BuildContext context) {
    final voters = option.votes;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                MCSpacing.pageH, MCSpacing.pageH, MCSpacing.pageH, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: MCColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Voted for:', style: MCTypography.caption),
                const SizedBox(height: 2),
                Text(option.optionText, style: MCTypography.h4),
                const SizedBox(height: 12),
                const Divider(height: 1, color: MCColors.borderLight),
              ],
            ),
          ),
          if (voters.isEmpty)
            Padding(
              padding: const EdgeInsets.all(MCSpacing.pageH),
              child: Text('No votes yet', style: MCTypography.caption),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: voters.length,
                itemBuilder: (_, i) {
                  final name = voters[i].voterName ?? 'Member';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                  return ListTile(
                    leading: MCAvatar(
                      initials: initial,
                      size: MCAvatar.sm,
                      backgroundColor: MCColors.primary,
                    ),
                    title: Text(name, style: MCTypography.body),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
