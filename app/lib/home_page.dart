import 'package:flutter/material.dart';

import 'feed_page.dart';
import 'icons.dart';
import 'main.dart' show kStoriesTabEnabled;
import 'liked_page.dart';
import 'onboarding_page.dart' show BetaBadge;
import 'podcasts_page.dart';
import 'recommend.dart';
import 'search_page.dart';
import 'stories_page.dart';
import 'store.dart';
import 'survey_page.dart';
import 'theme.dart';
import 'videos.dart';
import 'l10n.dart';

/// Главная: ролики, шортсы и рассказы под ответы анкеты, плюс подкасты.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onVideos, required this.onStories, required this.onPodcasts});

  /// Переходы на вкладки таббара.
  final VoidCallback onVideos, onStories, onPodcasts;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: store, builder: (context, _) => _page(context));
  }

  Widget _page(BuildContext context) {
    final level = store.level, interests = store.interests;
    final forYou = recommendVideos(videos, level: level, interests: interests);
    // Шортсы идут от новых к старым (clips уже в таком порядке); просмотренные — в конец, законченные скрыты.
    final fresh = [
      for (final v in clips)
        if (!store.isFinished(v.id)) v,
    ];
    final shorts = [...fresh.where((v) => !store.isWatched(v.id)), ...fresh.where((v) => store.isWatched(v.id))].take(6).toList();
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
                    child: MediaQuery.sizeOf(context).width >= 900
                        ? Text(
                            ui('Главная'),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: cText,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: brandName,
                                  children: [
                                    TextSpan(
                                      text: '?',
                                      style: TextStyle(color: cAccent),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.9,
                                  color: cViolet,
                                ),
                              ),
                              SizedBox(width: 8),
                              BetaBadge(logoSize: 26),
                            ],
                          ),
                  ),
                ),
              ),
              IconButton(
                tooltip: ui('Избранное'),
                icon: Icon(KIcons.star, size: 24, color: cText),
                onPressed: () => openLiked(context, all: true),
              ),
              IconButton(
                tooltip: ui('Поиск'),
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
              ClipsStrip(title: ui('Шортсы для тебя'), list: shorts),
              VideoSection(title: ui('Ролики для тебя'), list: forYou, onAll: onVideos),
              if (kStoriesTabEnabled) _Books(books, onAll: onStories),
              _Podcasts(onAll: onPodcasts),
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
        ? ui('Ответь на два вопроса — подберём ролики под твой уровень и темы.')
        : ui('Подобрано для уровня {0}', [levelLabel(level!)]) +
              (interests.isEmpty
                  ? ''
                  : ' · ${interests.take(3).map(topicLabel).join(', ')}${interests.length > 3 ? ui(' и ещё {0}', [interests.length - 3]) : ''}');
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 20),
      child: Material(
        color: mobile ? cCard : cViolet,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openSurvey(context),
          child: Padding(
            padding: mobile ? EdgeInsets.fromLTRB(16, 12, 8, 12) : EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                if (!mobile) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: cOnViolet.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome_rounded, size: 22, color: cOnViolet),
                  ),
                  SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(text, style: TextStyle(fontSize: 14, height: 1.35, color: mobile ? cMuted : cOnViolet)),
                ),
                SizedBox(width: mobile ? 4 : 12),
                if (mobile)
                  Text(
                    level == null ? ui('Пройти') : ui('Изменить'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cViolet),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: cOnViolet, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      level == null ? ui('Пройти') : ui('Изменить'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cViolet),
                    ),
                  ),
                if (mobile) SizedBox(width: 8),
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
          SectionHeader(ui('Книги для тебя'), onAll: onAll, allLabel: ui('Все')),
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

/// Несколько эпизодов подкастов с переходом ко всей вкладке.
class _Podcasts extends StatelessWidget {
  const _Podcasts({required this.onAll});
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    if (podcasts.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(ui('Подкасты для тебя'), onAll: onAll, allLabel: ui('Все')),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: [for (final p in podcasts.take(3)) EpisodeTile(p)]),
        ),
      ],
    );
  }
}
