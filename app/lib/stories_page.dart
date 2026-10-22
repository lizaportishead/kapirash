import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'icons.dart';
import 'phrase.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'l10n.dart';

/// Рассказ в читалке. [asset] — имя файлов в assets без расширения; у рассказов-заглушек его нет.
class Story {
  const Story({required this.id, required this.title, required this.author, this.blurb = '', this.level = '', this.asset});
  final String id, title, author, blurb, level;
  final String? asset;

  bool get ready => asset != null;

  // Слова из рассказа в «Моих словах» помнят его по этому id.
  String get wordKey => 'story:$id';
}

const stories = [
  Story(
    id: 'crvene-cipele',
    title: 'Crvene cipele',
    author: 'Hans Kristijan Andersen',
    blurb:
        'Priča za decu H. K. Andersena o devojčici Karin koja je silno htela crvene cipele, '
        'a kad ih je dobila više nije mogla da ih skine već je morala u njima zauvek da pleše.',
    level: 'B1',
    asset: 'story_crvene_cipele',
  ),
  Story(
    id: 'staklena-kula',
    title: 'Staklena kula',
    author: 'Autor nepoznat',
    blurb:
        'Priča o devojci Ilzi koja je da bi spasla bolesnog oca otišla u staklenu kulu veštice Prelje, '
        'gde se prede ljudske sudbine, i čistom pesmom razbila njenu čaroliju.',
    level: 'B1',
    asset: 'story_staklena_kula',
  ),
  Story(
    id: 'ogledalo-bez-odsjaja',
    title: 'Ogledalo bez odsjaja',
    author: 'Autor nepoznat',
    blurb:
        'Psihološki detektiv: inspektor Marko istražuje nestanak slikarke Sofije iz zaključane vile '
        'i pod ultraljubičastim svetlom otkriva istinu o njenom mužu.',
    level: 'B2',
    asset: 'story_ogledalo_bez_odsjaja',
  ),
  Story(
    id: 'tkacica-zaboravljenih-snova',
    title: 'Tkačica zaboravljenih snova',
    author: 'Autor nepoznat',
    blurb:
        'Priča o mladiću Radovanu koji je otišao u pećinu tkačice Morane da zaboravi bol za izgubljenim bratom, '
        'ali je shvatio da je bol cena ljubavi.',
    level: 'B1',
    asset: 'story_tkacica_zaboravljenih_snova',
  ),
  Story(
    id: 'poslednje-eho',
    title: 'Poslednje eho sa planete Aeron',
    author: 'Autor nepoznat',
    blurb:
        'Naučnofantastična priča o ksenoarheologu Viktoru Lazareviću koji na izumrloj planeti Aeron '
        'pronalazi oca zarobljenog u kristalu sećanja i mora da odluči da li da ga vrati kući.',
    level: 'B2',
    asset: 'story_poslednje_eho',
  ),
  Story(id: 'mala-sirena', title: 'Mala sirena', author: 'Hans Kristijan Andersen'),
  Story(id: 'ruzno-pace', title: 'Ružno pače', author: 'Hans Kristijan Andersen'),
  Story(
    id: 'snezna-kraljica',
    title: 'Snežna kraljica',
    author: 'Hans Kristijan Andersen',
    blurb:
        'Bajka H. K. Andersena u sedam priča: komadić đavoljeg ogledala zalazi dečaku Kaju u oko i srce, '
        'Snežna kraljica ga odvodi u svoje ledeno carstvo, a mala Gerda kreće da ga potraži. '
        'Za sada je dostupan samo početak bajke, ostatak stiže uskoro.',
    level: 'B2',
    asset: 'story_snezna_kraljica',
  ),
  Story(id: 'palcica', title: 'Palčica', author: 'Hans Kristijan Andersen'),
];

Story? storyById(String wordKey) {
  for (final s in stories) {
    if (s.wordKey == wordKey) return s;
  }
  return null;
}

/// Открывает читалку поверх таббара; [page] — страница, на которой слово было сохранено.
void openStory(BuildContext context, Story s, {int? page}) {
  if (!s.ready) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => StoryReader(story: s, page: page)),
  );
}

