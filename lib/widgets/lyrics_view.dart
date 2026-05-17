import 'package:flutter/material.dart';
import '../models/jellyfin_models.dart';
import '../theme.dart';

class LyricsView extends StatefulWidget {
  final List<LyricLine> lyrics;
  final int currentIndex;
  final bool loading;

  const LyricsView({
    super.key,
    required this.lyrics,
    required this.currentIndex,
    this.loading = false,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scroll = ScrollController();
  static const double _lineHeight = 56;

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex != old.currentIndex && widget.currentIndex >= 0) {
      _scrollToCurrent();
    }
  }

  void _scrollToCurrent() {
    final offset = (widget.currentIndex * _lineHeight) - 200;
    _scroll.animateTo(
      offset.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (widget.lyrics.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lyrics_rounded, size: 48, color: AppTheme.subtle),
            SizedBox(height: 12),
            Text('No lyrics available', style: TextStyle(color: AppTheme.subtle)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      itemCount: widget.lyrics.length,
      itemBuilder: (context, index) {
        final isCurrent = index == widget.currentIndex;
        final isPast = index < widget.currentIndex;
        return SizedBox(
          height: _lineHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isCurrent
                    ? AppTheme.onBackground
                    : isPast
                        ? AppTheme.onBackground.withOpacity(0.35)
                        : AppTheme.onBackground.withOpacity(0.5),
                fontSize: isCurrent ? 20 : 17,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                height: 1.3,
              ),
              child: Text(widget.lyrics[index].text),
            ),
          ),
        );
      },
    );
  }
}
