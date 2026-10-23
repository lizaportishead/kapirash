import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'collection_page.dart';
import 'icons.dart';
import 'phrase.dart';
import 'player_page.dart' show SubPage;
import 'quiz_page.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'video_card.dart' show LikeButton;
import 'l10n.dart';

/// Рассказ в читалке. [asset] — имя файлов в assets без расширения; у рассказов-заглушек его нет.
class Story {
  const Story({
    required this.id,
    required this.title,
    required this.author,
    this.blurb = '',
    this.level = '',
    this.asset,
    this.source = '',
  });
  final String id, title, author, blurb, level, source;
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
    id: 'princeza-na-zrnu-grasku',
    title: 'Princeza na zrnu graška',
    author: 'Hans Kristijan Andersen',
    blurb:
        'Kratka bajka o princu koji traži pravu princezu: kad jedne olujne noći neko zakuca na vrata, '
        'kraljica pod dvadeset dušeka stavlja zrno graška da to proveri.',
    level: 'B1',
    asset: 'story_princeza_na_zrnu_grasku',
    source:
        'Hans Kristijan Andersen, Bajke, prevod Đido (1888), preuzeto sa sr.wikisource.org; tekst prenet u latinicu',
  ),
  Story(
    id: 'u-cara-trojana-kozje-usi',
    title: 'U cara Trojana kozje uši',
    author: 'Narodna priča (Vuk Karadžić)',
    blurb:
        'Car Trojan ima kozje uši i seče svakog berberina koji ih vidi, a berberski momak nosi tajnu '
        'dok je ne poveri zemlji – iz jame ipak izraste zova.',
    level: 'B1',
    asset: 'story_u_cara_trojana_kozje_usi',
    source: 'Vuk Stef. Karadžić, Srpske narodne pripovijetke (1870), preuzeto sa sr.wikisource.org; tekst prenet u latinicu',
  ),
  Story(
    id: 'kako-su-radile',
    title: 'Kako su radile onako su i prošle',
    author: 'Narodna priča (Vuk Karadžić)',
    blurb:
        'Dobru pastorku maćeha otera od kuće, a ona kod ale pomaže i dobija sanduk dukata; '
        'maćehina rođena kći se vraća s ništa manje nego što je zaslužila.',
    level: 'B1',
    asset: 'story_kako_su_radile_onako_su_i_prosle',
    source: 'Vuk Stef. Karadžić, Srpske narodne pripovijetke (1870), preuzeto sa sr.wikisource.org; tekst prenet u latinicu',
  ),
  Story(
    id: 'prava-se-muka-ne-da-sakriti',
    title: 'Prava se muka ne da sakriti',
    author: 'Narodna priča (Vuk Karadžić)',
    blurb:
        'Sluga dobija samo novčić za godinu dana službe i baca ga u vodu da vidi da li ga je zaslužio – '
        'a novčić, pretvoren u mačka, na kraju mu donosi pravo bogatstvo.',
    level: 'B2',
    asset: 'story_prava_se_muka_ne_da_sakriti',
    source: 'Vuk Stef. Karadžić, Srpske narodne pripovijetke (1870), preuzeto sa sr.wikisource.org; tekst prenet u latinicu',
  ),
  Story(
    id: 'medved-svinja-i-lisica',
    title: 'Međed, svinja i lisica',
    author: 'Narodna priča (Vuk Karadžić)',
    blurb:
        'Međed, svinja i lisica zajedno siju i žanju pšenicu, ali kad treba da je podele, '
        'međed prevari lisicu – a ona se sveti na svoj način.',
    level: 'B1',
    asset: 'story_medved_svinja_i_lisica',
    source: 'Vuk Stef. Karadžić, Srpske narodne pripovijetke (1870), preuzeto sa sr.wikisource.org; tekst prenet u latinicu',
  ),
  Story(
    id: 'dva-novca',
    title: 'Dva novca',
    author: 'Narodna priča (Vuk Karadžić)',
    blurb:
        'Dva čoveka zamene vreće – jedan donosi mahovinu umesto vune, drugi šišarice umesto oraha – '
        'pa se dugo sudare oko dva novca duga, sve dok ne dođe do neobične poente.',
    level: 'B2',
    asset: 'story_dva_novca',
    source: 'Vuk Stef. Karadžić, Srpske narodne pripovijetke (1870), preuzeto sa sr.wikisource.org; tekst prenet u latinicu',
  ),
  Story(
    id: 'djavo-i-njegov-segrt',
    title: 'Đavo i njegov šegrt',
    author: 'Narodna priča (Vuk Karadžić)',
    blurb:
        'Dečak ode u svet da nauči zanat, ali mu se za majstora ponudi đavo u zelenim haljinama '
        'i odvede ga na dno vode.',
    level: 'B2',
    asset: 'story_djavo_i_njegov_segrt',
    source: 'Vuk Stef. Karadžić, Srpske narodne pripovijetke (1870), preuzeto sa sr.wikisource.org; tekst prenet u latinicu',
  ),
  Story(
    id: 'opet-maceha-i-pastorka',
    title: 'Opet maćeha i pastorka',
    author: 'Narodna priča (Vuk Karadžić)',
    blurb:
        'Maćeha tera muža da odvede decu u planinu; deca beleže put pepelom, ali ih '
        'sledeća noć dovodi u neobičnu opasnost.',
    level: 'B2',
    asset: 'story_opet_maceha_i_pastorka',
    source: 'Vuk Stef. Karadžić, Srpske narodne pripovijetke (1870), preuzeto sa sr.wikisource.org; tekst prenet u latinicu',
  ),
  Story(
    id: 'slava',
    title: 'Slava',
    author: 'Radoje Domanović',
    blurb:
        'Jedne kišne jeseni pripovedač na putu kući sreće malog Mijata, pastira, i otkriva '
        'kako njegova porodica proslavlja slavu uprkos oskudici.',
    level: 'C1',
    asset: 'story_slava',
    source: 'Radoje Domanović, Slava (1903), preuzeto sa sr.wikisource.org (domanovic.org); tekst prenet u latinicu',
  ),
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
  Story(
    id: 'staklena-kula',
    title: 'Staklena kula',
    author: 'Klod Ironić',
    blurb:
        'Priča o devojci Ilzi koja je da bi spasla bolesnog oca otišla u staklenu kulu veštice Prelje, '
        'gde se prede ljudske sudbine, i čistom pesmom razbila njenu čaroliju.',
    level: 'B1',
    asset: 'story_staklena_kula',
  ),
  Story(
    id: 'ogledalo-bez-odsjaja',
    title: 'Ogledalo bez odsjaja',
    author: 'Klod Ironić',
    blurb:
        'Psihološki detektiv: inspektor Marko istražuje nestanak slikarke Sofije iz zaključane vile '
        'i pod ultraljubičastim svetlom otkriva istinu o njenom mužu.',
    level: 'B2',
    asset: 'story_ogledalo_bez_odsjaja',
  ),
  Story(
    id: 'tkacica-zaboravljenih-snova',
    title: 'Tkačica zaboravljenih snova',
    author: 'Klod Ironić',
    blurb:
        'Priča o mladiću Radovanu koji je otišao u pećinu tkačice Morane da zaboravi bol za izgubljenim bratom, '
        'ali je shvatio da je bol cena ljubavi.',
    level: 'B1',
    asset: 'story_tkacica_zaboravljenih_snova',
  ),
  Story(
    id: 'poslednje-eho',
    title: 'Poslednje eho sa planete Aeron',
    author: 'Klod Ironić',
    blurb:
        'Naučnofantastična priča o ksenoarheologu Viktoru Lazareviću koji na izumrloj planeti Aeron '
        'pronalazi oca zarobljenog u kristalu sećanja i mora da odluči da li da ga vrati kući.',
    level: 'B2',
    asset: 'story_poslednje_eho',
  ),
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
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'StoryReader'),
      builder: (_) => StoryReader(story: s, page: page),
    ),
  );
}

