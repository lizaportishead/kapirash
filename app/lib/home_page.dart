import 'package:flutter/material.dart';

import 'feed_page.dart';
import 'icons.dart';
import 'learn_page.dart';
import 'liked_page.dart';
import 'recommend.dart';
import 'search_page.dart';
import 'stories_page.dart';
import 'store.dart';
import 'survey_page.dart';
import 'theme.dart';
import 'videos.dart';

/// Главная: ролики, шортсы и рассказы под ответы анкеты, плюс короткая тренировка слов.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onVideos, required this.onStories, required this.onWords});

  /// Переходы на вкладки таббара.
  final VoidCallback onVideos, onStories, onWords;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: store, builder: (context, _) => _page(context));
  }

  Widget _page(BuildContext context) {
    final level = store.level, interests = store.interests;
    final forYou = recommendVideos(videos, level: level, interests: interests);
    final shorts = recommendVideos(clips, level: level, interests: interests, limit: 6);
    final books = recommendStories(stories, level: level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        text: 'Kapiraš',
                        children: [
                          TextSpan(
                            text: '?',
                            style: TextStyle(color: cAccent),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.9, color: cViolet),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Любимое',
                icon: Icon(KIcons.heart, size: 24, color: cText),
                onPressed: () => openLiked(context),
              ),
              IconButton(
                tooltip: 'Поиск',
                icon: Icon(KIcons.search, size: 24, color: cText),
                onPressed: () => openSearch(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: 16),
            children: [
              _Profile(level: level, interests: interests),
              ClipsStrip(title: 'Шортсы для тебя', list: shorts),
              VideoSection(title: 'Ролики для тебя', list: forYou, onAll: onVideos),
              _Books(books, onAll: onStories),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _TrainWords(onWords: onWords),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Строка «Подобрано для…» с переходом к анкете. Если анкету пропустили — приглашение её пройти.
class _Profile extends StatelessWidget {
  const _Profile({required this.level, required this.interests});
  final String? level;
  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    final text = level == null
        ? 'Ответь на два вопроса — подберём ролики под твой уровень и темы.'
        : 'Подобрано для уровня ${levelLabel(level!)}${interests.isEmpty ? '' : ' · ${interests.take(3).join(', ')}${interests.length > 3 ? ' и ещё ${interests.length - 3}' : ''}'}';
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 20),
      child: Material(
        color: cCard,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openSurvey(context),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(text, style: TextStyle(fontSize: 14, height: 1.35, color: cMuted)),
                ),
                SizedBox(width: 4),
                Text(
                  level == null ? 'Пройти' : 'Изменить',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cViolet),
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Полоса рассказов подходящего уровня: обложка и название.
class _Books extends StatelessWidget {
  const _Books(this.list, {required this.onAll});
  final List<Story> list;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader('Книги для тебя', onAll: onAll, allLabel: 'Все'),
          SizedBox(
            height: 212,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(width: 12),
              itemBuilder: (_, i) => _BookCard(list[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard(this.story);
  final Story story;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openStory(context, story),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 140,
                height: 140,
                child: ExcludeSemantics(
                  child: Image.asset(
                    'assets/${story.asset}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: cCard2,
                      child: Icon(KIcons.stories, size: 36, color: cFaint),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              store.conv(story.title),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2, color: cText),
            ),
            SizedBox(height: 2),
            if (story.level.isNotEmpty) DifficultyLabel(story.level, size: 12),
          ],
        ),
      ),
    );
  }
}

/// Компактный блок тренировки: ряд карточек со словами (нажми — увидишь перевод) и переходы к словам.
class _TrainWords extends StatefulWidget {
  const _TrainWords({required this.onWords});
  final VoidCallback onWords;

  @override
  State<_TrainWords> createState() => _TrainWordsState();
}

class _TrainWordsState extends State<_TrainWords> {
  static const _shown = 8;
  // Переставляем при каждом «Другие слова»; ключи, а не объекты — слова могут удалить, пока экран открыт.
  late List<String> _order = _shuffled();
  final _flipped = <String>{};

  List<String> _shuffled() => ([...store.words]..shuffle()).map((w) => w.key).toList();

  void _reshuffle() => setState(() {
    _order = _shuffled();
    _flipped.clear();
  });

  @override
  Widget build(BuildContext context) {
    final words = store.words;
    // Пока нет ни одного сохранённого слова, тренировать нечего — блок не показываем.
    if (words.isEmpty) return SizedBox.shrink();
    final byKey = {for (final w in words) w.key: w};
    // Новые слова ставим в конец очереди, удалённые пропускаем.
    final list = [
      for (final k in _order)
        if (byKey.containsKey(k)) byKey[k]!,
      for (final w in words)
        if (!_order.contains(w.key)) w,
    ].take(_shown).toList();
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Тренируй слова',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: cText),
                  ),
                ),
                if (words.length > 1)
                  IconButton(
                    tooltip: 'Другие слова',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(KIcons.refresh, size: 20, color: cMuted),
                    onPressed: _reshuffle,
                  ),
              ],
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(width: 10),
              itemBuilder: (_, i) => _WordCard(
                list[i],
                flipped: _flipped.contains(list[i].key),
                onTap: () => setState(() {
                  final k = list[i].key;
                  _flipped.contains(k) ? _flipped.remove(k) : _flipped.add(k);
                }),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: BigButton('Тренировать', onTap: () => openLearn(context)),
          ),
          SizedBox(height: 4),
          TextButton(
            onPressed: widget.onWords,
            style: TextButton.styleFrom(foregroundColor: cViolet),
            child: Text('Мои слова · ${words.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard(this.w, {required this.flipped, required this.onTap});
  final SavedWord w;
  final bool flipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: flipped ? 'Перевод: ${w.tr}' : 'Слово ${store.conv(w.key)}, нажми, чтобы увидеть перевод',
      child: Material(
        color: flipped ? cAccent : cBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: flipped ? cAccent : cLine, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            width: 128,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  flipped ? (w.tr.isEmpty ? '—' : w.tr) : store.conv(w.key),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: flipped ? cInk : cText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
