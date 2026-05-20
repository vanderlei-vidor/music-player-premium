import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_music/shared/widgets/rotating_album_cover.dart';

void main() {
  testWidgets('RotatingAlbumCover cancels stream subscription on dispose', (tester) async {
    final controller = StreamController<bool>.broadcast();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RotatingAlbumCover(
          artwork: null,
          playingStream: controller.stream,
          isPlaying: false,
          size: 64,
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    controller.add(true);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await controller.close();
  });
}
