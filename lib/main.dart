import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'services/connectivity_service.dart';
import 'services/db_service.dart';
import 'services/download_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    JustAudioMediaKit.ensureInitialized(
      windows: Platform.isWindows,
      linux: Platform.isLinux,
      macOS: Platform.isMacOS,
    );
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'app.mineflare.jellyamp.audio',
      androidNotificationChannelName: 'JellyAmp',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: const Color(0xFF1DB954),
    );
  }

  await DbService().init();
  runApp(const JellyAmpApp());
}

class JellyAmpApp extends StatelessWidget {
  const JellyAmpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(
          create: (_) => DownloadService(DbService())..init(),
        ),
      ],
      child: MaterialApp(
        title: 'JellyAmp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _loadTriggered = false;
  bool _connectivityWired = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!_connectivityWired) {
      _connectivityWired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<AuthProvider>()
            .attachConnectivity(context.read<ConnectivityService>());
      });
    }

    if (!auth.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    if (!auth.isLoggedIn) {
      _loadTriggered = false;
      return const LoginScreen();
    }

    if (!_loadTriggered) {
      _loadTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final api = context.read<AuthProvider>().api;
        if (api != null) {
          context.read<LibraryProvider>().loadLibrary(api);
        }
      });
    }

    return const MainScaffold();
  }
}
