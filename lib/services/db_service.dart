import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/jellyfin_models.dart';

class DbService {
  static final DbService _instance = DbService._();
  factory DbService() => _instance;
  DbService._();

  Database? _db;

  Future<void> init() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'jellyamp.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE downloads (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            albumId TEXT,
            albumName TEXT,
            artistName TEXT,
            artistId TEXT,
            durationTicks INTEGER,
            hasLyrics INTEGER DEFAULT 0,
            trackNumber INTEGER,
            localPath TEXT
          )
        ''');
      },
    );
  }

  Future<List<Song>> getDownloads() async {
    final maps = await _db!.query('downloads', orderBy: 'artistName, albumName, trackNumber');
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<void> insertDownload(Song song) async {
    await _db!.insert('downloads', song.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteDownload(String id) async {
    await _db!.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isDownloaded(String id) async {
    final result = await _db!.query('downloads', where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isNotEmpty;
  }
}
