import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/recognition/data/models/recognition_dto.dart';
import 'package:manager_connect/features/recognition/data/repositories/recognition_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'recognition_provider.g.dart';

class RecognitionFeedState {
  const RecognitionFeedState({
    this.recognitions = const [],
    this.isLoading = false,
    this.error,
  });

  final List<RecognitionDto> recognitions;
  final bool isLoading;
  final String? error;

  RecognitionFeedState copyWith({
    List<RecognitionDto>? recognitions,
    bool? isLoading,
    String? Function()? error,
  }) {
    return RecognitionFeedState(
      recognitions: recognitions ?? this.recognitions,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class RecognitionFeedNotifier extends _$RecognitionFeedNotifier {
  RecognitionRepository? _repo;

  @override
  RecognitionFeedState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = RecognitionRepository(client);
    return const RecognitionFeedState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final recognitions = await _repo!.getRecognitions();
      state = state.copyWith(
        recognitions: recognitions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> refresh() async {
    try {
      final recognitions = await _repo!.getRecognitions();
      state = state.copyWith(
        recognitions: recognitions,
        error: () => null,
      );
    } catch (_) {}
  }
}
