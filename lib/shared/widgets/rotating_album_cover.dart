import 'dart:async';

import 'package:flutter/material.dart';

import 'package:music_music/shared/utils/artwork_provider.dart';

class RotatingAlbumCover extends StatefulWidget {
  final String? artwork;
  final Stream<bool> playingStream;
  final bool isPlaying;
  final double size;

  const RotatingAlbumCover({
    super.key,
    required this.artwork,
    required this.playingStream,
    required this.isPlaying,
    this.size = 180,
  });

  @override
  State<RotatingAlbumCover> createState() => _RotatingAlbumCoverState();
}

class _RotatingAlbumCoverState extends State<RotatingAlbumCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    _subscribeToPlayingStream(widget.playingStream);

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RotatingAlbumCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playingStream != widget.playingStream) {
      _playingSub?.cancel();
      _subscribeToPlayingStream(widget.playingStream);
    }
  }

  void _subscribeToPlayingStream(Stream<bool> stream) {
    _playingSub = stream.listen((isPlaying) {
      if (isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artworkProvider = resolveArtworkImageProvider(widget.artwork);

    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: artworkProvider != null
                ? DecorationImage(
                    image: artworkProvider,
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.black38,
          ),
          child: artworkProvider == null
              ? const Icon(Icons.album, size: 80, color: Colors.white70)
              : null,
        ),
      ),
    );
  }
}