class StoriesPage extends StatelessWidget {
  const StoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          ui('Рассказы'),
          actions: [
            IconButton(
              tooltip: ui('Любимое'),
              icon: Icon(KIcons.heart, size: 24, color: cText),
              onPressed: () => _openCollection(context, searchHint: null),
            ),
            IconButton(
              tooltip: ui('Поиск'),
              icon: Icon(KIcons.search, size: 24, color: cText),
              onPressed: () => _openCollection(context, searchHint: ui('Поиск по рассказам')),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, box) {
              const pad = 12.0, gap = 16.0;
              // На широком экране — сетка вертикальных карточек, на телефоне — список.
              if (box.maxWidth < 640) {
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
                  itemCount: stories.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12),
                  itemBuilder: (_, i) => _StoryCard(stories[i]),
                );
              }
              final cols = ((box.maxWidth - 2 * pad + gap) / (260 + gap)).floor().clamp(2, 5);
              final cardW = (box.maxWidth - 2 * pad - gap * (cols - 1)) / cols;
              // Высота карточки — по содержимому (квадратная обложка + текст), без пустоты снизу.
              final rows = (stories.length / cols).ceil();
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
                itemCount: rows,
                separatorBuilder: (_, _) => SizedBox(height: gap),
                itemBuilder: (_, r) => IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < cols; c++) ...[
                        if (c > 0) SizedBox(width: gap),
                        SizedBox(
                          width: cardW,
                          child: r * cols + c < stories.length
                              ? _StoryCard(stories[r * cols + c], vertical: true)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

void _openCollection(BuildContext context, {required String? searchHint}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'CollectionPage'),
      builder: (_) => CollectionPage<Story>(
        title: ui('Любимое'),
        icon: KIcons.stories,
        items: [for (final s in stories) if (s.ready) s],
        likeId: (s) => s.wordKey,
        text: (s) => '${s.title} ${s.author}',
        tile: (s) => _StoryCard(s),
        searchHint: searchHint,
        emptyLiked: ui('Ставь сердечко рассказам, которые хочешь прочитать позже. Они появятся тут.'),
      ),
    ),
  );
}

