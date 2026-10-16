import 'package:flutter/material.dart';

import 'learn_page.dart';
import 'player_page.dart';
import 'stories_page.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'videos.dart';

class WordsPage extends StatefulWidget {
  const WordsPage({super.key});

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  final _search = TextEditingController();
  bool _searching = false;

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
        final all = store.words.reversed.toList();
        final q = _norm(_search.text.trim());
        final list = q.isEmpty ? all : all.where((w) => _norm('${w.key} ${w.lemma ?? ''} ${w.tr} ${w.lemmaTr} ${w.ctx}').contains(q)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTitle(
              'Мои слова${all.isEmpty ? '' : ' · ${all.length}'}',
              actions: [
                if (all.isNotEmpty)
                  IconButton(
                    tooltip: _searching ? 'Закрыть поиск' : 'Поиск',
                    icon: Icon(_searching ? Icons.close : Icons.search_rounded, size: 24, color: cText),
                    onPressed: _toggleSearch,
                  ),
              ],
            ),
            if (_searching && all.isNotEmpty)
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
                    hintText: 'Поиск по словам',
                    hintStyle: TextStyle(color: cFaint),
                    prefixIcon: Icon(Icons.search_rounded, color: cFaint),
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
                  all.isEmpty
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Картинка декоративная: на низком экране ужимается, а не обрезает текст.
                              Flexible(
                                child: ExcludeSemantics(
                                  child: Image.asset('assets/ill_words.png', height: 173),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Пока пусто. Открой ролик, нажми на слово в субтитрах и сохрани его.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                              ),
                            ],
                          ),
                        )
                      : list.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Ничего не нашлось. Попробуй другой запрос.',
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
                  if (all.isNotEmpty && !_searching)
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
                          child: Text('Учить слова'),
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

class _WordCard extends StatelessWidget {
  const _WordCard(this.w);
  final SavedWord w;

  @override
  Widget build(BuildContext context) {
    final video = videoById(w.video);
    final story = storyById(w.video);
    return Material(
      color: cCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: video != null
            ? () => openVideo(context, video, startAt: w.t)
            : story != null
            ? () => openStory(context, story, page: w.t.toInt())
            : null,
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
                          'нач. форма: ${store.conv(w.lemma!)}${w.lemmaTr.isEmpty ? '' : ' — ${w.lemmaTr}'}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cViolet),
                        ),
                      ),
                    if (w.tr.isNotEmpty)
                      Text(
                        w.tr,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cAccentText),
                      ),
                    SizedBox(height: 6),
                    Text(
                      store.conv(w.ctx),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, height: 1.4, color: cMuted),
                    ),
                    if (video != null) ...[
                      SizedBox(height: 6),
                      Text(
                        '${video.channel} · ${fmtTime(w.t)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cFaint),
                      ),
                    ] else if (story != null) ...[
                      SizedBox(height: 6),
                      Text(
                        '${story.title} · стр. ${w.t.toInt()}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cFaint),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Удалить ${w.key}',
                icon: Icon(Icons.close, size: 18, color: cMuted),
                onPressed: () => store.remove(w.key),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
