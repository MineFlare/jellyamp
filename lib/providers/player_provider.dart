import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:smtc_windows/smtc_windows.dart';
import '../models/jellyfin_models.dart';
import '../services/jellyfin_api.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  SMTCWindows? _smtc;

  List<Song> _queue = [];
  int _currentIndex = 0;
  PlayerRepeatMode _repeatMode = PlayerRepeatMode.none;
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = -1;
  bool _lyricsLoading = false;
  String? _error;
  JellyfinApi? _api;

  AudioPlayer get player => _player;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  PlayerRepeatMode get repeatMode => _repeatMode;
  List<LyricLine> get lyrics => _lyrics;
  int get currentLyricIndex => _currentLyricIndex;
  bool get lyricsLoading => _lyricsLoading;
  String? get error => _error;

  Song? get currentSong =>
      _queue.isNotEmpty && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  PlayerProvider() {
    _initSmtc();

    _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex) {
        _currentIndex = index;
        _lyrics = [];
        _currentLyricIndex = -1;
        _error = null;
        notifyListeners();
        if (_api != null && _queue.isNotEmpty) {
          _loadLyrics(_queue[index]);
          _api!.reportPlaybackStart(_queue[index].id);
          _updateSmtcMetadata(_queue[index]);
        }
      }
    });

    _player.positionStream.listen(_updateCurrentLyric);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_repeatMode == PlayerRepeatMode.one) {
          _player.seek(Duration.zero);
          _player.play();
        }
      }
      _updateSmtcPlaybackStatus(state);
      notifyListeners();
    });

    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        _error = 'Playback error: ${e.toString()}';
        notifyListeners();
      },
    );
  }

  void _initSmtc() {
    if (kIsWeb || !Platform.isWindows) return;
    _smtc = SMTCWindows(
      config: const SMTCConfig(
        fastForwardEnabled: false,
        nextEnabled: true,
        pauseEnabled: true,
        playEnabled: true,
        rewindEnabled: false,
        prevEnabled: true,
        stopEnabled: false,
      ),
    );
    _smtc!.buttonPressStream.listen((event) {
      switch (event) {
        case PressedButton.play:
          _player.play();
        case PressedButton.pause:
          _player.pause();
        case PressedButton.next:
          _player.seekToNext();
        case PressedButton.previous:
          skipPrevious();
        default:
          break;
      }
    });
  }

  void _updateSmtcMetadata(Song song) {
    if (_smtc == null) return;
    _smtc!.updateMetadata(MusicMetadata(
      title: song.name,
      artist: song.artistName ?? '',
      albumArtist: song.artistName ?? '',
      album: song.albumName ?? '',
    ));
    _smtc!.setPlaybackStatus(PlaybackStatus.Playing);
    _smtc!.enableSmtc();
  }

  void _updateSmtcPlaybackStatus(PlayerState state) {
    if (_smtc == null) return;
    if (state.playing) {
      _smtc!.setPlaybackStatus(PlaybackStatus.Playing);
    } else {
      switch (state.processingState) {
        case ProcessingState.idle:
        case ProcessingState.completed:
          _smtc!.setPlaybackStatus(PlaybackStatus.Stopped);
        default:
          _smtc!.setPlaybackStatus(PlaybackStatus.Paused);
      }
    }
  }

  Future<void> playQueue(List<Song> songs, int startIndex, JellyfinApi api) async {
    if (songs.isEmpty) return;
    _api = api;
    _queue = songs;
    _currentIndex = startIndex;
    _lyrics = [];
    _currentLyricIndex = -1;
    _error = null;
    notifyListeners();

    try {
      final sources = songs.map((song) {
        final uri = song.isDownloaded && song.localPath != null
            ? Uri.file(song.localPath!)
            : Uri.parse(api.getStreamUrl(song.id));

        final headers = song.isDownloaded
            ? null
            : {
                'X-Emby-Authorization':
                    'MediaBrowser Client="JellyAmp", Device="Flutter", '
                    'DeviceId="jellyamp-flutter", Version="1.0.0", Token="${api.token}"',
              };

        return AudioSource.uri(uri, headers: headers);
      }).toList();

      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: startIndex,
        initialPosition: Duration.zero,
      );
      await _player.play();

      _loadLyrics(songs[startIndex]);
      _updateSmtcMetadata(songs[startIndex]);
      api.reportPlaybackStart(songs[startIndex].id);
    } catch (e) {
      _error = 'Failed to load audio: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _loadLyrics(Song song) async {
    if (_api == null) return;
    _lyricsLoading = true;
    notifyListeners();
    try {
      _lyrics = song.hasLyrics ? await _api!.getLyrics(song.id) : [];
    } catch (_) {
      _lyrics = [];
    }
    _lyricsLoading = false;
    _currentLyricIndex = -1;
    notifyListeners();
  }

  void _updateCurrentLyric(Duration position) {
    if (_lyrics.isEmpty) return;
    int newIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].start <= position) {
        newIndex = i;
      } else {
        break;
      }
    }
    if (newIndex != _currentLyricIndex) {
      _currentLyricIndex = newIndex;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async =>
      _player.playing ? await _player.pause() : await _player.play();

  Future<void> skipNext() async => _player.seekToNext();

  Future<void> skipPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> toggleShuffle() async {
    await _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
    notifyListeners();
  }

  Future<void> cycleRepeat() async {
    switch (_repeatMode) {
      case PlayerRepeatMode.none:
        _repeatMode = PlayerRepeatMode.all;
        await _player.setLoopMode(LoopMode.all);
      case PlayerRepeatMode.all:
        _repeatMode = PlayerRepeatMode.one;
        await _player.setLoopMode(LoopMode.one);
      case PlayerRepeatMode.one:
        _repeatMode = PlayerRepeatMode.none;
        await _player.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _smtc?.disableSmtc();
    _smtc?.dispose();
    _player.dispose();
    super.dispose();
  }
}
