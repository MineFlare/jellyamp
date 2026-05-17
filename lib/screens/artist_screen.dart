import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jellyfin_models.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../theme.dart';
import '../widgets/album_card.dart';
import 'album_screen.dart';

class ArtistScreen extends StatefulWidget {
  final Artist artist;

  const ArtistScreen({super.key, required this.artist});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  List<Album>? _albums;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().api!;
    final albums =
        await context.read<LibraryProvider>().getArtistAlbums(api, widget.artist.id);
    if (mounted) setState(() { _albums = albums; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthProvider>().api!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: api.getImageUrl(widget.artist.id),
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: AppTheme.surfaceElevated),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.background],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Text(
                      widget.artist.name,
                      style: const TextStyle(
                          color: AppTheme.onBackground,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Albums',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppTheme.accent))))
          else if (_albums != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final album = _albums![i];
                    return AlbumCard(
                      album: album,
                      imageUrl: api.getImageUrl(album.id),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AlbumScreen(album: album))),
                    );
                  },
                  childCount: _albums!.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
