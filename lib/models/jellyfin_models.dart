class JellyfinServer {
  final String baseUrl;
  final String userId;
  final String token;
  final String username;

  const JellyfinServer({
    required this.baseUrl,
    required this.userId,
    required this.token,
    required this.username,
  });

  factory JellyfinServer.fromJson(Map<String, dynamic> json) => JellyfinServer(
        baseUrl: json['baseUrl'],
        userId: json['userId'],
        token: json['token'],
        username: json['username'],
      );

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'userId': userId,
        'token': token,
        'username': username,
      };
}

class Song {
  final String id;
  final String name;
  final String? albumId;
  final String? albumName;
  final String? artistName;
  final String? artistId;
  final int? durationTicks;
  final bool hasLyrics;
  final int? trackNumber;
  String? localPath;
  bool isDownloaded;

  Song({
    required this.id,
    required this.name,
    this.albumId,
    this.albumName,
    this.artistName,
    this.artistId,
    this.durationTicks,
    this.hasLyrics = false,
    this.trackNumber,
    this.localPath,
    this.isDownloaded = false,
  });

  Duration get duration => Duration(microseconds: (durationTicks ?? 0) ~/ 10);

  factory Song.fromJson(Map<String, dynamic> json) {
    final artistItems = json['ArtistItems'] as List?;
    final artists = json['Artists'] as List?;
    return Song(
      id: json['Id'],
      name: json['Name'] ?? 'Unknown',
      albumId: json['AlbumId'],
      albumName: json['Album'],
      artistName: artistItems?.isNotEmpty == true
          ? artistItems![0]['Name']
          : (artists?.isNotEmpty == true ? artists![0] : 'Unknown Artist'),
      artistId: artistItems?.isNotEmpty == true ? artistItems![0]['Id'] : null,
      durationTicks: json['RunTimeTicks'],
      hasLyrics: (json['MediaStreams'] as List?)?.any((s) => s['Type'] == 'Lyric') ?? false,
      trackNumber: json['IndexNumber'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'albumId': albumId,
        'albumName': albumName,
        'artistName': artistName,
        'artistId': artistId,
        'durationTicks': durationTicks,
        'hasLyrics': hasLyrics ? 1 : 0,
        'trackNumber': trackNumber,
        'localPath': localPath,
      };

  factory Song.fromMap(Map<String, dynamic> map) => Song(
        id: map['id'],
        name: map['name'],
        albumId: map['albumId'],
        albumName: map['albumName'],
        artistName: map['artistName'],
        artistId: map['artistId'],
        durationTicks: map['durationTicks'],
        hasLyrics: map['hasLyrics'] == 1,
        trackNumber: map['trackNumber'],
        localPath: map['localPath'],
        isDownloaded: true,
      );
}

class Album {
  final String id;
  final String name;
  final String? artistName;
  final String? artistId;
  final int? year;
  final int? songCount;

  const Album({
    required this.id,
    required this.name,
    this.artistName,
    this.artistId,
    this.year,
    this.songCount,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    final albumArtists = json['AlbumArtists'] as List?;
    return Album(
      id: json['Id'],
      name: json['Name'] ?? 'Unknown',
      artistName: albumArtists?.isNotEmpty == true ? albumArtists![0]['Name'] : 'Unknown Artist',
      artistId: albumArtists?.isNotEmpty == true ? albumArtists![0]['Id'] : null,
      year: json['ProductionYear'],
      songCount: json['ChildCount'],
    );
  }
}

class Artist {
  final String id;
  final String name;
  final int? albumCount;

  const Artist({required this.id, required this.name, this.albumCount});

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
        id: json['Id'],
        name: json['Name'] ?? 'Unknown',
        albumCount: json['ChildCount'],
      );
}

class Playlist {
  final String id;
  final String name;
  final int? songCount;

  const Playlist({required this.id, required this.name, this.songCount});

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['Id'],
        name: json['Name'] ?? 'Unknown',
        songCount: json['ChildCount'],
      );
}

class LyricLine {
  final Duration start;
  final String text;

  const LyricLine({required this.start, required this.text});

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
        start: Duration(microseconds: ((json['Start'] ?? 0) as int) ~/ 10),
        text: json['Text'] ?? '',
      );
}

enum PlayerRepeatMode { none, all, one }
