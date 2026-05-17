import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import 'mini_player.dart';

class PlayerScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const PlayerScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final hasSong = context.watch<PlayerProvider>().currentSong != null;

    return Scaffold(
      appBar: appBar as PreferredSizeWidget?,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          Expanded(child: body),
          if (hasSong) const MiniPlayer(),
        ],
      ),
    );
  }
}
