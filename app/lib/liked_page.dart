import 'package:flutter/material.dart';

import 'feed_page.dart' show videoCardHeight;
import 'podcasts_page.dart' show EpisodeTile;
import 'stories_page.dart' show storyById, storyTile;
import 'store.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';
import 'words_page.dart' show wordCard;
import 'l10n.dart';

/// Открывает ролики со звёздочкой поверх таббара.
void openLiked(BuildContext context, {bool all = false}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'LikedPage'),
      builder: (_) => LikedPage(all: all),
    ),
  );
}

class LikedPage extends StatelessWidget {
  const LikedPage({super.key, this.all = false});

  /// С главной: вместе с подкастами и рассказами, а не только ролики.
  final bool all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  // Сверху — отмеченные последними.
                  final podIds = {for (final p in podcasts) p.id};
                  final all = store.liked.reversed.map(videoById).nonNulls.toList();
                  final list = [
                    for (final v in all)
                      if (!this.all || !podIds.contains(v.id)) v,
                  ];
                  final pods = this.all
                      ? [
                          for (final v in all)
                            if (podIds.contains(v.id)) v,
                        ]
                      : <Video>[];
                  final books = this.all ? store.liked.reversed.map(storyById).nonNulls.toList() : [];
                  final words = this.all ? store.words.reversed.where((w) => w.starred).toList() : <SavedWord>[];
                  final total = list.length + pods.length + books.length + words.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...pageHeader(
                        context,
                        '${ui(this.all ? 'Избранное' : 'Избранные ролики')}${total == 0 ? '' : ' · $total'}',
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 1200),
                            child: total == 0
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
                                            this.all
                                                ? 'Добавляй в избранное то, что хочешь сохранить: ролики, подкасты, рассказы. Это появится тут.'
                                                : 'Добавляй в избранное ролики, которые хочешь посмотреть позже или пересмотреть. Они появятся тут.',
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
                                      final cardW = (box.maxWidth - 32 - 16 * (cols - 1)) / cols;
                                      Widget title(String t) => Padding(
                                        padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                                        child: Text(
                                          t,
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cText),
                                        ),
                                      );
                                      Widget column(List<Widget> tiles) => Align(
                                        alignment: Alignment.topLeft,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: 720),
                                          child: Padding(
                                            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                            child: Column(
                                              children: [
                                                for (final t in tiles)
                                                  Padding(padding: EdgeInsets.only(bottom: 12), child: t),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                      return CustomScrollView(
                                        slivers: [
                                          if (list.isNotEmpty) ...[
                                            if (this.all) SliverToBoxAdapter(child: title(ui('Видео'))),
                                            SliverPadding(
                                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                              sliver: SliverGrid.builder(
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: cols,
                                                  crossAxisSpacing: 16,
                                                  mainAxisSpacing: 16,
                                                  mainAxisExtent: videoCardHeight(cardW),
                                                ),
                                                itemCount: list.length,
                                                itemBuilder: (_, i) => VideoCard(list[i], key: ValueKey(list[i].id)),
                                              ),
                                            ),
                                          ],
                                          if (pods.isNotEmpty) ...[
                                            SliverToBoxAdapter(child: title(ui('Подкасты'))),
                                            SliverToBoxAdapter(
                                              child: column([
                                                for (final v in pods) EpisodeTile(v, key: ValueKey(v.id)),
                                              ]),
                                            ),
                                          ],
                                          if (books.isNotEmpty) ...[
                                            SliverToBoxAdapter(child: title(ui('Рассказы'))),
                                            SliverToBoxAdapter(child: column([for (final s in books) storyTile(s)])),
                                          ],
                                          if (words.isNotEmpty) ...[
                                            SliverToBoxAdapter(child: title(ui('Слова'))),
                                            SliverToBoxAdapter(
                                              child: column([for (final w in words) wordCard(w)]),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
