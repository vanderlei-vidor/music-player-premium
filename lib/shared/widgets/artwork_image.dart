import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_music/shared/utils/artwork_provider.dart';

class ArtworkCache {
  static final LinkedHashMap<String, ImageProvider> _cache = LinkedHashMap();
  static const int _maxEntries = 200;
  static int _maxEntriesOverride = _maxEntries;

  static ImageProvider? provider(String? url) {
    if (url == null || url.isEmpty) return null;
    final existing = _cache.remove(url);
    if (existing != null) {
      _cache[url] = existing;
      return existing;
    }
    final created = resolveArtworkImageProvider(url);
    if (created == null) return null;
    _cache[url] = created;
    if (_cache.length > _maxEntriesOverride) {
      _cache.remove(_cache.keys.first);
    }
    return created;
  }

  static void preload(BuildContext context, String? url) {
    final image = provider(url);
    if (image == null) return;
    precacheImage(image, context);
  }

  static void configure({int? maxEntries}) {
    if (maxEntries != null && maxEntries > 50) {
      _maxEntriesOverride = maxEntries;
    }
  }

  static void clear() {
    _cache.clear();
    ArtworkQueryCache.clear();
  }
}

class ArtworkQueryCache {
  static final OnAudioQuery _audioQuery = OnAudioQuery();
  static final LinkedHashMap<String, Future<Uint8List?>> _cache =
      LinkedHashMap();
  static const int defaultSize = 200;
  static const int defaultQuality = 70;
  static const int _maxEntries = 160;

  static Future<Uint8List?>? query({
    required int? audioId,
    required String? audioUrl,
    int size = defaultSize,
    int quality = defaultQuality,
  }) {
    if (kIsWeb || audioId == null) return null;

    final key = _cacheKey(audioId: audioId, audioUrl: audioUrl, size: size);
    final existing = _cache.remove(key);
    if (existing != null) {
      _cache[key] = existing;
      return existing;
    }

    final created = _audioQuery
        .queryArtwork(audioId, ArtworkType.AUDIO, size: size, quality: quality)
        .catchError((Object _, StackTrace __) => null);
    _cache[key] = created;
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return created;
  }

  static String _cacheKey({
    required int audioId,
    required String? audioUrl,
    required int size,
  }) {
    final trimmedUrl = audioUrl?.trim();
    if (trimmedUrl != null && trimmedUrl.isNotEmpty) {
      return 'url:$trimmedUrl|size:$size';
    }
    return 'id:$audioId|size:$size';
  }

  static void clear() {
    _cache.clear();
  }
}

class ArtworkImage extends StatelessWidget {
  final String? artworkUrl;
  final String? audioUrl;
  final int? audioId;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final int targetSize;
  final bool animate;
  final Widget? fallback;

  const ArtworkImage({
    super.key,
    required this.artworkUrl,
    this.audioUrl,
    this.audioId,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.targetSize = ArtworkQueryCache.defaultSize,
    this.animate = false,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final provider = ArtworkCache.provider(artworkUrl);
    final fallbackWidget = fallback ?? const ArtworkFallback();

    Widget child;
    if (provider != null) {
      child = Image(
        key: ValueKey('artwork-url-${artworkUrl ?? ''}'),
        image: provider,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallbackWidget,
      );
    } else {
      final future = ArtworkQueryCache.query(
        audioId: audioId,
        audioUrl: audioUrl,
        size: targetSize,
      );
      if (future == null) {
        child = fallbackWidget;
      } else {
        child = FutureBuilder<Uint8List?>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return fallbackWidget;
            }
            return Image.memory(
              snapshot.data!,
              key: ValueKey(
                'artwork-query-${audioUrl ?? audioId}-$targetSize',
              ),
              width: width,
              height: height,
              fit: fit,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => fallbackWidget,
            );
          },
        );
      }
    }

    child = ClipRRect(
      key: ValueKey(
        'artwork-${artworkUrl ?? audioUrl ?? audioId ?? 'fallback'}-$targetSize',
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: child),
    );

    if (!animate) return child;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: child,
    );
  }
}

class ArtworkThumb extends StatelessWidget {
  final String? artworkUrl;
  final String? audioUrl;
  final int? audioId;

  const ArtworkThumb({
    super.key,
    required this.artworkUrl,
    this.audioUrl,
    this.audioId,
  });

  @override
  Widget build(BuildContext context) {
    return ArtworkImage(
      artworkUrl: artworkUrl,
      audioUrl: audioUrl,
      audioId: audioId,
      width: 48,
      height: 48,
      borderRadius: 12,
      targetSize: 160,
    );
  }
}

class ArtworkSquare extends StatelessWidget {
  final String? artworkUrl;
  final String? audioUrl;
  final int? audioId;
  final double borderRadius;

  const ArtworkSquare({
    super.key,
    required this.artworkUrl,
    this.audioUrl,
    this.audioId,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ArtworkImage(
      artworkUrl: artworkUrl,
      audioUrl: audioUrl,
      audioId: audioId,
      borderRadius: borderRadius,
      targetSize: 320,
    );
  }
}

class ArtworkFallback extends StatelessWidget {
  final double iconSize;

  const ArtworkFallback({super.key, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.35),
            theme.colorScheme.secondary.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Icon(Icons.music_note, color: Colors.white70, size: iconSize),
    );
  }
}
