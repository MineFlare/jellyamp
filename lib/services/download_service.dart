import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/jellyfin_models.dart';
import '../services/db_service.dart';
import '../services/jellyfin_api.dart';

class DownloadService extends ChangeNotifier {
  final DbService _db;
  final Map<String, double> _progress = {};
  final Set<String> _downloading = {};
  List<Song> _downloads = [];

  DownloadService(this._db);

  List<Song> get downloads => _downloads;
  Map<String, double> get progress => _progress;

  Future<void> init() async {
    _downloads = await _db.getDownloads();
    notifyListeners();
  }

  bool isDownloaded(String songId) => _downloads.any((s) => s.id == songId);
  bool isDownloading(String songId) => _downloading.contains(songId);
  double getProgress(String songId) => _progress[songId] ?? 0;

  Future<String> _downloadsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(dir.path, 'jellyamp_downloads'));
    await downloadDir.create(recursive: true);
    return downloadDir.path;
  }

  Future<void> download(Song song, JellyfinApi api) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) return;

    _downloading.add(song.id);
    _progress[song.id] = 0;
    notifyListeners();

    try {
      final dir = await _downloadsDir();
      final filePath = p.join(dir, '${song.id}.audio');

      await Dio().download(
        api.getStreamUrl(song.id),
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _progress[song.id] = received / total;
            notifyListeners();
          }
        },
      );

      song.localPath = filePath;
      song.isDownloaded = true;
      await _db.insertDownload(song);
      _downloads.add(song);
    } finally {
      _downloading.remove(song.id);
      _progress.remove(song.id);
      notifyListeners();
    }
  }

  Future<void> remove(String songId) async {
    final song = _downloads.firstWhere((s) => s.id == songId);
    if (song.localPath != null) {
      final file = File(song.localPath!);
      if (await file.exists()) await file.delete();
    }
    await _db.deleteDownload(songId);
    _downloads.removeWhere((s) => s.id == songId);
    notifyListeners();
  }

  Song? getDownloaded(String songId) {
    try {
      return _downloads.firstWhere((s) => s.id == songId);
    } catch (_) {
      return null;
    }
  }
}
