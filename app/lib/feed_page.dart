import 'package:flutter/material.dart';

import 'liked_page.dart';
import 'search_page.dart';
import 'store.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';

const _perSection = 4;

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  // Каталог может обновиться из облака, пока экран открыт.
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) => _feed(context));

  Widget _feed(BuildContext context) {
    // Новые ролики добавляются в конец списка, поэтому «последние» — это хвост.
    final newest = videos.reversed.toList();
    final popular = (videos.toList()..sort((a, b) => b.views.compareTo(a.views))).take(_perSection).toList();
    final topics = <String>[
      for (final v in videos)
        if (v.topic.isNotEmpty) v.topic,
    ].toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          'Каталог',
          actions: [
            IconButton(
              tooltip: 'Любимое',
              icon: Icon(Icons.favorite_border_rounded, size: 24, color: cText),
              onPressed: () => openLiked(context),
            ),
            IconButton(
              tooltip: 'Поиск',
              icon: Icon(Icons.search_rounded, size: 24, color: cText),
              onPressed: () => openSearch(context),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: 16),
            children: [
              _Section(title: 'Новое', list: newest.take(_perSection).toList()),
              _Section(title: 'Популярное', list: popular),
              for (final t in topics)
                _Section(
                  title: t,
                  list: videos.where((v) => v.topic == t).toList().reversed.take(_perSection).toList(),
                  onAll: () => openTopic(context, t),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Высота карточки: превью 16:9 плюс подпись.
double _cardHeight(double w) => (w - 16) * 9 / 16 + 108;

/// Заголовок темы со ссылкой «Смотреть все» и горизонтальная полоса из последних роликов.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.list, this.onAll});
  final String title;
  final List<Video> list;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: cText),
                  ),
                ),
                if (onAll != null)
                  TextButton(
                    onPressed: onAll,
                    style: TextButton.styleFrom(foregroundColor: cViolet),
                    child: Text('Смотреть все', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (_, box) {
              // Телефон: одна карточка и краешек второй. Широкий экран: четыре в ряд.
              final w = box.maxWidth < 600
                  ? box.maxWidth * 0.82
                  : ((box.maxWidth - 24 - 12 * (_perSection - 1)) / _perSection).clamp(260.0, 400.0);
              return SizedBox(
                height: _cardHeight(w),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(width: w, child: VideoCard(list[i])),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Все ролики одной темы поверх таббара.
void openTopic(BuildContext context, String topic) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TopicPage(topic)));
}

class TopicPage extends StatelessWidget {
  const TopicPage(this.topic, {super.key});
  final String topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200),
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final list = videos.where((v) => v.topic == topic).toList().reversed.toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: IconButton(
                          tooltip: 'Назад',
                          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    PageTitle(topic),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, box) {
                          final cols = (box.maxWidth / 340).floor().clamp(1, 4);
                          final cardW = (box.maxWidth - 24 - 12 * (cols - 1)) / cols;
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: _cardHeight(cardW),
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
    );
  }
}
