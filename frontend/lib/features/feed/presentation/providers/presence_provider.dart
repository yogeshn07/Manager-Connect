import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tracks which user IDs are currently online via Supabase Realtime Presence.
// Started from MCFeedScreen.initState() once the user is authenticated.
// presenceState() → List<SinglePresenceState>, each with List<Presence> (.payload).

class _PresenceNotifier extends Notifier<Set<String>> {
  RealtimeChannel? _channel;

  @override
  Set<String> build() {
    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });
    return const {};
  }

  Future<void> startTracking(String userId, String fullName) async {
    await _channel?.unsubscribe();
    _channel = null;

    final client = Supabase.instance.client;
    _channel = client.channel('catalysts:presence');

    _channel!
        .onPresenceSync((_) => _sync())
        .onPresenceJoin((_) => _sync())
        .onPresenceLeave((_) => _sync())
        .subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel?.track({
          'user_id': userId,
          'name': fullName,
          'online_at': DateTime.now().toIso8601String(),
        });
        _sync();
      }
    });
  }

  void _sync() {
    // List<SinglePresenceState> → each entry has key + List<Presence>
    // Presence.payload contains the tracked map we sent via channel.track().
    final entries = _channel?.presenceState();
    if (entries == null) return;
    final ids = <String>{};
    for (final entry in entries) {
      for (final presence in entry.presences) {
        final id = presence.payload['user_id'] as String?;
        if (id != null) ids.add(id);
      }
    }
    state = ids;
  }
}

final presenceProvider =
    NotifierProvider<_PresenceNotifier, Set<String>>(_PresenceNotifier.new);
