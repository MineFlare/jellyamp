import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jellyfin_models.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../theme.dart';
import '../widgets/album_card.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import 'playlist_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final api = context.read<AuthProvider>().api;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: lib.loadingLibrary && lib.albums.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : TabBarView(
              controller: _tabs,
              children: [
                _AlbumsGrid(albums: lib.albums, api: api),
                _ArtistsList(lib: lib, api: api),
                _PlaylistsList(lib: lib, api: api),
              ],
            ),
    );
  }
}

class _AlbumsGrid extends StatelessWidget {
  final List<Album> albums;
  final dynamic api;

  const _AlbumsGrid({required this.albums, required this.api});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Center(
          child: Text('No albums found', style: TextStyle(color: AppTheme.subtle)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = (width / 180).floor().clamp(2, 6);
        final cardWidth = (width - 16 * (crossAxisCount + 1)) / crossAxisCount;
        final childAspectRatio = cardWidth / (cardWidth + 48);

        return GridView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: albums.length,
          itemBuilder: (context, i) {
            final album = albums[i];
            return AlbumCard(
              album: album,
              imageUrl: api!.getImageUrl(album.id),
              size: cardWidth,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => AlbumScreen(album: album))),
            );
          },
        );
      },
    );
  }
}

class _ArtistsList extends StatelessWidget {
  final LibraryProvider lib;
  final dynamic api;

  const _ArtistsList({required this.lib, required this.api});

  @override
  Widget build(BuildContext context) {
    if (lib.artists.isEmpty) {
      return const Center(
          child: Text('No artists found', style: TextStyle(color: AppTheme.subtle)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: lib.artists.length,
      itemBuilder: (context, i) {
        final artist = lib.artists[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.surfaceElevated,
            backgroundImage: api != null
                ? NetworkImage(api!.getImageUrl(artist.id, maxWidth: 96))
                : null,
            child: api == null
                ? const Icon(Icons.person_rounded, color: AppTheme.subtle)
                : null,
          ),
          title: Text(artist.name,
              style: const TextStyle(
                  color: AppTheme.onBackground, fontWeight: FontWeight.w500)),
          subtitle: artist.albumCount != null
              ? Text('${artist.albumCount} albums',
                  style: const TextStyle(color: AppTheme.subtle, fontSize: 12))
              : null,
          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.subtle),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => ArtistScreen(artist: artist))),
        );
      },
    );
  }
}

class _PlaylistsList extends StatelessWidget {
  final LibraryProvider lib;
  final dynamic api;

  const _PlaylistsList({required this.lib, required this.api});

  @override
  Widget build(BuildContext context) {
    if (lib.playlists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music_rounded, size: 64, color: AppTheme.subtle),
            SizedBox(height: 12),
            Text('No playlists yet',
                style: TextStyle(color: AppTheme.onBackground, fontSize: 16)),
            SizedBox(height: 4),
            Text('Create playlists in Jellyfin',
                style: TextStyle(color: AppTheme.subtle)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: lib.playlists.length,
      itemBuilder: (context, i) {
        final playlist = lib.playlists[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.queue_music_rounded, color: AppTheme.subtle),
          ),
          title: Text(playlist.name,
              style: const TextStyle(
                  color: AppTheme.onBackground, fontWeight: FontWeight.w500)),
          subtitle: playlist.songCount != null
              ? Text('${playlist.songCount} songs',
                  style: const TextStyle(color: AppTheme.subtle, fontSize: 12))
              : null,
          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.subtle),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: playlist))),
        );
      },
    );
  }
}
