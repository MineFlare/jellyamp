import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import '../theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final api = context.read<AuthProvider>().api;
    final song = player.currentSong;

    if (song == null || api == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF282828),
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                color: Colors.red.withOpacity(0.2),
                child: Text(
                  player.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: api.getImageUrl(song.albumId ?? song.id, maxWidth: 80),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _artPlaceholder(),
                      errorWidget: (_, __, ___) => _artPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.name,
                          style: const TextStyle(
                              color: AppTheme.onBackground,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artistName ?? '',
                          style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final loading =
                          state?.processingState == ProcessingState.loading ||
                          state?.processingState == ProcessingState.buffering;
                      final playing = state?.playing ?? false;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (loading)
                            const SizedBox(
                              width: 40, height: 40,
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.accent),
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppTheme.onBackground,
                                size: 30,
                              ),
                              onPressed: player.togglePlay,
                            ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded,
                                color: AppTheme.onBackground, size: 26),
                            onPressed: player.skipNext,
                          ),
                          const SizedBox(width: 4),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artPlaceholder() => Container(
        color: AppTheme.surfaceElevated,
        child: const Icon(Icons.music_note_rounded, color: AppTheme.subtle, size: 20),
      );
}
