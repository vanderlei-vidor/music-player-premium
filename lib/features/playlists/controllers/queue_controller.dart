import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_music/data/models/music_entity.dart';

class QueueController {
  QueueController({required int Function() rawQueueIndex})
      : _rawQueueIndex = rawQueueIndex;

  final int Function() _rawQueueIndex;

  List<MusicEntity> queue = <MusicEntity>[];
  bool isShuffled = false;
  LoopMode repeatMode = LoopMode.off;

  int get currentIndex {
    final idx = _rawQueueIndex();
    if (queue.isEmpty) return 0;
    return idx.clamp(0, queue.length - 1);
  }

  int get queueCount => queue.length;

  int currentPosition() {
    if (queue.isEmpty) return 1;
    return currentIndex + 1;
  }

  List<String> titles({int limit = 1000}) {
    if (queue.isEmpty) return const <String>[];
    final list = <String>[];
    for (var i = 0; i < queue.length && list.length < limit; i++) {
      list.add(queue[i].title);
    }
    return list;
  }

  int indexOfAudioUrl(String audioUrl) {
    return queue.indexWhere((m) => m.audioUrl == audioUrl);
  }

  bool replaceByAudioUrl(MusicEntity updated) {
    final idx = indexOfAudioUrl(updated.audioUrl);
    if (idx == -1) return false;
    queue[idx] = updated;
    return true;
  }

  bool replaceIfDifferent(List<MusicEntity> nextQueue) {
    final same = listEquals(
      queue.map((e) => e.audioUrl).toList(),
      nextQueue.map((e) => e.audioUrl).toList(),
    );
    if (same) return false;
    queue = List<MusicEntity>.from(nextQueue);
    return true;
  }

  int reorder({
    required int oldIndex,
    required int newIndex,
    int? currentMusicId,
  }) {
    if (queue.isEmpty) return 0;
    if (oldIndex < 0 || oldIndex >= queue.length) return currentIndex;
    if (newIndex < 0 || newIndex > queue.length) return currentIndex;

    final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    final moved = queue.removeAt(oldIndex);
    queue.insert(targetIndex, moved);

    if (currentMusicId != null) {
      final idx = queue.indexWhere((m) => m.id == currentMusicId);
      return idx == -1 ? 0 : idx;
    }
    return targetIndex.clamp(0, queue.length - 1);
  }
}
