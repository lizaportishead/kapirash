import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'player_page.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'videos.dart';

class WordsPage extends StatelessWidget {
  const WordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.words.reversed.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTitle(
              'Мои слова${list.isEmpty ? '' : ' · ${list.length}'}',
              actions: [
                if (list.isNotEmpty)
                  Pill(
                    'Скопировать',
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: store.words.map((w) => '${w.key}\t${w.tr}\t${w.ctx}').join('\n')),
                      );
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Скопировано'), duration: Duration(milliseconds: 1200)));
                    },
                  ),
              ],
            ),
            Expanded(
              child: list.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Пока пусто. Открой ролик, нажми на слово в субтитрах и сохрани его.',
                        style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8),
                      itemBuilder: (_, i) => _WordCard(list[i]),
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
    return Material(
      color: cCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: video == null ? null : () => openVideo(context, video, startAt: w.t),
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
