import 'dart:math';
import 'package:flutter/material.dart';

import 'package:music_music/shared/utils/artwork_provider.dart';

class AnimatedAlbumCover extends StatefulWidget {
  final String? artwork;

  const AnimatedAlbumCover({
    super.key,
    required this.artwork,
  });

  @override
  State<AnimatedAlbumCover> createState() => _AnimatedAlbumCoverState();
}

class _AnimatedAlbumCoverState extends State<AnimatedAlbumCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artworkProvider = resolveArtworkImageProvider(widget.artwork);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = sin(_controller.value * 2 * pi) * 6;

        return Transform.translate(
          offset: Offset(0, t),
          child: Transform.scale(
            scale: 1.02,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                image: artworkProvider != null
                    ? DecorationImage(
                        image: artworkProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.black38,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 40,
                    spreadRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
              child: artworkProvider == null
                  ? const Icon(
                      Icons.album,
                      size: 90,
                      color: Colors.white70,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
