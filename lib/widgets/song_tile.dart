import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/jellyfin_models.dart';
import '../theme.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final String? imageUrl;
  final bool showImage;
  final bool isPlaying;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onRemoveDownload;
  final int? trackNumber;

  const SongTile({
    super.key,
    required this.song,
    this.imageUrl,
    this.showImage = true,
    this.isPlaying = false,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0,
    required this.onTap,
    this.onDownload,
    this.onRemoveDownload,
    this.trackNumber,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (showImage) ...[
              _buildLeading(),
              const SizedBox(width: 12),
            ] else if (trackNumber != null) ...[
              SizedBox(
                width: 32,
                child: Text(
                  trackNumber.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.subtle, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.name,
                    style: TextStyle(
                      color: isPlaying ? AppTheme.accent : AppTheme.onBackground,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isDownloaded)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.download_done_rounded,
                              size: 12, color: AppTheme.accent),
                        ),
                      Expanded(
                        child: Text(
                          song.artistName ?? '',
                          style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isDownloading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: downloadProgress,
                  strokeWidth: 2,
                  color: AppTheme.accent,
                ),
              )
            else
              Text(
                _formatDuration(song.duration),
                style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
              ),
            if ((onDownload != null || onRemoveDownload != null) && !isDownloading) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.subtle, size: 20),
                color: AppTheme.surfaceElevated,
                itemBuilder: (_) => [
                  if (!isDownloaded && onDownload != null)
                    const PopupMenuItem(
                        value: 'download',
                        child: Row(children: [
                          Icon(Icons.download_rounded, color: AppTheme.onBackground),
                          SizedBox(width: 12),
                          Text('Download', style: TextStyle(color: AppTheme.onBackground)),
                        ])),
                  if (isDownloaded && onRemoveDownload != null)
                    const PopupMenuItem(
                        value: 'remove',
                        child: Row(children: [
                          Icon(Icons.delete_rounded, color: Colors.redAccent),
                          SizedBox(width: 12),
                          Text('Remove download',
                              style: TextStyle(color: Colors.redAccent)),
                        ])),
                ],
                onSelected: (v) {
                  if (v == 'download') onDownload?.call();
                  if (v == 'remove') onRemoveDownload?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (imageUrl == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.music_note_rounded, color: AppTheme.subtle, size: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
            color: AppTheme.surfaceElevated,
            child: const Icon(Icons.music_note_rounded, color: AppTheme.subtle, size: 20)),
        errorWidget: (_, __, ___) => Container(
            color: AppTheme.surfaceElevated,
            child: const Icon(Icons.music_note_rounded, color: AppTheme.subtle, size: 20)),
      ),
    );
  }
}
