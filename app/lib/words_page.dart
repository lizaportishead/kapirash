import 'package:flutter/material.dart';

import 'icons.dart';
import 'learn_page.dart';
import 'phrase.dart';
import 'player_page.dart';
import 'podcasts_page.dart';
import 'store.dart';
import 'stories_page.dart';
import 'subs.dart';
import 'theme.dart';
import 'videos.dart';
import 'l10n.dart';

class WordsPage extends StatefulWidget {
  const WordsPage({super.key});

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  final _search = TextEditingController();
  bool _searching = false;
  bool _learnedTab = false;

  @override
  void initState() {
    super.initState();
    store.fillLemmas();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Поиск не различает латиницу и кириллицу: «село» находит «sela».
  static String _norm(String s) => toLat(s.toLowerCase());

  /// Контекст с выделенным жирным сохранённым словом.
  static List<TextSpan> _ctxSpans(String text, Set<String> words) {
    final targets = words.map(_norm).toSet();
    final spans = <TextSpan>[];
    final hit = RegExp(
      r'[\p{L}\u0301]+',
      unicode: true,
    ).allMatches(text).where((m) => targets.contains(_norm(m.group(0)!))).firstOrNull;
    // Длинное предложение обрезаем вокруг слова, по границам слов.
    const span = 55;
    if (text.length > span * 2 + 20) {
      final c = hit?.start ?? 0;
      var a = (c - span).clamp(0, text.length);
      var b = (c + span).clamp(0, text.length);
      if (a > 0) {
        final i = text.indexOf(' ', a);
        a = i < 0 || i > c ? a : i + 1;
      }
      if (b < text.length) {
        final i = text.lastIndexOf(' ', b);
        b = i > c ? i : b;
      }
      text = '${a > 0 ? '… ' : ''}${text.substring(a, b)}${b < text.length ? ' …' : ''}';
    }
    var last = 0;
    for (final m in RegExp(r'[\p{L}\u0301]+', unicode: true).allMatches(text)) {
      if (!targets.contains(_norm(m.group(0)!))) continue;
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(
        TextSpan(
          text: m.group(0),
          style: TextStyle(fontWeight: FontWeight.w800, color: cText),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    _search.clear();
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final every = store.words.reversed.toList();
        final all = every.where((w) => w.learned == _learnedTab).toList();
        final q = _norm(_search.text.trim());
        final list = q.isEmpty
            ? all
            : all.where((w) => _norm('${w.key} ${w.lemma ?? ''} ${w.tr} ${w.lemmaTr} ${w.ctx}').contains(q)).toList();
        // Слова группируются по ролику (группы — по самому свежему слову); заголовок — строка, слово — SavedWord.
        final groups = <String, List<SavedWord>>{};
        for (final w in list) {
          (groups[w.video] ??= []).add(w);
        }
        final items = <Object>[];
        for (final e in groups.entries) {
          final title = videoById(e.key)?.title ?? storyById(e.key)?.title ?? '';
          if (title.isNotEmpty) items.add(_Head(e.key, store.conv(title)));
          items.addAll(e.value);
        }
        final cols = MediaQuery.sizeOf(context).width >= 700 ? 2 : 1;
        final rows = <Object>[];
        for (var i = 0; i < items.length;) {
          if (items[i] is _Head) {
            rows.add(items[i++]);
            continue;
          }
          final row = <SavedWord>[];
          while (i < items.length && items[i] is SavedWord && row.length < cols) {
            row.add(items[i++] as SavedWord);
          }
          rows.add(row);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTitle(
              '${ui('Словарь')}${every.isEmpty ? '' : ' · ${every.length}'}',
              actions: [
                if (every.isNotEmpty)
                  IconButton(
                    tooltip: _searching ? ui('Закрыть поиск') : ui('Поиск'),
                    icon: Icon(_searching ? Icons.close : KIcons.search, size: 24, color: cText),
                    onPressed: _toggleSearch,
                  ),
              ],
            ),
            if (every.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    Pill(
                      '${ui('В процессе')} · ${every.where((w) => !w.learned).length}',
                      on: !_learnedTab,
                      onTap: () => setState(() => _learnedTab = false),
                    ),
                    SizedBox(width: 8),
                    Pill(
                      '${ui('Выучено')} · ${every.where((w) => w.learned).length}',
                      on: _learnedTab,
                      onTap: () => setState(() => _learnedTab = true),
                    ),
                  ],
                ),
              ),
            if (_searching && every.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 15, color: cText),
                  cursorColor: cViolet,
                  decoration: InputDecoration(
                    hintText: ui('Поиск по словам'),
                    hintStyle: TextStyle(color: cFaint),
                    prefixIcon: Icon(KIcons.search, color: cFaint),
                    filled: true,
                    fillColor: cCard,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  every.isEmpty
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: SizedBox.expand(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Картинка декоративная: на низком экране ужимается, а не обрезает текст.
                                Flexible(
                                  child: ExcludeSemantics(child: Image.asset('assets/ill_words.png', height: 173)),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  ui('Пока пусто. Открой ролик, нажми на слово в субтитрах и сохрани его.'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : list.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            all.isEmpty
                                ? ui(_learnedTab ? 'Выученных слов пока нет.' : 'Все слова выучены.')
                                : ui('Ничего не нашлось. Попробуй другой запрос.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: cMuted),
                          ),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          // Снизу запас под плавающую кнопку.
                          padding: EdgeInsets.fromLTRB(16, 4, 16, _searching ? 16 : 72),
                          itemCount: rows.length,
                          separatorBuilder: (_, i) =>
                              SizedBox(height: rows[i] is _Head || rows[i + 1] is _Head ? 0 : 16),
                          itemBuilder: (_, i) {
                            final it = rows[i];
                            if (it is List<SavedWord>) {
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (var k = 0; k < cols; k++) ...[
                                      if (k > 0) SizedBox(width: 16),
                                      Expanded(child: k < it.length ? _WordCard(it[k]) : SizedBox.shrink()),
                                    ],
                                  ],
                                ),
                              );
                            }
                            it as _Head;
                            final video = videoById(it.id);
                            final icon = video == null
                                ? KIcons.stories
                                : video.podcast
                                ? KIcons.headphones
                                : video.tiktok
                                ? KIcons.clips
                                : KIcons.videos;
                            return _HeadRow(
                              icon: icon,
                              title: it.title,
                              padding: EdgeInsets.fromLTRB(4, i == 0 ? 4 : 36, 4, 12),
                              onTap: () => _openSource(context, it.id),
                            );
                          },
                        ),
                  if (all.isNotEmpty && !_learnedTab && !_searching)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: Center(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: cText,
                            foregroundColor: cBg,
                            elevation: 6,
                            minimumSize: Size(0, 44),
                            padding: EdgeInsets.symmetric(horizontal: 22),
                            shape: StadiumBorder(),
                            textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () => openLearn(context),
                          child: Text(ui('Учить слова')),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Заголовок группы слов: ролик, подкаст или книга, откуда они.
class _Head {
  const _Head(this.id, this.title);
  final String id, title;
}

/// Заголовок группы: при наведении меняется только цвет, без плашки.
class _HeadRow extends StatefulWidget {
  const _HeadRow({required this.icon, required this.title, required this.padding, required this.onTap});
  final IconData icon;
  final String title;
  final EdgeInsets padding;
  final VoidCallback onTap;

  @override
  State<_HeadRow> createState() => _HeadRowState();
}

class _HeadRowState extends State<_HeadRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? cText : cFaint;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: widget.padding,
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: color),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Открывает источник слова: сам ролик/подкаст/книгу, а при [t] — на месте, где слово встретилось.
void _openSource(BuildContext context, String id, {double? t}) {
  final video = videoById(id);
  final story = storyById(id);
  if (video != null) {
    video.podcast
        ? openPodcast(context, video, startAt: t, autoplay: t != null)
        : openVideo(context, video, startAt: t);
  } else if (story != null) {
    openStory(context, story, page: t?.toInt());
  }
}

/// Краткая карточка в списке: слово, перевод и озвучка. Остальное — в шторке по нажатию.
class _WordCard extends StatelessWidget {
  const _WordCard(this.w);
  final SavedWord w;

  @override
  Widget build(BuildContext context) {
    return Lift(
      child: Material(
        color: cCard,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showWordSheet(context, w),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: w.starred ? ui('Убрать из избранного') : ui('Добавить в избранное'),
                  visualDensity: VisualDensity.compact,
                  isSelected: w.starred,
                  icon: Icon(KIcons.star, size: 20, color: cFaint),
                  selectedIcon: Icon(Icons.star_rounded, size: 20, color: cViolet),
                  onPressed: () => store.toggleStar(w.key),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.stressed(w.key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cText),
                      ),
                      if (w.tr.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            w.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: cAccentText,
                            ),
                          ),
                        ),
                      if (w.lemma != null && w.lemma != w.key)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            ui('{0} от {1}', [
                              formUi(w.form == null || w.form!.isEmpty ? 'Форма' : w.form!),
                              store.conv(w.lemma!),
                            ]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, height: 1.35, color: cMuted),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: ui('Удалить {0}', [w.key]),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 18, color: cMuted),
                  onPressed: () => store.remove(w.key),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Полная информация о слове: шторка на телефоне, окно по центру на десктопе.
void _showWordSheet(BuildContext context, SavedWord w) {
  final wide = MediaQuery.sizeOf(context).width >= 700;
  Widget body(BuildContext ctx) => _WordSheet(w);
  if (wide) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 560), child: body(ctx)),
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: body,
    );
  }
}

class _WordSheet extends StatelessWidget {
  const _WordSheet(this.w);
  final SavedWord w;

