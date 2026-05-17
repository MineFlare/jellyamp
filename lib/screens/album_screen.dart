import 'package:cached_network_image/cached_network_image.dart';
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

class AlbumScreen extends StatefulWidget {
  final Album album;
  const AlbumScreen({super.key, required this.album});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<Song>? _songs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().api!;
    final songs = await context.read<LibraryProvider>().getAlbumSongs(api, widget.album.id);
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
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: api.getImageUrl(widget.album.id),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppTheme.surfaceElevated),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppTheme.background],
                              stops: [0.4, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.album.name,
                                  style: const TextStyle(
                                      color: AppTheme.onBackground,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                [
                                  widget.album.artistName ?? '',
                                  if (widget.album.year != null)
                                    widget.album.year.toString(),
                                  if (widget.album.songCount != null)
                                    '${widget.album.songCount} songs',
                                ].where((s) => s.isNotEmpty).join(' • '),
                                style: const TextStyle(
                                    color: AppTheme.subtle, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _songs?.isNotEmpty == true ? () => _playSong(0) : null,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Play'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.onBackground,
                              side: const BorderSide(color: AppTheme.divider),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: _songs?.isNotEmpty == true
                                ? () {
                                    final songs = List<Song>.from(_songs!)
                                      ..shuffle();
                                    context
                                        .read<PlayerProvider>()
                                        .playQueue(songs, 0, api);
                                  }
                                : null,
                            icon: const Icon(Icons.shuffle_rounded),
                            label: const Text('Shuffle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child:
                            CircularProgressIndicator(color: AppTheme.accent),
                      ),
                    ),
                  )
                else if (_songs != null)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final song = _songs![i];
                        final isPlaying = player.currentSong?.id == song.id;
                        final isDownloaded = downloads.isDownloaded(song.id);
                        final isDownloading = downloads.isDownloading(song.id);
                        return SongTile(
                          song: song,
                          showImage: false,
                          trackNumber: song.trackNumber ?? i + 1,
                          isPlaying: isPlaying,
                          isDownloaded: isDownloaded,
                          isDownloading: isDownloading,
                          downloadProgress: downloads.getProgress(song.id),
                          onTap: () => _playSong(i),
                          onDownload: isDownloaded || isDownloading
                              ? null
                              : () => downloads.download(song, api),
                          onRemoveDownload: isDownloaded
                              ? () => downloads.remove(song.id)
                              : null,
                        );
                      },
                      childCount: _songs!.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          if (hasSong) const MiniPlayer(),
        ],
      ),
    );
  }
}