final _pageCounts = <String, Future<int>>{};

/// Число страниц текста рассказа (без обложки); считаем один раз на рассказ.
Future<int> _storyPages(Story s) => _pageCounts.putIfAbsent(s.id, () async {
  try {
    final text = await rootBundle.loadString('assets/${s.asset}.txt');
    return _StoryReaderState._paginate(text).length;
  } catch (_) {
    return 0;
  }
});

class _PageCount extends StatelessWidget {
  const _PageCount(this.story, {this.inline = false});
  final Story story;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _storyPages(story),
      builder: (_, snap) {
        final n = snap.data ?? 0;
        if (n == 0) return SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: inline ? 0 : 4),
          child: Text(ui('{0} стр.', [n]), style: TextStyle(fontSize: 13, color: cMuted)),
        );
      },
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard(this.story, {this.vertical = false});
  final Story story;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final ready = story.ready;
    if (vertical) return _vertical(context, ready);
    final body = Padding(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 100,
              height: 100,
              child: ready
                  ? ExcludeSemantics(
                      child: Image.asset(
                        'assets/${story.asset}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: cCard2,
                          child: Icon(KIcons.stories, size: 36, color: cFaint),
                        ),
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
                Text(story.author, style: TextStyle(fontSize: 13, color: cText)),
                if (ready) _meta(),
                SizedBox(height: 8),
                if (!ready)
                  Text(
                    ui('Скоро'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cFaint),
                  ),
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
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(24), child: body),
          ),
        ),
      );
    }
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () => openStory(context, story), child: body),
        ),
        Positioned(top: 0, right: 0, child: _StoryHeart(story, onCover: false)),
      ],
    );
  }

  /// Сложность и число страниц в одну строку.
  Widget _meta() => Padding(
    padding: EdgeInsets.only(top: 4),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        if (story.level.isNotEmpty) DifficultyLabel(story.level),
        _PageCount(story, inline: true),
      ],
    ),
  );

  /// Карточка для сетки: вертикальная обложка сверху, под ней название, автор и уровень.
  Widget _vertical(BuildContext context, bool ready) {
    final body = Padding(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: ready
                  ? ExcludeSemantics(
                      child: Image.asset(
                        'assets/${story.asset}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: cCard2,
                          child: Icon(KIcons.stories, size: 36, color: cFaint),
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: cCard2,
                      child: Icon(KIcons.stories, size: 36, color: cFaint),
                    ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            store.conv(story.title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2, color: cText),
          ),
          SizedBox(height: 4),
          Text(
            story.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: cText),
          ),
          if (ready) _meta(),
          if (!ready)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                ui('Скоро'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cFaint),
              ),
            ),
        ],
      ),
    );
    if (!ready) {
      return Semantics(
        label: ui('{0}, скоро', [story.title]),
        child: ExcludeSemantics(
          child: Opacity(
            opacity: 0.55,
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(24), child: body),
          ),
        ),
      );
    }
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () => openStory(context, story), child: body),
        ),
        Positioned(top: 0, right: 0, child: _StoryHeart(story, onCover: true)),
      ],
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
  List<QuizSection> _quiz = [];

  // Страница 0 — обложка, дальше текст, в конце — финальный экран.
  int get _count => _pages.length + 2;

  @override
  void initState() {
    super.initState();
    _ctl = PageController(initialPage: _i);
    _load();
    loadQuiz(widget.story.asset!).then((q) {
      if (mounted && q.isNotEmpty) setState(() => _quiz = q);
    });
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
      final dict =
          jsonDecode(await store.assetText('$asset.dict.json', en: '$asset.dict.en.json')) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _pages = _paginate(text);
        _dict = dict;
        _i = _i.clamp(0, _count - 1);
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
                            trailing: Text(
                              ui('стр. {0}', [w.t.toInt()]),
                              style: TextStyle(fontSize: 12, color: cFaint),
                            ),
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
    // Широкий экран: шапка на всю ширину, а книга лежит на белой плашке с тенью на сером фоне.
    final wide = MediaQuery.sizeOf(context).width >= 960;
    if (wide) {
      return Scaffold(
        backgroundColor: cCard,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: cBg,
                child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _header()),
              ),
              Divider(height: 1, color: cLine),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 840),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cBg,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 32, offset: Offset(0, 8)),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _body()),
                            if (_pages.isNotEmpty) _footer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: EdgeInsets.only(left: 12, right: 12), child: _header()),
                Expanded(child: _body()),
                if (_pages.isNotEmpty) _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final s = widget.story;
    return Row(
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
    );
  }

  Widget _body() {
    return _failed
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
              itemBuilder: (_, i) => i == 0
                  ? _cover()
                  : i == _count - 1
                  ? _finish()
                  : _text(_pages[i - 1], last: i == _count - 2),
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

  Widget _text(List<List<_Token>> paragraphs, {bool last = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final para in paragraphs)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Wrap(spacing: 6, children: [for (final t in para) _word(t)]),
            ),
          if (last && widget.story.source.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              ui('Источник: {0}', [widget.story.source]),
              style: TextStyle(fontSize: 12, height: 1.45, color: cFaint),
            ),
          ],
        ],
      ),
    );
  }

  // Последняя страница: рассказ прочитан, отсюда можно перейти к заданиям.
  Widget _finish() {
    final s = widget.story;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: cAccent, shape: BoxShape.circle),
            child: Icon(KIcons.done, size: 44, color: cInk),
          ),
          SizedBox(height: 24),
          Text(
            ui('Рассказ прочитан'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: cText),
          ),
          SizedBox(height: 10),
          Text(
            _quiz.isEmpty
                ? ui('Вот и конец рассказа «{0}». Возвращайся к нему, чтобы повторить слова.', [store.conv(s.title)])
                : ui('Вот и конец рассказа «{0}». Проверь, как ты его понял: ответь на вопросы по смыслу и словам.', [store.conv(s.title)]),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5, color: cMuted),
          ),
          SizedBox(height: 28),
          if (_quiz.isNotEmpty)
            ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final left = _quiz.where((q) => store.quizResult(s.asset!, q.title) == null).length;
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: cViolet,
                      foregroundColor: cOnViolet,
                      minimumSize: Size.fromHeight(52),
                    ),
                    icon: Icon(KIcons.tasks, size: 20),
                    label: Text(
                      left > 0 ? ui('Задания · {0}', [left]) : ui('Задания'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: RouteSettings(name: 'SubPage'),
                        builder: (_) => SubPage(
                          title: ui('Задания'),
                          child: QuizList(videoId: s.asset!, sections: _quiz),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () => _ctl.animateToPage(0, duration: Duration(milliseconds: 350), curve: Curves.easeOut),
            child: Text(ui('Читать сначала'), style: TextStyle(fontWeight: FontWeight.w700, color: cMuted)),
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
                _i == 0
                    ? ui('Начало')
                    : _i == _count - 1
                    ? ui('Конец')
                    : '$_i из ${_count - 2}',
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

/// Сердечко рассказа; на вертикальной карточке лежит поверх обложки.
class _StoryHeart extends StatelessWidget {
  const _StoryHeart(this.story, {required this.onCover});
  final Story story;
  final bool onCover;

  @override
  Widget build(BuildContext context) {
    final heart = LikeButton(story.wordKey);
    if (!onCover) return heart;
    return Padding(
      padding: EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(color: cBg.withValues(alpha: 0.85), shape: BoxShape.circle),
        child: heart,
      ),
    );
  }
}
