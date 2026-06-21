import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/polls/data/models/poll_dto.dart';
import 'package:manager_connect/features/polls/data/repositories/poll_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'poll_provider.g.dart';

class PollDetailState {
  const PollDetailState({
    this.poll,
    this.userVoteOptionId,
    this.isLoading = false,
    this.error,
  });

  final PollDto? poll;
  final String? userVoteOptionId;
  final bool isLoading;
  final String? error;

  bool get hasVoted => userVoteOptionId != null;

  PollDetailState copyWith({
    PollDto? poll,
    String? Function()? userVoteOptionId,
    bool? isLoading,
    String? Function()? error,
  }) {
    return PollDetailState(
      poll: poll ?? this.poll,
      userVoteOptionId: userVoteOptionId != null
          ? userVoteOptionId()
          : this.userVoteOptionId,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

@riverpod
class PollDetailNotifier extends _$PollDetailNotifier {
  PollRepository? _repo;

  @override
  PollDetailState build(String pollId) {
    final client = ref.watch(supabaseClientProvider);
    _repo = PollRepository(client);
    return const PollDetailState();
  }

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final results = await Future.wait([
        _repo!.getPoll(pollId),
        _repo!.getUserVoteOptionId(pollId: pollId, userId: userId),
      ]);
      state = state.copyWith(
        poll: results[0] as PollDto,
        userVoteOptionId: () => results[1] as String?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> vote({
    required String optionId,
    required String userId,
  }) async {
    if (state.hasVoted || state.poll == null || state.poll!.isClosed) return;
    try {
      await _repo!.vote(
        pollId: pollId,
        pollOptionId: optionId,
        userId: userId,
      );
      final poll = await _repo!.getPoll(pollId);
      state = state.copyWith(
        poll: poll,
        userVoteOptionId: () => optionId,
      );
    } catch (_) {}
  }
}
