import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'icons.dart';
import 'learn_page.dart';
import 'player_page.dart';
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTitle(
              '${ui('Мои слова')}${every.isEmpty ? '' : ' · ${every.length}'}',
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
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                          padding: EdgeInsets.fromLTRB(12, 0, 12, _searching ? 16 : 72),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => SizedBox(height: 8),
                          itemBuilder: (_, i) => _WordCard(list[i]),
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

final FlutterTts _tts = FlutterTts();
bool _ttsReady = false;

Future<void> _speak(String word) async {
  try {
    if (!_ttsReady) {
      await _tts.setLanguage('sr-RS');
      await _tts.setSpeechRate(0.4);
      _ttsReady = true;
    }
    await _tts.stop();
    await _tts.speak(toCyr(toLat(word)));
  } catch (_) {}
}

class _WordCard extends StatelessWidget {
  const _WordCard(this.w);
  final SavedWord w;

  @override
  Widget build(BuildContext context) {
    final video = videoById(w.video);
    final story = storyById(w.video);
    final VoidCallback? onOpen = video != null
        ? () => openVideo(context, video, startAt: w.t)
        : story != null
        ? () => openStory(context, story, page: w.t.toInt())
        : null;
    return Material(
      color: cCard,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 14, 6, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.conv(w.key),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cText),
                  ),
                  if (w.lemma != null && w.lemma != w.key)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        ui('{0} от {1}', [formUi(w.form == null || w.form!.isEmpty ? 'Форма' : w.form!), store.conv(w.lemma!)]) +
                            (w.lemmaTr.isEmpty ? '' : ' — ${w.lemmaTr}'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: cText,
                        ),
                      ),
                    ),
                  if (w.tr.isNotEmpty)
                    Text(
                      w.tr,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cAccentText),
                    ),
                  SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onOpen,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: store.conv(w.ctx)),
                            if (onOpen != null) ...[
                              TextSpan(text: ' '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(Icons.arrow_forward_rounded, size: 16, color: cViolet),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, height: 1.4, color: cMuted),
                      ),
                    ),
                  ),
                  if (story != null) ...[
                    SizedBox(height: 6),
                    Text(
                      ui('{0} · стр. {1}', [story.title, w.t.toInt()]),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cFaint),
                    ),
                  ],
                ],
              ),
            ),
            if (w.learned)
              IconButton(
                tooltip: ui('Вернуть в изучение'),
                icon: Icon(Icons.undo_rounded, size: 20, color: cMuted),
                onPressed: () => store.setLearned(w.key, false),
              ),
            IconButton(
              tooltip: ui('Прослушать {0}', [w.key]),
              icon: Icon(Icons.volume_up_rounded, size: 22, color: cViolet),
              onPressed: () => _speak(w.key),
            ),
            IconButton(
              tooltip: ui('Удалить {0}', [w.key]),
              icon: Icon(Icons.close, size: 18, color: cMuted),
              onPressed: () => store.remove(w.key),
            ),
          ],
        ),
      ),
    );
  }
}
