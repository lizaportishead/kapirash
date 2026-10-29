import 'package:flutter/material.dart';

import 'feed_page.dart' show videoCardHeight;
import 'icons.dart';
import 'store.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';
import 'l10n.dart';

/// Открывает ролики со звёздочкой поверх таббара.
void openLiked(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'LikedPage'),
      builder: (_) => LikedPage(),
    ),
  );
}

class LikedPage extends StatelessWidget {
  const LikedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1200),
                  child: ListenableBuilder(
                    listenable: store,
                    builder: (context, _) {
                      // Сверху — отмеченные последними.
                      final list = store.liked.reversed.map(videoById).nonNulls.toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...pageHeader(context, '${ui('Избранное')}${list.isEmpty ? '' : ' · ${list.length}'}', icon: KIcons.videos),
                          Expanded(
                            child: list.isEmpty
                                ? Padding(
                                    padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Картинка декоративная: на низком экране ужимается, а не обрезает текст.
                                        Flexible(
                                          child: ExcludeSemantics(
                                            child: Image.asset('assets/ill_liked.png', height: 220),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          ui(
                                            'Ставь звёздочку роликам, которые хочешь посмотреть позже или пересмотреть. Они появятся тут.',
                                          ),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                                        ),
                                      ],
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (_, box) {
                                      // Узкий экран — лента в одну колонку, на десктопе — плитки.
                                      final cols = (box.maxWidth / 340).floor().clamp(1, 4);
                                      final cardW = (box.maxWidth - 24 - 12 * (cols - 1)) / cols;
                                      return GridView.builder(
                                        padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          mainAxisExtent: videoCardHeight(cardW),
                                        ),
                                        itemCount: list.length,
                                        itemBuilder: (_, i) => VideoCard(list[i], key: ValueKey(list[i].id)),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
