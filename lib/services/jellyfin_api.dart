import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/jellyfin_models.dart';

class JellyfinApi {
  final String baseUrl;
  final String userId;
  final String token;
  late final Dio _dio;

  static const String _authBase =
      'MediaBrowser Client="JellyAmp", Device="Flutter", DeviceId="jellyamp-flutter", Version="1.0.0"';

  JellyfinApi({required this.baseUrl, required this.userId, required this.token}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {'X-Emby-Authorization': '$_authBase, Token="$token"'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  static Future<JellyfinServer> authenticate(
      String baseUrl, String username, String password) async {
    final dio = Dio();
    final response = await dio.post(
      '$baseUrl/Users/AuthenticateByName',
      data: {'Username': username, 'Pw': password},
      options: Options(headers: {'X-Emby-Authorization': _authBase}),
    );
    return JellyfinServer(
      baseUrl: baseUrl,
      userId: response.data['User']['Id'],
      token: response.data['AccessToken'],
      username: username,
    );
  }

  static Future<List<DiscoveredServer>> discoverServers() async {
    final servers = <DiscoveredServer>[];
    final seen = <String>{};

    try {
      final socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, 0,
          reuseAddress: true);
      socket.broadcastEnabled = true;

      final completer = Completer<void>();

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg != null) {
            try {
              final raw = String.fromCharCodes(dg.data).trim();
              final json = jsonDecode(raw) as Map<String, dynamic>;
              final address = json['Address'] as String?;
              final name = (json['Name'] as String?) ?? address ?? 'Jellyfin Server';
              if (address != null && seen.add(address)) {
                servers.add(DiscoveredServer(address: address, name: name));
              }
            } catch (_) {}
          }
        }
      });

      final msg = utf8.encode('who is JellyfinServer?');

      for (final broadcast in ['255.255.255.255', '192.168.1.255', '192.168.0.255', '10.0.0.255']) {
        try {
          socket.send(msg, InternetAddress(broadcast), 7359);
        } catch (_) {}
      }

      Timer(const Duration(seconds: 3), () {
        socket.close();
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;
    } catch (_) {}

    return servers;
  }

  String getStreamUrl(String itemId) =>
      '$baseUrl/Audio/$itemId/universal'
      '?UserId=$userId'
      '&DeviceId=jellyamp-flutter'
      '&MaxStreamingBitrate=140000000'
      '&Container=opus,mp3,aac,m4a,flac,wav,ogg,webma'
      '&TranscodingContainer=ts'
      '&TranscodingProtocol=hls'
      '&AudioCodec=aac'
      '&api_key=$token'
      '&StartTimeTicks=0'
      '&EnableRedirection=true'
      '&EnableRemoteMedia=false';

  String getImageUrl(String itemId, {int maxWidth = 512}) =>
      '$baseUrl/Items/$itemId/Images/Primary?maxWidth=$maxWidth&quality=90';

  Future<List<Album>> getAlbums() async {
    final items = <Album>[];
    int startIndex = 0;
    const pageSize = 500;
    while (true) {
      final r = await _dio.get('/Users/$userId/Items', queryParameters: {
        'IncludeItemTypes': 'MusicAlbum',
        'Recursive': true,
        'SortBy': 'SortName',
        'SortOrder': 'Ascending',
        'Fields': 'ChildCount,SortName',
        'Limit': pageSize,
        'StartIndex': startIndex,
      });
      final page = (r.data['Items'] as List?) ?? [];
      items.addAll(page.map((e) => Album.fromJson(e)));
      final total = r.data['TotalRecordCount'] as int? ?? 0;
      startIndex += page.length;
      if (startIndex >= total || page.isEmpty) break;
    }
    return items;
  }

  Future<List<Artist>> getArtists() async {
    final r = await _dio.get('/Artists/AlbumArtists', queryParameters: {
      'UserId': userId,
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
      'Fields': 'ChildCount',
      'Limit': 2000,
    });
    final all = (r.data['Items'] as List?) ?? [];
    final seenNames = <String>{};
    final result = <Artist>[];
    for (final e in all) {
      final artist = Artist.fromJson(e);
      final key = artist.name
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');
      if (seenNames.add(key)) {
        result.add(artist);
      }
    }
    return result;
  }

  Future<List<Playlist>> getPlaylists() async {
    final r = await _dio.get('/Users/$userId/Items', queryParameters: {
      'IncludeItemTypes': 'Playlist',
      'Recursive': true,
      'Fields': 'ChildCount',
    });
    final items = (r.data['Items'] as List?) ?? [];
    return items.map((e) => Playlist.fromJson(e)).toList();
  }

  Future<List<Album>> getRecentAlbums() async {
    final r = await _dio.get('/Users/$userId/Items/Latest', queryParameters: {
      'IncludeItemTypes': 'MusicAlbum',
      'Limit': 12,
      'Fields': 'ChildCount',
    });
    return ((r.data as List?) ?? []).map((e) => Album.fromJson(e)).toList();
  }

  Future<List<Song>> getRecentlyPlayed() async {
    final r = await _dio.get('/Users/$userId/Items', queryParameters: {
      'IncludeItemTypes': 'Audio',
      'Recursive': true,
      'SortBy': 'DatePlayed',
      'SortOrder': 'Descending',
      'IsPlayed': true,
      'Limit': 30,
      'Fields': 'MediaStreams,RunTimeTicks,ArtistItems',
    });
    return ((r.data['Items'] as List?) ?? []).map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    final r = await _dio.get('/Users/$userId/Items', queryParameters: {
      'ParentId': albumId,
      'SortBy': 'IndexNumber,SortName',
      'SortOrder': 'Ascending',
      'Fields': 'MediaStreams,RunTimeTicks,ArtistItems',
    });
    return ((r.data['Items'] as List?) ?? []).map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final r = await _dio.get('/Playlists/$playlistId/Items', queryParameters: {
      'UserId': userId,
      'Fields': 'MediaStreams,RunTimeTicks,ArtistItems',
      'MediaTypes': 'Audio',
    });
    return ((r.data['Items'] as List?) ?? []).map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Album>> getArtistAlbums(String artistId) async {
    final r = await _dio.get('/Users/$userId/Items', queryParameters: {
      'IncludeItemTypes': 'MusicAlbum',
      'Recursive': true,
      'AlbumArtistIds': artistId,
      'SortBy': 'ProductionYear,SortName',
      'SortOrder': 'Descending',
      'Fields': 'ChildCount',
    });
    return ((r.data['Items'] as List?) ?? []).map((e) => Album.fromJson(e)).toList();
  }

  Future<List<Song>> searchSongs(String query) async {
    final r = await _dio.get('/Users/$userId/Items', queryParameters: {
      'SearchTerm': query,
      'IncludeItemTypes': 'Audio',
      'Recursive': true,
      'Limit': 50,
      'Fields': 'MediaStreams,RunTimeTicks,ArtistItems',
    });
    return ((r.data['Items'] as List?) ?? []).map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Album>> searchAlbums(String query) async {
    final r = await _dio.get('/Users/$userId/Items', queryParameters: {
      'SearchTerm': query,
      'IncludeItemTypes': 'MusicAlbum',
      'Recursive': true,
      'Limit': 20,
      'Fields': 'ChildCount',
    });
    return ((r.data['Items'] as List?) ?? []).map((e) => Album.fromJson(e)).toList();
  }

  Future<List<LyricLine>> getLyrics(String itemId) async {
    try {
      final r = await _dio.get('/Audio/$itemId/Lyrics');
      final lyrics = (r.data['Lyrics'] as List?) ?? [];
      return lyrics.map((e) => LyricLine.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> reportPlaybackStart(String itemId) async {
    try {
      await _dio.post('/Sessions/Playing', data: {
        'ItemId': itemId,
        'MediaSourceId': itemId,
        'CanSeek': true,
        'PlayMethod': 'Transcode',
      });
    } catch (_) {}
  }

  Future<void> reportPlaybackProgress(String itemId, int positionTicks) async {
    try {
      await _dio.post('/Sessions/Playing/Progress', data: {
        'ItemId': itemId,
        'MediaSourceId': itemId,
        'PositionTicks': positionTicks,
      });
    } catch (_) {}
  }

  Future<void> reportPlaybackStopped(String itemId, int positionTicks) async {
    try {
      await _dio.post('/Sessions/Playing/Stopped', data: {
        'ItemId': itemId,
        'MediaSourceId': itemId,
        'PositionTicks': positionTicks,
      });
    } catch (_) {}
  }

  Future<void> createPlaylist(String name, List<String> songIds) async {
    await _dio.post('/Playlists', data: {
      'Name': name,
      'Ids': songIds.join(','),
      'UserId': userId,
      'MediaType': 'Audio',
    });
  }

  Future<void> addToPlaylist(String playlistId, List<String> songIds) async {
    await _dio.post('/Playlists/$playlistId/Items', queryParameters: {
      'Ids': songIds.join(','),
      'UserId': userId,
    });
  }

  Future<void> removeFromPlaylist(String playlistId, String entryId) async {
    await _dio.delete('/Playlists/$playlistId/Items', queryParameters: {
      'EntryIds': entryId,
    });
  }
}

class DiscoveredServer {
  final String address;
  final String name;
  const DiscoveredServer({required this.address, required this.name});
}