class StoriesPage extends StatelessWidget {
  const StoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(ui('Рассказы')),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: stories.length,
            separatorBuilder: (_, _) => SizedBox(height: 12),
            itemBuilder: (_, i) => _StoryCard(stories[i]),
          ),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard(this.story);
  final Story story;

  @override
  Widget build(BuildContext context) {
    final ready = story.ready;
    final body = Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 112,
              height: 112,
              child: ready
                  ? ExcludeSemantics(
                      child: Image.asset(
                        'assets/${story.asset}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            ColoredBox(color: cCard2, child: Icon(KIcons.stories, size: 36, color: cFaint)),
                      ),
                    )
                  : ColoredBox(
                      color: cCard2,
                      child: Icon(KIcons.stories, size: 36, color: cFaint),
                    ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2),
                Text(
                  store.conv(story.title),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2, color: cText),
                ),
                SizedBox(height: 4),
                Text(story.author, style: TextStyle(fontSize: 13, color: cMuted)),
                if (ready && story.level.isNotEmpty)
                  Padding(padding: EdgeInsets.only(top: 4), child: DifficultyLabel(story.level)),
                SizedBox(height: 8),
                if (ready)
                  Text(
                    store.conv(story.blurb),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, height: 1.4, color: cMuted),
                  )
                else
                  Text(ui('Скоро'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cFaint)),
              ],
            ),
          ),
        ],
      ),
    );
    if (!ready) {
      // Заглушка: не нажимается и приглушена.
      return Semantics(
        label: ui('{0}, скоро', [story.title]),
        child: ExcludeSemantics(
          child: Opacity(
            opacity: 0.55,
            child: Material(color: cCard, borderRadius: BorderRadius.circular(24), child: body),
          ),
        ),
      );
    }
    return Material(
      color: cCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => openStory(context, story),
        child: body,
      ),
    );
  }
}

/// Одно слово текста и предложение, в котором оно стоит, — его покажем в карточке слова.
class _Token {
  const _Token(this.word, this.sentence);
  final String word, sentence;
}

class StoryReader extends StatefulWidget {
  const StoryReader({super.key, required this.story, this.page});
  final Story story;
  // null — продолжить с места, где остановились.
  final int? page;

