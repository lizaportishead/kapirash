import 'package:flutter/material.dart';

import 'icons.dart';
import 'l10n.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';

/// Экран «Избранное» или поиска для раздела (рассказы, подкасты): [items] — всё, что есть в разделе,
/// [likeId] — ключ в store.liked, [text] — по чему искать, [tile] — карточка.
class CollectionPage<T> extends StatefulWidget {
  const CollectionPage({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.likeId,
    required this.text,
    required this.tile,
    this.searchHint,
    this.emptyLiked = '',
  });

  /// Если [searchHint] задан — это поиск, иначе список любимого.
  final String title;
  final IconData icon;
  final List<T> items;
  final String Function(T) likeId;
  final String Function(T) text;
  final Widget Function(T) tile;
  final String? searchHint;
  final String emptyLiked;

  @override
  State<CollectionPage<T>> createState() => _CollectionPageState<T>();
}

class _CollectionPageState<T> extends State<CollectionPage<T>> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Поиск не различает латиницу и кириллицу: «село» находит «sela».
  static String _norm(String s) => toLat(s.toLowerCase());

  List<T> get _found {
    if (widget.searchHint == null) {
      final byId = <String, T>{for (final i in widget.items) widget.likeId(i): i};
      return [
        for (final id in store.liked.reversed)
          if (byId[id] case final T item) item,
      ];
    }
    final q = _norm(_search.text.trim());
    if (q.isEmpty) return widget.items;
    return widget.items.where((i) => _norm(widget.text(i)).contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searching = widget.searchHint != null;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: searching ? 720 : double.infinity),
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final list = _found;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (searching)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: ui('Назад'),
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
                                  hintText: widget.searchHint,
                                  hintStyle: TextStyle(color: cFaint),
                                  prefixIcon: Icon(KIcons.search, color: cFaint),
                                  suffixIcon: _search.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: ui('Очистить'),
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
                      )
                    else ...[
                      ...pageHeader(context, '${widget.title}${list.isEmpty ? '' : ' · ${list.length}'}'),
                    ],
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 720),
                          child: list.isEmpty
                              ? Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!searching)
                                        Flexible(
                                          child: ExcludeSemantics(
                                            child: Image.asset('assets/ill_liked.png', height: 220),
                                          ),
                                        ),
                                      if (!searching) SizedBox(height: 16),
                                      Text(
                                        searching
                                            ? ui('Ничего не нашлось. Попробуй другой запрос.')
                                            : widget.emptyLiked,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: list.length,
                                  separatorBuilder: (_, _) => SizedBox(height: 16),
                                  itemBuilder: (_, i) => widget.tile(list[i]),
                                ),
                        ),
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
