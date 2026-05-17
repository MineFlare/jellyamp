import 'dart:async';
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
import 'downloads_tab.dart';

class SearchTab extends StatefulWidget {
  final VoidCallback? onGoToDownloads;
  const SearchTab({super.key, this.onGoToDownloads});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final isOffline = context.read<ConnectivityService>().isOffline;
      final lib = context.read<LibraryProvider>();
      if (isOffline) {
        final downloads = context.read<DownloadService>().downloads;
        lib.searchOffline(downloads, query);
      } else {
        final api = context.read<AuthProvider>().api;
        if (api != null) lib.searchOnline(api, query);
      }
    });
  }

  void _clear() {
    _ctrl.clear();
    context.read<LibraryProvider>().clearSearch();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final api = context.read<AuthProvider>().api;
    final isOffline = context.watch<ConnectivityService>().isOffline;
    final downloads = context.watch<DownloadService>();
    final player = context.read<PlayerProvider>();

    final hasResults =
        lib.songSearchResults.isNotEmpty || lib.albumSearchResults.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            if (isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Offline',
                    style: TextStyle(color: AppTheme.subtle, fontSize: 11)),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              onChanged: _onChanged,
              style: const TextStyle(color: AppTheme.onBackground),
              decoration: InputDecoration(
                hintText: isOffline
                    ? 'Search your downloads…'
                    : 'Songs, albums, artists…',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.subtle),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.subtle),
                        onPressed: _clear,
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: lib.loadingSearch
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : !hasResults && _ctrl.text.isEmpty
                    ? _buildEmptyPrompt(context, isOffline, downloads)
                    : !hasResults
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 48, color: AppTheme.subtle),
                                const SizedBox(height: 12),
                                Text(
                                  isOffline
                                      ? 'Not found in your downloads'
                                      : 'No results found',
                                  style: const TextStyle(color: AppTheme.subtle),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 120),
                            children: [
                              if (lib.songSearchResults.isNotEmpty) ...[
                                _sectionHeader(context, isOffline ? 'Downloads' : 'Songs'),
                                ...lib.songSearchResults.map((song) {
                                  final isDl = downloads.isDownloaded(song.id);
                                  return SongTile(
                                    song: song,
                                    imageUrl: isOffline
                                        ? (api?.getImageUrl(
                                            song.albumId ?? song.id, maxWidth: 80))
                                        : api?.getImageUrl(
                                            song.albumId ?? song.id, maxWidth: 80),
                                    isPlaying: context
                                            .watch<PlayerProvider>()
                                            .currentSong
                                            ?.id ==
                                        song.id,
                                    isDownloaded: isDl,
                                    onTap: () {
                                      if (isOffline) {
                                        player.playQueue(
                                            downloads.downloads,
                                            downloads.downloads.indexWhere(
                                                (s) => s.id == song.id),
                                            api!);
                                      } else {
                                        player.playQueue(
                                            lib.songSearchResults,
                                            lib.songSearchResults.indexWhere(
                                                (s) => s.id == song.id),
                                            api!);
                                      }
                                    },
                                    onDownload: (!isDl && !isOffline && api != null)
                                        ? () => downloads.download(song, api)
                                        : null,
                                  );
                                }),
                              ],
                              if (lib.albumSearchResults.isNotEmpty) ...[
                                _sectionHeader(context, 'Albums'),
                                SizedBox(
                                  height: 210,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: lib.albumSearchResults.length,
                                    itemBuilder: (context, i) {
                                      final album = lib.albumSearchResults[i];
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
                                                    builder: (_) =>
                                                        AlbumScreen(album: album))),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt(
      BuildContext context, bool isOffline, DownloadService downloads) {
    if (isOffline) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.subtle),
            const SizedBox(height: 12),
            const Text('Offline mode',
                style: TextStyle(
                    color: AppTheme.onBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${downloads.downloads.length} song${downloads.downloads.length == 1 ? '' : 's'} available',
              style: const TextStyle(color: AppTheme.subtle),
            ),
            const SizedBox(height: 6),
            const Text('Search your downloaded songs above',
                style: TextStyle(color: AppTheme.subtle, fontSize: 13)),
            if (downloads.downloads.isNotEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onGoToDownloads,
                icon: const Icon(Icons.download_for_offline_rounded),
                label: const Text('Browse Downloads'),
              ),
            ],
          ],
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 64, color: AppTheme.subtle),
          SizedBox(height: 16),
          Text('Find songs and albums',
              style: TextStyle(color: AppTheme.onBackground, fontSize: 18)),
          SizedBox(height: 6),
          Text('Search your Jellyfin library',
              style: TextStyle(color: AppTheme.subtle)),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
