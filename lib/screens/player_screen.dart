import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import '../models/jellyfin_models.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../theme.dart';
import '../widgets/lyrics_view.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Color _bgColor = const Color(0xFF1a1a2e);
  String? _lastImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateColor());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateColor() async {
    final api = context.read<AuthProvider>().api;
    final song = context.read<PlayerProvider>().currentSong;
    if (api == null || song == null) return;
    final imageUrl = api.getImageUrl(song.albumId ?? song.id, maxWidth: 200);
    if (imageUrl == _lastImageUrl) return;
    _lastImageUrl = imageUrl;
    try {
      final gen = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(200, 200),
      );
      final color = gen.dominantColor?.color ?? gen.mutedColor?.color;
      if (color != null && mounted) {
        setState(() => _bgColor = Color.lerp(color.withOpacity(1), Colors.black, 0.5)!);
      }
    } catch (_) {}
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final api = context.read<AuthProvider>().api;
    final song = player.currentSong;

    if (song == null || api == null) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: Text('Nothing playing')));
    }

    if (api.getImageUrl(song.albumId ?? song.id) != _lastImageUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateColor());
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgColor, AppTheme.background],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [Tab(text: 'Playing'), Tab(text: 'Lyrics')],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPlayingTab(context, player, api, song),
                          LyricsView(
                            lyrics: player.lyrics,
                            currentIndex: player.currentLyricIndex,
                            loading: player.lyricsLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.onBackground, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Now Playing',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPlayingTab(
      BuildContext context, PlayerProvider player, dynamic api, Song song) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildAlbumArt(api, song),
          const SizedBox(height: 28),
          _buildSongInfo(song),
          const SizedBox(height: 24),
          _buildProgressBar(player, song),
          const SizedBox(height: 16),
          _buildControls(player),
          const SizedBox(height: 24),
          _buildQueuePreview(player, api),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(dynamic api, Song song) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: api.getImageUrl(song.albumId ?? song.id),
          width: 280,
          height: 280,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 280,
            height: 280,
            color: AppTheme.surfaceElevated,
            child: const Icon(Icons.album_rounded, color: AppTheme.subtle, size: 64),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 280,
            height: 280,
            color: AppTheme.surfaceElevated,
            child: const Icon(Icons.album_rounded, color: AppTheme.subtle, size: 64),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(Song song) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.name,
                style: const TextStyle(
                    color: AppTheme.onBackground,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                song.artistName ?? '',
                style: const TextStyle(color: AppTheme.subtle, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (song.albumName != null)
                Text(
                  song.albumName!,
                  style: const TextStyle(color: AppTheme.subtle, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(PlayerProvider player, Song song) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.player.duration ?? song.duration;
        final value = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppTheme.onBackground,
                inactiveTrackColor: AppTheme.onBackground.withOpacity(0.2),
                thumbColor: AppTheme.onBackground,
                overlayColor: AppTheme.onBackground.withOpacity(0.1),
              ),
              child: Slider(
                value: value,
                onChanged: (v) {
                  player.seek(Duration(milliseconds: (v * duration.inMilliseconds).round()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position),
                      style: const TextStyle(color: AppTheme.subtle, fontSize: 12)),
                  Text(_formatDuration(duration),
                      style: const TextStyle(color: AppTheme.subtle, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(PlayerProvider player) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShuffleButton(player: player),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 36),
                  color: AppTheme.onBackground,
                  onPressed: player.skipPrevious,
                ),
                _PlayPauseButton(playing: playing, onPressed: player.togglePlay),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 36),
                  color: AppTheme.onBackground,
                  onPressed: player.skipNext,
                ),
                _RepeatButton(player: player),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueuePreview(PlayerProvider player, dynamic api) {
    if (player.queue.isEmpty) return const SizedBox.shrink();
    final nextIndex = player.currentIndex + 1;
    if (nextIndex >= player.queue.length) return const SizedBox.shrink();
    final next = player.queue[nextIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Next up',
            style: TextStyle(color: AppTheme.subtle, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: api.getImageUrl(next.albumId ?? next.id, maxWidth: 80),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                    width: 40, height: 40, color: AppTheme.surfaceElevated),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(next.name,
                      style: const TextStyle(
                          color: AppTheme.onBackground, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(next.artistName ?? '',
                      style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onPressed;

  const _PlayPauseButton({required this.playing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppTheme.onBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: AppTheme.background,
          size: 36,
        ),
      ),
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  final PlayerProvider player;
  const _ShuffleButton({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.player.shuffleModeEnabledStream,
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? false;
        return IconButton(
          icon: Icon(Icons.shuffle_rounded,
              size: 24, color: enabled ? AppTheme.accent : AppTheme.subtle),
          onPressed: player.toggleShuffle,
        );
      },
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final PlayerProvider player;
  const _RepeatButton({required this.player});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        player.repeatMode == PlayerRepeatMode.one
            ? Icons.repeat_one_rounded
            : Icons.repeat_rounded,
        size: 24,
        color: player.repeatMode == PlayerRepeatMode.none ? AppTheme.subtle : AppTheme.accent,
      ),
      onPressed: player.cycleRepeat,
    );
  }
}
