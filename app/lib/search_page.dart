import 'package:flutter/material.dart';

import 'clips_page.dart';
import 'icons.dart';
import 'subs.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';

/// Открывает экран поиска поверх таббара: по каталогу, а с [clips] — по клипам.
void openSearch(BuildContext context, {bool clips = false}) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SearchPage(clips: clips)));
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.clips = false});
  final bool clips;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Поиск не различает латиницу и кириллицу: «село» находит «sela».
  static String _norm(String s) => toLat(s.toLowerCase());

  List<Video> get _found {
    final q = _norm(_search.text.trim());
    final all = widget.clips ? clips : videos;
    if (q.isEmpty) return all;
    return all.where((v) => _norm('${v.title} ${v.channel} ${v.topic}').contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _found;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Назад',
                        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          style: TextStyle(fontSize: 15, color: cText),
                          cursorColor: cViolet,
                          decoration: InputDecoration(
                            hintText: widget.clips ? 'Поиск по клипам' : 'Поиск по роликам',
                            hintStyle: TextStyle(color: cFaint),
                            prefixIcon: Icon(KIcons.search, color: cFaint),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Очистить',
                                    icon: Icon(Icons.close, size: 18, color: cMuted),
                                    onPressed: () => setState(_search.clear),
                                  ),
                            filled: true,
                            fillColor: cCard,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Ничего не нашлось. Попробуй другой запрос.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: cMuted),
                          ),
                        )
                      : widget.clips
                      ? GridView.builder(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                          gridDelegate: clipGrid,
                          itemCount: list.length,
                          itemBuilder: (_, i) => ClipTile(list[i], among: list),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => SizedBox(height: 12),
                          itemBuilder: (_, i) => VideoCard(list[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