  @override
  Widget build(BuildContext context) {
    final video = videoById(w.video);
    final story = storyById(w.video);
    void open(void Function() go) {
      Navigator.of(context).pop();
      go();
    }

    final VoidCallback? onOpen = video != null
        ? () => open(() => _openSource(context, w.video, t: w.t))
        : story != null
        ? () => open(() => _openSource(context, w.video, t: w.t))
        : null;
    final links = w.key.contains(' ')
        ? null
        : Wrap(
            spacing: 8,
            children: [
              LinkButton(
                icon: Image.asset('assets/glosbe.png', width: 18, height: 18),
                label: ui('Смотреть в Glosbe'),
                url: Uri.https('glosbe.com', '/sr/${store.lang == 'en' ? 'en' : 'ru'}/${toCyr(toLat(w.key))}'),
              ),
              LinkButton(
                icon: Text(
                  'W',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: cMuted,
                  ),
                ),
                label: ui('Смотреть в Wiktionary'),
                url: Uri.https(
                  'en.wiktionary.org',
                  '/wiki/${toLat(w.lemma ?? w.key)}',
                ).replace(fragment: 'Serbo-Croatian'),
              ),
            ],
          );
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, 24, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    store.stressed(w.key),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.6,
                      color: cText,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 22, color: cMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (w.tr.isNotEmpty) ...[
              SizedBox(height: 14),
              Text(
                w.tr,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25, color: cAccentText),
              ),
            ],
            if (w.lemma != null && w.lemma != w.key) ...[
              SizedBox(height: 10),
              Text(
                ui('{0} от {1}', [
                      formUi(w.form == null || w.form!.isEmpty ? 'Форма' : w.form!),
                      store.conv(w.lemma!),
                    ]) +
                    (w.lemmaTr.isEmpty ? '' : ' — ${w.lemmaTr}'),
                style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
              ),
            ],
            if (links != null) ...[SizedBox(height: 18), links],
            SizedBox(height: 22),
            Material(
              color: cCard,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onOpen,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        ..._WordsPageState._ctxSpans(store.conv(w.ctx), {w.key, if (w.form != null) w.form!}),
                        if (onOpen != null) ...[
                          TextSpan(text: ' '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(Icons.arrow_forward_rounded, size: 16, color: cViolet),
                          ),
                        ],
                      ],
                    ),
                    style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                  ),
                ),
              ),
            ),
            if (story != null || video != null) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    story != null
                        ? Icons.menu_book_rounded
                        : video!.podcast
                        ? Icons.mic_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 16,
                    color: cFaint,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      story != null ? ui('{0} · стр. {1}', [story.title, w.t.toInt()]) : (video?.title ?? ''),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cFaint),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 28),
            if (w.learned) ...[
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
                icon: Icon(Icons.undo_rounded, size: 18, color: cMuted),
                label: Text(ui('Вернуть в изучение'), style: TextStyle(color: cMuted)),
                onPressed: () {
                  store.setLearned(w.key, false);
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(height: 8),
            ],
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFFDE8E8),
                minimumSize: Size.fromHeight(52),
                padding: EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFD32F2F)),
              label: Text(
                ui('Удалить слово'),
                style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                store.remove(w.key);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
