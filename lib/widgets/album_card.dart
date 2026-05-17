import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/jellyfin_models.dart';
import '../theme.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final String imageUrl;
  final VoidCallback onTap;
  final double? size;

  const AlbumCard({
    super.key,
    required this.album,
    required this.imageUrl,
    required this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.surfaceElevated,
                  child: const Center(
                    child: Icon(Icons.album_rounded, color: AppTheme.subtle, size: 48),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surfaceElevated,
                  child: const Center(
                    child: Icon(Icons.album_rounded, color: AppTheme.subtle, size: 48),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            style: const TextStyle(
              color: AppTheme.onBackground,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            album.artistName ?? '',
            style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
