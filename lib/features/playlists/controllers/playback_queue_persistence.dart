import 'package:music_music/core/audio/playback_queue_store.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/data/playback_queue_repository.dart';

class QueueRestoreResult {
  final List<MusicEntity> queue;
  final int currentIndex;
  final int positionMs;

  const QueueRestoreResult({
    required this.queue,
    required this.currentIndex,
    required this.positionMs,
  });
}

class PlaybackQueuePersistence {
  PlaybackQueuePersistence({
    required PlaybackQueueRepository repository,
    DateTime Function()? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now;

  static const Duration positionPersistInterval = Duration(seconds: 30);
  static const Duration positionPersistDelta = Duration(seconds: 15);

  final PlaybackQueueRepository _repository;
  final DateTime Function() _now;
  bool _isPersisting = false;
  bool _isRestoring = false;
  DateTime? _lastPersistAt;
  Duration _lastPersistedPosition = Duration.zero;
  String? _lastPersistedQueueKey;
  int? _lastPersistedIndex;

  bool get isRestoring => _isRestoring;

  Future<void> clear() async {
    await _repository.clearPlaybackQueue();
    _lastPersistAt = null;
    _lastPersistedPosition = Duration.zero;
    _lastPersistedQueueKey = null;
    _lastPersistedIndex = null;
  }

  Future<QueueRestoreResult?> restoreQueue(List<MusicEntity> library) async {
    if (_isRestoring) return null;
    _isRestoring = true;
    try {
      final saved = await _repository.loadPlaybackQueue();
      if (saved == null) return null;

      final savedUrls = (saved['audioUrls'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList();
      if (savedUrls.isEmpty) return null;

      final byUrl = <String, MusicEntity>{};
      for (final music in library) {
        byUrl[music.audioUrl] = music;
      }

      final restoredQueue = <MusicEntity>[];
      for (final url in savedUrls) {
        final music = byUrl[url];
        if (music != null) restoredQueue.add(music);
      }
      if (restoredQueue.isEmpty) return null;

      final currentIndex = (saved['currentIndex'] as int? ?? 0)
          .clamp(0, restoredQueue.length - 1);
      final positionMs = saved['positionMs'] as int? ?? 0;
      return QueueRestoreResult(
        queue: restoredQueue,
        currentIndex: currentIndex,
        positionMs: positionMs,
      );
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> saveQueue({
    required List<MusicEntity> queue,
    required int currentIndex,
    required Duration position,
    bool force = false,
  }) async {
    if (_isRestoring) return;
    if (queue.isEmpty) {
      await clear();
      return;
    }
    if (_isPersisting) return;

    final now = _now();
    final queueKey = _queueKey(queue);
    final queueChanged =
        queueKey != _lastPersistedQueueKey ||
        currentIndex != _lastPersistedIndex;
    final sinceLastPersist =
        _lastPersistAt == null ? null : now.difference(_lastPersistAt!);
    final movedMs = (position - _lastPersistedPosition).inMilliseconds.abs();
    final positionCheckpointDue =
        sinceLastPersist == null ||
        sinceLastPersist >= positionPersistInterval ||
        movedMs >= positionPersistDelta.inMilliseconds;
    final shouldPersist = force || queueChanged || positionCheckpointDue;

    if (!shouldPersist) return;

    _isPersisting = true;
    try {
      await _repository.savePlaybackQueue(
        audioUrls: queue.map((m) => m.audioUrl).toList(),
        currentIndex: currentIndex,
        positionMs: position.inMilliseconds,
      );
      await PlaybackQueueStore.saveSnapshot(
        queue: queue,
        currentIndex: currentIndex,
        positionMs: position.inMilliseconds,
      );
      _lastPersistAt = now;
      _lastPersistedPosition = position;
      _lastPersistedQueueKey = queueKey;
      _lastPersistedIndex = currentIndex;
    } finally {
      _isPersisting = false;
    }
  }

  String _queueKey(List<MusicEntity> queue) {
    return queue.map((m) => m.audioUrl).join('\u001f');
  }
}
