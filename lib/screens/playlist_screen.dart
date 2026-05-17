import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jellyfin_models.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/download_service.dart';
import '../theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Song>? _songs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().api!;
    final songs =
        await context.read<LibraryProvider>().getPlaylistSongs(api, widget.playlist.id);
    if (mounted) setState(() { _songs = songs; _loading = false; });
  }

  void _playSong(int index) {
    final api = context.read<AuthProvider>().api!;
    final downloads = context.read<DownloadService>();
    final songs = _songs!.map((s) {
      final dl = downloads.getDownloaded(s.id);
      if (dl != null) { s.localPath = dl.localPath; s.isDownloaded = true; }
      return s;
    }).toList();
    context.read<PlayerProvider>().playQueue(songs, index, api);
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthProvider>().api!;
    final player = context.watch<PlayerProvider>();
    final downloads = context.watch<DownloadService>();
    final hasSong = player.currentSong != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          if (_songs?.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () {
                final songs = List<Song>.from(_songs!)..shuffle();
                context.read<PlayerProvider>().playQueue(songs, 0, api);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent))
                : _songs == null || _songs!.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.playlist_play_rounded,
                                size: 64, color: AppTheme.subtle),
                            SizedBox(height: 12),
                            Text('No songs in playlist',
                                style: TextStyle(color: AppTheme.subtle)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: ElevatedButton.icon(
                              onPressed: () => _playSong(0),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text('Play all (${_songs!.length} songs)'),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _songs!.length,
                              itemBuilder: (context, i) {
                                final song = _songs![i];
                                final isPlaying =
                                    player.currentSong?.id == song.id;
                                final isDownloaded =
                                    downloads.isDownloaded(song.id);
                                final isDownloading =
                                    downloads.isDownloading(song.id);
                                return SongTile(
                                  song: song,
                                  imageUrl: api.getImageUrl(
                                      song.albumId ?? song.id,
                                      maxWidth: 80),
                                  isPlaying: isPlaying,
                                  isDownloaded: isDownloaded,
                                  isDownloading: isDownloading,
                                  downloadProgress:
                                      downloads.getProgress(song.id),
                                  onTap: () => _playSong(i),
                                  onDownload: isDownloaded || isDownloading
                                      ? null
                                      : () => downloads.download(song, api),
                                  onRemoveDownload: isDownloaded
                                      ? () => downloads.remove(song.id)
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
          if (hasSong) const MiniPlayer(),
        ],
      ),
    );
  }
}