  @override
  State<StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<StoryReader> {
  // Страницы текста: на каждой несколько абзацев, а каждый абзац — список слов с предложениями.
  List<List<List<_Token>>> _pages = [];
  Map<String, dynamic> _dict = {};
  late final PageController _ctl;
  late int _i = widget.page ?? store.positionOf(widget.story.wordKey)?.toInt() ?? 0;
  bool _failed = false;

  // Страница 0 — обложка, дальше текст.
  int get _count => _pages.length + 1;

  @override
  void initState() {
    super.initState();
    _ctl = PageController(initialPage: _i);
    _load();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final asset = widget.story.asset!;
      final text = await rootBundle.loadString('assets/$asset.txt');
      final dict = jsonDecode(await store.assetText('$asset.dict.json', en: '$asset.dict.en.json')) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _pages = _paginate(text);
        _dict = dict;
        _i = _i.clamp(0, _pages.length);
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  // Абзацы набираем на страницу, пока не наберётся около 550 знаков.
  static List<List<List<_Token>>> _paginate(String text) {
    final pages = <List<List<_Token>>>[];
    var page = <List<_Token>>[];
    var size = 0;
    for (final p in text.split(RegExp(r'\n\s*\n'))) {
      final para = p.trim();
      if (para.isEmpty) continue;
      if (page.isNotEmpty && size + para.length > 560) {
        pages.add(page);
        page = [];
        size = 0;
      }
      page.add([
        for (final s in para.split(RegExp(r'(?<=[.!?])\s+')))
          for (final w in s.split(' ')) _Token(w, s),
      ]);
      size += para.length;
    }
    if (page.isNotEmpty) pages.add(page);
    return pages;
  }

  void _go(int d) {
    final to = (_i + d).clamp(0, _count - 1);
    if (to == _i) return;
    _ctl.animateToPage(to, duration: Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  // Слова из этого рассказа; нажатие переносит на страницу, где слово было сохранено.
  void _showWords() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      builder: (ctx) => ListenableBuilder(
        listenable: store,
        builder: (ctx, _) {
          final list = store.words.where((w) => w.video == widget.story.wordKey).toList().reversed.toList();
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
              child: list.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        ui('Пока нет слов. Нажми на слово в тексте, чтобы добавить его.'),
                        style: TextStyle(fontSize: 14, color: cMuted),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      children: [
                        for (final w in list)
                          ListTile(
                            title: Text(
                              store.conv(w.key),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cText),
                            ),
                            subtitle: Text(w.tr, style: TextStyle(fontSize: 14, color: cMuted)),
                            trailing: Text(ui('стр. {0}', [w.t.toInt()]), style: TextStyle(fontSize: 12, color: cFaint)),
                            onTap: () {
                              Navigator.pop(ctx);
                              final to = w.t.toInt().clamp(0, _count - 1);
                              if (_ctl.hasClients) _ctl.jumpToPage(to);
                            },
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  void _openWord(_Token t) {
    // Тире и прочие значки без букв не слова.
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(t.word)) return;
    showWord(
      context,
      raw: t.word,
      cue: Cue(_i.toDouble(), _i.toDouble(), t.sentence),
      dict: _dict,
      videoId: widget.story.wordKey,
      place: ui('стр. {0}', [_i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 12, right: 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: ui('Назад'),
                        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          store.conv(s.title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cText),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: store,
                        builder: (context, _) {
                          final n = store.wordCount(s.wordKey);
                          return IconButton(
                            tooltip: ui('Добавленные слова'),
                            icon: Badge(
                              isLabelVisible: n > 0,
                              label: Text('$n'),
                              backgroundColor: cViolet,
                              child: Icon(Icons.bookmark_border_rounded, size: 24, color: cText),
                            ),
                            onPressed: _showWords,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _failed
                      ? Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(ui('Не удалось открыть рассказ.'), style: TextStyle(fontSize: 14, color: cMuted)),
                        )
                      : _pages.isEmpty
                      ? SizedBox.shrink()
                      : ListenableBuilder(
                          // Слова, сохранённые прямо сейчас, подчёркиваются сразу.
                          listenable: store,
                          builder: (context, _) => PageView.builder(
                            controller: _ctl,
                            itemCount: _count,
                            onPageChanged: (i) {
                              setState(() => _i = i);
                              store.setPosition(widget.story.wordKey, i == 0 ? null : i.toDouble());
                            },
                            itemBuilder: (_, i) => i == 0 ? _cover() : _text(_pages[i - 1]),
                          ),
                        ),
                ),
                if (_pages.isNotEmpty) _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    final s = widget.story;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ExcludeSemantics(
              // Обложки бывают и горизонтальными, и вертикальными — показываем целиком.
              child: Image.asset('assets/${s.asset}.png', width: double.infinity, fit: BoxFit.fitWidth),
            ),
          ),
          SizedBox(height: 20),
          Text(
            store.conv(s.title),
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: cText),
          ),
          SizedBox(height: 4),
          Text(s.author, style: TextStyle(fontSize: 14, color: cMuted)),
          if (s.level.isNotEmpty) Padding(padding: EdgeInsets.only(top: 6), child: DifficultyLabel(s.level, size: 14)),
          SizedBox(height: 14),
          Text(store.conv(s.blurb), style: TextStyle(fontSize: 16, height: 1.5, color: cText)),
          SizedBox(height: 14),
          Text(
            ui('Нажимай на слова, чтобы увидеть перевод. Листай вправо — рассказ начнётся.'),
            style: TextStyle(fontSize: 13, height: 1.45, color: cFaint),
          ),
        ],
      ),
    );
  }

  Widget _text(List<List<_Token>> paragraphs) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final para in paragraphs)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 6,
                children: [for (final t in para) _word(t)],
              ),
            ),
        ],
      ),
    );
  }

  Widget _word(_Token t) {
    final key = toLat(cleanWord(t.word)).toLowerCase();
    final saved = key.isNotEmpty && store.isSaved(key);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openWord(t),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Text(
          store.conv(t.word),
          style: TextStyle(
            fontSize: 19,
            height: 1.5,
            color: cText,
            // Сохранённые слова подчёркнуты фиолетовым, как в субтитрах.
            decoration: saved ? TextDecoration.underline : null,
            decorationColor: cViolet,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    Widget arrow(int d, IconData icon, String label) {
      final off = d < 0 ? _i == 0 : _i == _count - 1;
      return Opacity(
        opacity: off ? 0.35 : 1,
        child: Pill('', icon: icon, label: label, onTap: () => _go(d)),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          arrow(-1, KIcons.arrowLeft, ui('Предыдущая страница')),
          Expanded(
            child: Center(
              child: Text(
                _i == 0 ? ui('Начало') : '$_i из ${_count - 1}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cFaint),
              ),
            ),
          ),
          arrow(1, KIcons.arrowRight, ui('Следующая страница')),
        ],
      ),
    );
  }
}
