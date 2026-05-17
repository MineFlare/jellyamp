import 'package:flutter/foundation.dart';
import '../models/jellyfin_models.dart';
import '../services/jellyfin_api.dart';

class LibraryProvider extends ChangeNotifier {
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Playlist> _playlists = [];
  List<Album> _recentAlbums = [];
  List<Song> _recentlyPlayed = [];

  List<Song> _songSearchResults = [];
  List<Album> _albumSearchResults = [];
  String _lastQuery = '';

  bool _loadingLibrary = false;
  bool _loadingSearch = false;
  bool _loaded = false;

  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<Playlist> get playlists => _playlists;
  List<Album> get recentAlbums => _recentAlbums;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<Song> get songSearchResults => _songSearchResults;
  List<Album> get albumSearchResults => _albumSearchResults;
  bool get loadingLibrary => _loadingLibrary;
  bool get loadingSearch => _loadingSearch;
  bool get loaded => _loaded;

  Future<void> loadLibrary(JellyfinApi api, {bool force = false}) async {
    if (_loadingLibrary) return;
    if (_loaded && !force) return;
    _loadingLibrary = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.getAlbums(),
        api.getArtists(),
        api.getPlaylists(),
        api.getRecentAlbums(),
        api.getRecentlyPlayed(),
      ]);
      _albums = results[0] as List<Album>;
      _artists = results[1] as List<Artist>;
      _playlists = results[2] as List<Playlist>;
      _recentAlbums = results[3] as List<Album>;
      _recentlyPlayed = results[4] as List<Song>;
      _loaded = true;
    } catch (_) {
      rethrow;
    } finally {
      _loadingLibrary = false;
      notifyListeners();
    }
  }

  Future<void> refreshLibrary(JellyfinApi api) => loadLibrary(api, force: true);

  Future<void> searchOnline(JellyfinApi api, String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;
    if (query.isEmpty) {
      _songSearchResults = [];
      _albumSearchResults = [];
      notifyListeners();
      return;
    }
    _loadingSearch = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.searchSongs(query),
        api.searchAlbums(query),
      ]);
      _songSearchResults = results[0] as List<Song>;
      _albumSearchResults = results[1] as List<Album>;
    } finally {
      _loadingSearch = false;
      notifyListeners();
    }
  }

  void searchOffline(List<Song> downloads, String query) {
    if (query == _lastQuery) return;
    _lastQuery = query;
    if (query.isEmpty) {
      _songSearchResults = [];
      _albumSearchResults = [];
      notifyListeners();
      return;
    }
    final q = query.toLowerCase();
    _songSearchResults = downloads.where((s) {
      return s.name.toLowerCase().contains(q) ||
          (s.artistName?.toLowerCase().contains(q) ?? false) ||
          (s.albumName?.toLowerCase().contains(q) ?? false);
    }).toList();
    _albumSearchResults = [];
    notifyListeners();
  }

  void clearSearch() {
    _lastQuery = '';
    _songSearchResults = [];
    _albumSearchResults = [];
    notifyListeners();
  }

  void reset() {
    _albums = [];
    _artists = [];
    _playlists = [];
    _recentAlbums = [];
    _recentlyPlayed = [];
    _loaded = false;
    _lastQuery = '';
    _songSearchResults = [];
    _albumSearchResults = [];
    notifyListeners();
  }

  Future<List<Song>> getAlbumSongs(JellyfinApi api, String albumId) =>
      api.getAlbumSongs(albumId);

  Future<List<Song>> getPlaylistSongs(JellyfinApi api, String playlistId) =>
      api.getPlaylistSongs(playlistId);

  Future<List<Album>> getArtistAlbums(JellyfinApi api, String artistId) =>
      api.getArtistAlbums(artistId);
}
