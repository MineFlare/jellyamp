import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jellyfin_models.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/download_service.dart';
import '../theme.dart';
import '../widgets/song_tile.dart';

class DownloadsTab extends StatelessWidget {
  const DownloadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadService>();
    final player = context.watch<PlayerProvider>();
    final api = context.read<AuthProvider>().api;
    final songs = downloads.downloads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          if (songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: 'Shuffle all',
              onPressed: api == null
                  ? null
                  : () {
                      final shuffled = List<Song>.from(songs)..shuffle();
                      player.playQueue(shuffled, 0, api);
                    },
            ),
        ],
      ),
      body: songs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_for_offline_rounded, size: 72, color: AppTheme.subtle),
                  SizedBox(height: 16),
                  Text('No downloads yet',
                      style: TextStyle(color: AppTheme.onBackground, fontSize: 18)),
                  SizedBox(height: 6),
                  Text('Download songs to listen offline',
                      style: TextStyle(color: AppTheme.subtle)),
                ],
              ),
            )
          : Column(
              children: [
                if (songs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Text('${songs.length} songs downloaded',
                            style: const TextStyle(color: AppTheme.subtle, fontSize: 13)),
                        const Spacer(),
                        if (api != null)
                          TextButton.icon(
                            onPressed: () => player.playQueue(songs, 0, api),
                            icon: const Icon(Icons.play_arrow_rounded,
                                size: 18, color: AppTheme.accent),
                            label: const Text('Play all',
                                style: TextStyle(color: AppTheme.accent)),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: songs.length,
                    itemBuilder: (context, i) {
                      final song = songs[i];
                      return SongTile(
                        song: song,
                        imageUrl: api?.getImageUrl(song.albumId ?? song.id, maxWidth: 80),
                        isPlaying: player.currentSong?.id == song.id,
                        isDownloaded: true,
                        onTap: () {
                          if (api != null) player.playQueue(songs, i, api);
                        },
                        onRemoveDownload: () => _confirmRemove(context, downloads, song),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, DownloadService downloads, Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Remove download',
            style: TextStyle(color: AppTheme.onBackground)),
        content: Text('Remove "${song.name}" from downloads?',
            style: const TextStyle(color: AppTheme.subtle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.subtle)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await downloads.remove(song.id);
    }
  }
}
