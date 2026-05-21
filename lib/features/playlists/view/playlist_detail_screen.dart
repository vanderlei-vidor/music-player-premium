import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:music_music/app/routes.dart';
import 'package:music_music/core/observability/app_logger.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';
import 'package:music_music/shared/widgets/artwork_image.dart';
import 'package:music_music/shared/widgets/swipe_to_reveal_actions.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<List<MusicEntity>> _displayedMusics =
      ValueNotifier<List<MusicEntity>>(<MusicEntity>[]);
  final Set<int> _removingMusicIds = <int>{};

  List<MusicEntity> _allMusics = [];
  List<MusicEntity> _filteredMusics = [];

  @override
  void initState() {
    super.initState();
    _reloadMusics();
    _searchController.addListener(_filterMusics);
  }

  @override
  void didUpdateWidget(covariant PlaylistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlistId != widget.playlistId) {
      _reloadMusics();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _displayedMusics.dispose();
    super.dispose();
  }

  void _reloadMusics() {
    context
        .read<PlaylistViewModel>()
        .getMusicsFromPlaylistV2(widget.playlistId)
        .then((musics) {
      if (!mounted) return;
      _allMusics = musics;
      _filteredMusics = musics;
      _syncDisplayedMusics();
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar playlist: $error'),
          ),
        );
    });
  }

  void _filterMusics() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredMusics = _allMusics;
    } else {
      _filteredMusics = _allMusics.where((music) {
        return music.title.toLowerCase().contains(query) ||
            music.artist.toLowerCase().contains(query);
      }).toList();
    }
    _syncDisplayedMusics();
  }

  void _syncDisplayedMusics() {
    _displayedMusics.value = List<MusicEntity>.unmodifiable(_filteredMusics);
  }

  Future<void> _openMusicSelection() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.musicSelection,
      arguments: MusicSelectionArgs(
        playlistId: widget.playlistId,
        playlistName: widget.playlistName,
      ),
    );
    if (!mounted) return;
    if (result is MusicSelectionResult) {
      _allMusics = result.playlistMusics;
      _filterMusics();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reloadMusics();
    });

    final addedCount = switch (result) {
      MusicSelectionResult result => result.addedCount,
      int value => value,
      _ => 0,
    };
    if (addedCount > 0) {
      debugPrint('Playlist atualizada com $addedCount item(ns) adicionados');
    }
  }

  Future<void> _removeMusicWithUndo(MusicEntity music) async {
    final musicId = music.id;
    if (musicId == null) return;

    final allIndex = _allMusics.indexWhere((m) => m.id == musicId);
    final filteredIndex = _filteredMusics.indexWhere((m) => m.id == musicId);
    if (allIndex == -1 || filteredIndex == -1) return;

    setState(() {
      _removingMusicIds.add(musicId);
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    final vm = context.read<PlaylistViewModel>();
    await vm.removeMusicFromPlaylist(widget.playlistId, musicId);

    _allMusics.removeWhere((m) => m.id == musicId);
    _filteredMusics.removeWhere((m) => m.id == musicId);
    _syncDisplayedMusics();

    setState(() {
      _removingMusicIds.remove(musicId);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Musica removida da playlist'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              await vm.addMusicToPlaylistV2(widget.playlistId, musicId);

              final insertAll = allIndex.clamp(0, _allMusics.length);
              _allMusics.insert(insertAll, music);

              final query = _searchController.text.toLowerCase();
              final passesFilter =
                  query.isEmpty ||
                  music.title.toLowerCase().contains(query) ||
                  music.artist.toLowerCase().contains(query);
              if (passesFilter) {
                final insertFiltered = filteredIndex.clamp(0, _filteredMusics.length);
                _filteredMusics.insert(insertFiltered, music);
              }

              _syncDisplayedMusics();
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.read<PlaylistViewModel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Adicionar musica'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: () async {
          HapticFeedback.selectionClick();
          await _openMusicSelection();
        },
      ),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildHeaderBackground(theme),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            ),
                            Expanded(
                              child: Text(
                                widget.playlistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar na playlist',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: theme.colorScheme.surface.withValues(alpha: 0.92),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: theme.scaffoldBackgroundColor,
            child: SizedBox(
              height: 86,
              child: Center(
                child: _PlaylistActionBar(
                  musics: _allMusics,
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<MusicEntity>>(
              valueListenable: _displayedMusics,
              builder: (_, musics, __) {
                return _buildMusicContent(theme, viewModel, musics);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicContent(
    ThemeData theme,
    PlaylistViewModel viewModel,
    List<MusicEntity> musics,
  ) {
    if (musics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Esta playlist ainda esta vazia',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione musicas para comecar a curtir',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar musicas'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                HapticFeedback.selectionClick();
                await _openMusicSelection();
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96, top: 8),
      itemCount: musics.length,
      itemBuilder: (context, index) {
          final music = musics[index];
          final shadows = Theme.of(context).extension<AppShadows>()?.surface ?? [];
          ArtworkCache.preload(context, music.artworkUrl);

          final isRemoving = music.id != null && _removingMusicIds.contains(music.id);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isRemoving ? 0.0 : 1.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: isRemoving ? 0.95 : 1.0,
                child: SwipeToRevealActions(
                  isFavorite: music.isFavorite,
                  onToggleFavorite: () async {
                    final vm = context.read<PlaylistViewModel>();
                    HapticFeedback.selectionClick();
                    final newValue = await vm.toggleFavorite(music);

                    final allIndex = _allMusics.indexWhere((m) => m.id == music.id);
                    if (allIndex != -1) {
                      _allMusics[allIndex] = _allMusics[allIndex].copyWith(
                        isFavorite: newValue,
                      );
                    }

                    final filteredIndex = _filteredMusics.indexWhere((m) => m.id == music.id);
                    if (filteredIndex != -1) {
                      _filteredMusics[filteredIndex] =
                          _filteredMusics[filteredIndex].copyWith(
                        isFavorite: newValue,
                      );
                    }
                    _syncDisplayedMusics();
                  },
                  onDelete: () {
                    HapticFeedback.selectionClick();
                    _removeMusicWithUndo(music);
                  },
                  child: _PressableTile(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final queueIndex = _allMusics.indexWhere((m) => m.id == music.id);
                      if (queueIndex == -1) return;
                      if (viewModel.isShuffled) {
                        final shuffled = List<MusicEntity>.from(_allMusics)..shuffle();
                        viewModel.playMusic(shuffled, 0);
                      } else {
                        viewModel.playMusic(_allMusics, queueIndex);
                      }
                    },
                    onDoubleTap: () {
                      Navigator.pushNamed(context, AppRoutes.player);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: shadows,
                      ),
                      child: ListTile(
                        leading: ArtworkThumb(
                          artworkUrl: music.artworkUrl,
                          audioUrl: music.audioUrl,
                          audioId: music.sourceId ?? music.id,
                        ),
                        title: Text(music.title),
                        subtitle: Text(music.artist),
                        trailing: Selector<PlaylistViewModel, _NowPlayingState>(
                          selector: (_, vm) => _NowPlayingState(
                            id: vm.currentMusic?.id,
                            isPlaying: vm.isPlaying,
                          ),
                          builder: (_, state, __) {
                            final isCurrent = state.id == music.id;
                            if (!isCurrent) return const SizedBox.shrink();
                            return Icon(
                              Icons.equalizer,
                              color: theme.colorScheme.primary,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
      },
    );
  }

  Widget _buildHeaderBackground(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.9),
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.10)),
          ),
        ),
      ],
    );
  }
}

class _PlaylistActionBar extends StatelessWidget {
  final List<MusicEntity> musics;

  const _PlaylistActionBar({required this.musics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = context.select<PlaylistViewModel, bool>((vm) => vm.isPlaying);
    final isShuffled =
        context.select<PlaylistViewModel, bool>((vm) => vm.isShuffled);
    final currentQueue =
        context.select<PlaylistViewModel, List<MusicEntity>>((vm) => vm.queueMusics);
    final vm = context.read<PlaylistViewModel>();

    final isCurrentQueueFromPlaylist =
        musics.isNotEmpty && _isSamePlaylistQueue(currentQueue, musics);

    Future<void> playOrPausePlaylist() async {
      if (musics.isEmpty) return;
      AppLogger.info(
        'PlaylistDetailScreen',
        'play/pause tapped | musics=${musics.length} | isPlaying=$isPlaying | '
        'isShuffled=$isShuffled | sameQueue=$isCurrentQueueFromPlaylist | '
        'currentQueue=${currentQueue.length}',
      );
      if (isCurrentQueueFromPlaylist) {
        if (isPlaying) {
          await vm.pause();
        } else {
          await vm.play();
        }
        AppLogger.info(
          'PlaylistDetailScreen',
          'play/pause handled as transport control | nowPlaying=${vm.currentMusic?.title ?? '-'}',
        );
        return;
      }
      await vm.playAllFromPlaylist(musics);
      AppLogger.info(
        'PlaylistDetailScreen',
        'play/pause delegated to playAllFromPlaylist | nowPlaying=${vm.currentMusic?.title ?? '-'}',
      );
    }

    Future<void> toggleShuffleForPlaylist() async {
      if (musics.isEmpty) return;
      AppLogger.info(
        'PlaylistDetailScreen',
        'shuffle tapped | musics=${musics.length} | isPlaying=$isPlaying | '
        'isShuffled=$isShuffled | sameQueue=$isCurrentQueueFromPlaylist | '
        'currentQueue=${currentQueue.length}',
      );
      if (!isShuffled) {
        await vm.toggleShuffle();
        AppLogger.info(
          'PlaylistDetailScreen',
          'shuffle enabled from playlist action bar',
        );
      }
      if (isCurrentQueueFromPlaylist && isPlaying) return;
      await vm.playAllFromPlaylist(musics);
      AppLogger.info(
        'PlaylistDetailScreen',
        'shuffle delegated to playAllFromPlaylist | nowPlaying=${vm.currentMusic?.title ?? '-'}',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isPlaying && isCurrentQueueFromPlaylist
                    ? Icons.pause
                    : Icons.play_arrow,
                key: ValueKey<bool>(isPlaying && isCurrentQueueFromPlaylist),
                color: theme.colorScheme.onPrimary,
                size: 28,
              ),
            ),
            onPressed: playOrPausePlaylist,
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
          IconButton(
            onPressed: toggleShuffleForPlaylist,
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isShuffled
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                    child: RotationTransition(
                      turns: Tween(begin: 0.9, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  Icons.shuffle,
                  key: ValueKey(isShuffled),
                  size: 24,
                  color: isShuffled
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSamePlaylistQueue(
    List<MusicEntity> currentQueue,
    List<MusicEntity> playlistMusics,
  ) {
    if (currentQueue.length != playlistMusics.length) return false;

    for (var i = 0; i < currentQueue.length; i++) {
      if (currentQueue[i].audioUrl != playlistMusics[i].audioUrl) {
        return false;
      }
    }

    return true;
  }
}

class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const _PressableTile({
    required this.child,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class _NowPlayingState {
  final int? id;
  final bool isPlaying;

  const _NowPlayingState({required this.id, required this.isPlaying});

  @override
  bool operator ==(Object other) {
    return other is _NowPlayingState &&
        other.id == id &&
        other.isPlaying == isPlaying;
  }

  @override
  int get hashCode => Object.hash(id, isPlaying);
}
