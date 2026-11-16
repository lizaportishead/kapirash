import 'deep_link.dart';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import 'add_video.dart';
import 'clips_page.dart';
import 'fav_button.dart';
import 'icons.dart';
import 'request_sheet.dart';
import 'liked_page.dart';
import 'search_page.dart';
import 'store.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';
import 'l10n.dart';

/// Сколько карточек видно в ряд на широком экране.
const _perRow = 4;

/// Сколько роликов в секции: на широком экране 8 (листаются вправо), на телефоне 4.
int _perSection(BuildContext context) => MediaQuery.sizeOf(context).width < 600 ? 4 : 8;

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  // Каталог может обновиться из облака, пока экран открыт.
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) => _feed(context));

  Widget _feed(BuildContext context) {
    // Новые ролики добавляются в конец списка, поэтому «последние» — это хвост.
    final newest = videos.reversed.toList();
    final perSection = _perSection(context);
    final popular = (videos.toList()..sort((a, b) => b.views.compareTo(a.views))).take(perSection).toList();
    final topics = _topicsByViews();
    final mine = [for (final m in store.myVideos.reversed) m.video];
    final series = [
      for (final v in videos.reversed)
        if (_isSeries(v)) v,
    ];
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          ui('Видео'),
          actions: [
            FavIconButton(scope: FavScope.videos, onPressed: () => openLiked(context)),
            IconButton(
              tooltip: ui('Поиск'),
              icon: Icon(KIcons.search, size: 24, color: cText),
              onPressed: () => openSearch(context),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: 16),
            children: [
              VideoSection(title: ui('Мои ролики'), list: mine),
              VideoSection(title: ui('Популярное'), list: popular),
              VideoSection(title: ui('Новое'), list: newest.take(perSection).toList()),
              ClipsStrip(),
              VideoSection(
                title: ui('Сериалы'),
                list: series.take(perSection).toList(),
                onAll: () => openSeries(context),
              ),
              for (final t in topics)
                VideoSection(
                  title: topicLabel(t),
                  list: videos.where((v) => v.topic == t).toList().reversed.take(perSection).toList(),
                  onAll: () => openTopic(context, t),
                  ),
            ],
          ),
        ),
      ],
    );
    if (!canAddVideo && !canSendRequest) return page;
    return Stack(
      children: [
        page,
        Positioned(
          right: 16,
          bottom: 16,
          child: Semantics(
            button: true,
            label: ui('Добавить ролик'),
            child: Material(
              color: cViolet,
              shape: CircleBorder(),
              elevation: 3,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => canSendRequest ? showSendRequest(context, podcast: false) : showAddVideo(context),
                child: SizedBox(width: 56, height: 56, child: Icon(KIcons.plus, size: 28, color: cOnViolet)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Темы каталога по популярности: чем больше суммарных просмотров роликов, тем выше.
List<String> _topicsByViews() {
  final topics = <String>[
    for (final v in videos)
      if (v.topic.isNotEmpty) v.topic,
  ].toSet().toList();
  final views = {for (final t in topics) t: videos.where((v) => v.topic == t).fold(0, (a, v) => a + v.views)};
  topics.sort((a, b) => views[b]!.compareTo(views[a]!));
  return topics;
}

/// Серия сериала: в названии «Epizoda» или «Serija», либо канал «Andrija i Andjelka».
bool _isSeries(Video v) =>
    !v.podcast && !v.tiktok && (RegExp(r'epizod|serij', caseSensitive: false).hasMatch(v.title) || v.channel == 'Andrija i Andjelka');

/// Название сериала: по названию ролика или каналу.
String _seriesName(Video v) {
  if (v.title.toLowerCase().contains('mamini sinovi')) return 'Mamini Sinovi';
  return v.channel;
}

/// Ролики по сериалам, в порядке первого появления.
List<(String?, List<Video>)> _seriesGroups(List<Video> list) {
  final map = <String, List<Video>>{};
  for (final v in list) {
    (map[_seriesName(v)] ??= []).add(v);
  }
  final groups = [for (final e in map.entries) (e.key, e.value)];
  // «Andrija i Andjelka» всегда первыми; остальные — в порядке появления.
  return [
    ...groups.where((g) => g.$1 == 'Andrija i Andjelka'),
    ...groups.where((g) => g.$1 != 'Andrija i Andjelka'),
  ];
}

// Высота карточки: превью 16:9 плюс подпись.
double videoCardHeight(double w) => (w - 16) * 9 / 16 + 107;

/// Заголовок полосы со ссылкой «Смотреть все», если есть куда вести.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onAll, this.allLabel});
  final String title;
  final String? allLabel;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              child: Text(allLabel ?? ui('Смотреть все'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

/// Заголовок темы со ссылкой «Смотреть все» и горизонтальная полоса из последних роликов.
class VideoSection extends StatelessWidget {
  const VideoSection({super.key, required this.title, required this.list, this.onAll});
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
          SectionHeader(title, onAll: onAll),
          LayoutBuilder(
            builder: (_, box) {
              // Телефон: одна карточка и краешек второй. Широкий экран: четыре в ряд.
              final w = box.maxWidth < 600
                  ? box.maxWidth * 0.82
                  : ((box.maxWidth - 32 - 16 * (_perRow - 1)) / _perRow).clamp(260.0, 400.0);
              return SizedBox(
                height: videoCardHeight(w) + 16,
                child: ScrollConfiguration(
                  // На десктопе ряд можно листать и мышью.
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => SizedBox(width: 16),
                    itemBuilder: (_, i) => SizedBox(width: w, child: VideoCard(list[i])),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Полоса «Короткие ролики»: шесть вертикальных обложек, которые листаются вправо.
class ClipsStrip extends StatelessWidget {
  const ClipsStrip({super.key, this.title, this.list});
  final String? title;

  /// null — первые клипы каталога.
  final List<Video>? list;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    // На широком экране показываем столько обложек, сколько влезает в строку.
    final fit = ((box.maxWidth - 32 + 16) / 151).floor();
    final list = this.list ?? clips.take(fit < 6 ? 6 : fit).toList();
    if (list.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title ?? ui('Шортсы'), onAll: () => openClips(context)),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(width: 16),
              itemBuilder: (_, i) => SizedBox(width: 135, child: ClipTile(list[i], among: list)),
            ),
          ),
        ],
      ),
    );
  });
}

/// Все ролики одной темы поверх таббара.
void openTopic(BuildContext context, String topic, {bool replace = false}) {
  final route = MaterialPageRoute<void>(
    settings: urlSettings('TopicPage', '/topic/${topicSlug(topic)}'),
    builder: (_) => TopicPage(topic),
  );
  replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}

/// Все ролики каталога поверх таббара: адрес `/all`.
void openAllVideos(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: urlSettings('TopicPage', '/all'),
      builder: (_) => TopicPage('', all: true),
    ),
  );
}

/// Все сериалы поверх таббара: адрес `/series`.
void openSeries(BuildContext context, {bool replace = false}) {
  final route = MaterialPageRoute<void>(
    settings: urlSettings('TopicPage', '/series'),
    builder: (_) => TopicPage('', series: true),
  );
  replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}

class TopicPage extends StatelessWidget {
  const TopicPage(this.topic, {super.key, this.series = false, this.all = false});
  final String topic;
  final bool series, all;

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
                final list = videos.where((v) => all || (series ? _isSeries(v) : v.topic == topic)).toList().reversed.toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...pageHeader(context, all ? ui('Все видео') : series ? ui('Сериалы') : topicLabel(topic)),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, box) {
                          final cols = (box.maxWidth / 340).floor().clamp(1, 4);
                          final cardW = (box.maxWidth - 32 - 16 * (cols - 1)) / cols;
                          return CustomScrollView(
                            slivers: [
                              for (final g in series ? _seriesGroups(list) : [(null as String?, list)]) ...[
                                if (g.$1 != null)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                                      child: Text(
                                        g.$1!,
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: cText),
                                      ),
                                    ),
                                  ),
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  sliver: SliverGrid.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: box.maxWidth < 600 ? 8 : 16,
                                      mainAxisExtent: videoCardHeight(cardW),
                                    ),
                                    itemCount: g.$2.length,
                                    itemBuilder: (_, i) => VideoCard(g.$2[i], key: ValueKey(g.$2[i].id)),
                                  ),
                                ),
                              ],
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ui('Ролики в других категориях'),
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: cText),
                                      ),
                                      SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (!series) Pill(ui('Сериалы'), onTap: () => openSeries(context, replace: true)),
                                          for (final t in _topicsByViews())
                                            if (series || t != topic)
                                              Pill(topicLabel(t), onTap: () => openTopic(context, t, replace: true)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
