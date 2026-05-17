import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/connectivity_service.dart';
import '../theme.dart';
import '../widgets/mini_player.dart';
import 'home_tab.dart';
import 'library_tab.dart';
import 'search_tab.dart';
import 'downloads_tab.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  static const _pages = [
    HomeTab(),
    SearchTab(),
    LibraryTab(),
    DownloadsTab(),
  ];

  void _goToDownloads() => setState(() => _index = 3);

  @override
  Widget build(BuildContext context) {
    final hasSong = context.watch<PlayerProvider>().currentSong != null;
    final isOffline = context.watch<ConnectivityService>().isOffline;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: [
            HomeTab(onGoToDownloads: _goToDownloads),
            SearchTab(onGoToDownloads: _goToDownloads),
            const LibraryTab(),
            const DownloadsTab(),
          ]),
          if (isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    color: const Color(0xFFB7410E).withOpacity(0.92),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('You\'re offline — showing downloads only',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<ConnectivityService>().recheck();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Retry', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSong) const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Library'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.download_for_offline_rounded), label: 'Downloads'),
            ],
          ),
        ],
      ),
    );
  }
}
