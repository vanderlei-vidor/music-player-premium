import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_music/shared/utils/artwork_provider.dart';

void main() {
  test('resolveArtworkImageProvider returns null for unsupported artwork URIs', () {
    expect(resolveArtworkImageProvider(null), isNull);
    expect(resolveArtworkImageProvider(''), isNull);
    expect(resolveArtworkImageProvider('content://media/external/audio/albumart/1'), isNull);
  });

  test('resolveArtworkImageProvider keeps remote artwork on network provider', () {
    final provider = resolveArtworkImageProvider('https://example.com/cover.jpg');

    expect(provider, isA<NetworkImage>());
  });

  test('resolveArtworkImageProvider supports local file artwork outside web', () {
    final provider = resolveArtworkImageProvider('C:\\music\\cover.jpg');

    if (kIsWeb) {
      expect(provider, isNull);
    } else {
      expect(provider, isA<FileImage>());
    }
  });
}
