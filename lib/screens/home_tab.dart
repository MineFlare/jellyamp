import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/connectivity_service.dart';
import '../services/download_service.dart';
import '../theme.dart';
import '../widgets/album_card.dart';
import '../widgets/song_tile.dart';
import 'album_screen.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback? onGoToDownloads;
  const HomeTab({super.key, this.onGoToDownloads});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final auth = context.read<AuthProvider>();
    final api = auth.api;
    final isOffline = context.watch<ConnectivityService>().isOffline;
    final downloads = context.watch<DownloadService>();

    if (isOffline) {
      return _buildOfflineView(context, downloads);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('JellyAmp',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: api == null ? null : () => lib.refreshLibrary(api),
          ),
          IconButton(
            icon: const CircleAvatar(
                backgroundColor: AppTheme.surfaceElevated,
                radius: 14,
                child: Icon(Icons.person_rounded, size: 18, color: AppTheme.subtle)),
            onPressed: () => _showAccountSheet(context, auth),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: lib.loadingLibrary && lib.recentAlbums.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () => lib.refreshLibrary(api!),
              child: CustomScrollView(
                slivers: [
                  if (lib.recentAlbums.isNotEmpty) ...[
                    _sectionHeader(context, 'Recently Added'),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 210,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: lib.recentAlbums.length,
                          itemBuilder: (context, i) {
                            final album = lib.recentAlbums[i];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 160,
                                child: AlbumCard(
                                  album: album,
                                  imageUrl: api!.getImageUrl(album.id),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => AlbumScreen(album: album))),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  if (lib.recentlyPlayed.isNotEmpty) ...[
                    _sectionHeader(context, 'Recently Played'),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final song = lib.recentlyPlayed[i];
                          final player = context.read<PlayerProvider>();
                          final dl = context.read<DownloadService>();
                          return SongTile(
                            song: song,
                            imageUrl: api!.getImageUrl(song.albumId ?? song.id, maxWidth: 80),
                            isPlaying: context.watch<PlayerProvider>().currentSong?.id == song.id,
                            isDownloaded: dl.isDownloaded(song.id),
                            onTap: () => player.playQueue([song], 0, api),
                            onDownload: dl.isDownloaded(song.id)
                                ? null
                                : () => dl.download(song, api),
                          );
                        },
                        childCount: lib.recentlyPlayed.length,
                      ),
                    ),
                  ],
                  if (lib.recentAlbums.isEmpty && lib.recentlyPlayed.isEmpty && !lib.loadingLibrary)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.library_music_rounded, size: 64, color: AppTheme.subtle),
                            const SizedBox(height: 16),
                            const Text('Your library is empty',
                                style: TextStyle(color: AppTheme.onBackground, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(
                              api == null
                                  ? 'Connect to a Jellyfin server'
                                  : 'Add music to your Jellyfin server',
                              style: const TextStyle(color: AppTheme.subtle),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }

  Widget _buildOfflineView(BuildContext context, DownloadService downloads) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JellyAmp',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 72, color: AppTheme.subtle),
              const SizedBox(height: 20),
              const Text('You\'re offline',
                  style: TextStyle(
                      color: AppTheme.onBackground,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '${downloads.downloads.length} song${downloads.downloads.length == 1 ? '' : 's'} available offline',
                style: const TextStyle(color: AppTheme.subtle, fontSize: 15),
              ),
              const SizedBox(height: 32),
              if (downloads.downloads.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: onGoToDownloads,
                  icon: const Icon(Icons.download_for_offline_rounded),
                  label: const Text('Go to Downloads'),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.subtle,
                  side: const BorderSide(color: AppTheme.divider),
                  minimumSize: const Size(200, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => context.read<ConnectivityService>().recheck(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }

  void _showAccountSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connected to', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(auth.server?.username ?? '',
                style: Theme.of(context).textTheme.titleMedium),
            Text(auth.server?.baseUrl ?? '',
                style: const TextStyle(color: AppTheme.subtle, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<LibraryProvider>().reset();
                  auth.logout();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
