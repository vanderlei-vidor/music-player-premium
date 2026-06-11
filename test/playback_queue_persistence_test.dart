import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/controllers/playback_queue_persistence.dart';
import 'package:music_music/features/playlists/data/playback_queue_repository.dart';

class FakeQueueRepository implements PlaybackQueueRepository {
  Map<String, dynamic>? stored;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<Map<String, dynamic>?> loadPlaybackQueue() async {
    return stored;
  }

  @override
  Future<void> savePlaybackQueue({
    required List<String> audioUrls,
    required int currentIndex,
    required int positionMs,
  }) async {
    saveCalls += 1;
    stored = {
      'audioUrls': audioUrls,
      'currentIndex': currentIndex,
      'positionMs': positionMs,
    };
  }

  @override
  Future<void> clearPlaybackQueue() async {
    clearCalls += 1;
    stored = null;
  }
}

List<MusicEntity> _library() {
  return [
    MusicEntity(
      id: 1,
      sourceId: 101,
      title: 'Track A',
      artist: 'Artist A',
      album: 'Album A',
      artworkUrl: null,
      audioUrl: 'file://a.mp3',
      duration: 120000,
    ),
    MusicEntity(
      id: 2,
      sourceId: 102,
      title: 'Track B',
      artist: 'Artist B',
      album: 'Album B',
      artworkUrl: null,
      audioUrl: 'file://b.mp3',
      duration: 150000,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var now = DateTime(2026, 5, 21, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 5, 21, 12);
  });

  PlaybackQueuePersistence persistenceFor(FakeQueueRepository repo) {
    return PlaybackQueuePersistence(repository: repo, now: () => now);
  }

  test('restoreQueue returns null when no saved queue', () async {
    final repo = FakeQueueRepository();
    final persistence = persistenceFor(repo);

    final result = await persistence.restoreQueue(_library());
    expect(result, isNull);
  });

  test('restoreQueue maps saved urls to library items', () async {
    final repo = FakeQueueRepository()
      ..stored = {
        'audioUrls': ['file://b.mp3', 'file://missing.mp3'],
        'currentIndex': 10,
        'positionMs': 2300,
      };
    final persistence = persistenceFor(repo);

    final result = await persistence.restoreQueue(_library());
    expect(result, isNotNull);
    expect(result!.queue.length, 1);
    expect(result.queue.first.audioUrl, 'file://b.mp3');
    expect(result.currentIndex, 0);
    expect(result.positionMs, 2300);
  });

  test('saveQueue clears when queue is empty', () async {
    final repo = FakeQueueRepository();
    final persistence = persistenceFor(repo);

    await persistence.saveQueue(
      queue: const <MusicEntity>[],
      currentIndex: 0,
      position: Duration.zero,
      force: true,
    );

    expect(repo.clearCalls, 1);
    expect(repo.saveCalls, 0);
  });

  test('saveQueue persists snapshot with force', () async {
    final repo = FakeQueueRepository();
    final persistence = persistenceFor(repo);
    final queue = _library();

    await persistence.saveQueue(
      queue: queue,
      currentIndex: 1,
      position: const Duration(milliseconds: 5400),
      force: true,
    );

    expect(repo.saveCalls, 1);
    expect(repo.stored, isNotNull);
    expect(repo.stored!['audioUrls'], ['file://a.mp3', 'file://b.mp3']);
    expect(repo.stored!['currentIndex'], 1);
    expect(repo.stored!['positionMs'], 5400);
  });

  test('saveQueue skips small position ticks inside checkpoint window', () async {
    final repo = FakeQueueRepository();
    final persistence = persistenceFor(repo);
    final queue = _library();

    await persistence.saveQueue(
      queue: queue,
      currentIndex: 0,
      position: const Duration(seconds: 10),
      force: true,
    );

    now = now.add(const Duration(seconds: 10));

    await persistence.saveQueue(
      queue: queue,
      currentIndex: 0,
      position: const Duration(seconds: 12),
    );

    expect(repo.saveCalls, 1);
    expect(repo.stored!['positionMs'], 10000);
  });

  test('saveQueue persists position after checkpoint interval', () async {
    final repo = FakeQueueRepository();
    final persistence = persistenceFor(repo);
    final queue = _library();

    await persistence.saveQueue(
      queue: queue,
      currentIndex: 0,
      position: const Duration(seconds: 10),
      force: true,
    );

    now = now.add(PlaybackQueuePersistence.positionPersistInterval);

    await persistence.saveQueue(
      queue: queue,
      currentIndex: 0,
      position: const Duration(seconds: 20),
    );

    expect(repo.saveCalls, 2);
    expect(repo.stored!['positionMs'], 20000);
  });

  test('saveQueue persists immediately when queue index changes', () async {
    final repo = FakeQueueRepository();
    final persistence = persistenceFor(repo);
    final queue = _library();

    await persistence.saveQueue(
      queue: queue,
      currentIndex: 0,
      position: const Duration(seconds: 10),
      force: true,
    );

    now = now.add(const Duration(seconds: 1));

    await persistence.saveQueue(
      queue: queue,
      currentIndex: 1,
      position: const Duration(seconds: 11),
    );

    expect(repo.saveCalls, 2);
    expect(repo.stored!['currentIndex'], 1);
  });
}
