import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  Timer? _timer;
  String? _serverBaseUrl;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  ConnectivityService() {
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  void setServerUrl(String baseUrl) {
    _serverBaseUrl = baseUrl;
    _check();
  }

  Future<void> _check() async {
    final online = await _canReachServer();
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  Future<bool> _canReachServer() async {
    if (_serverBaseUrl == null) return true;
    try {
      final uri = Uri.parse('$_serverBaseUrl/System/Info/Public');
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 5));
      await response.drain();
      client.close();
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<void> recheck() => _check();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
