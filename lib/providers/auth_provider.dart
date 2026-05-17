import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jellyfin_models.dart';
import '../services/connectivity_service.dart';
import '../services/jellyfin_api.dart';

class AuthProvider extends ChangeNotifier {
  JellyfinServer? _server;
  JellyfinApi? _api;
  bool _initialized = false;
  ConnectivityService? _connectivity;

  JellyfinServer? get server => _server;
  JellyfinApi? get api => _api;
  bool get isLoggedIn => _server != null;
  bool get initialized => _initialized;

  void attachConnectivity(ConnectivityService c) {
    _connectivity = c;
    if (_server != null) _connectivity!.setServerUrl(_server!.baseUrl);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('server');
    if (raw != null) {
      try {
        _server = JellyfinServer.fromJson(jsonDecode(raw));
        _api = JellyfinApi(
          baseUrl: _server!.baseUrl,
          userId: _server!.userId,
          token: _server!.token,
        );
        _connectivity?.setServerUrl(_server!.baseUrl);
      } catch (_) {
        await prefs.remove('server');
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String baseUrl, String username, String password) async {
    final trimmed = baseUrl.trimRight().replaceAll(RegExp(r'/+$'), '');
    final server = await JellyfinApi.authenticate(trimmed, username, password);
    _server = server;
    _api = JellyfinApi(
      baseUrl: server.baseUrl,
      userId: server.userId,
      token: server.token,
    );
    _connectivity?.setServerUrl(server.baseUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server', jsonEncode(server.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _server = null;
    _api = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server');
    notifyListeners();
  }
}
