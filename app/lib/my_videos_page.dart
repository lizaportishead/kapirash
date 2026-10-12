import 'package:flutter/material.dart';

import 'add_video.dart';
import 'store.dart';
import 'theme.dart';
import 'video_card.dart';

class MyVideosPage extends StatelessWidget {
  const MyVideosPage({super.key});

  Future<void> _remove(BuildContext context, MyVideo m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: Text(
          'Удалить ролик?',
          style: TextStyle(fontWeight: FontWeight.w800, color: cText),
        ),
        content: Text(
          '«${m.video.title}» и его субтитры будут удалены с устройства. Сохранённые слова останутся.',
          style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Отмена', style: TextStyle(color: cText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Удалить',
              style: TextStyle(fontWeight: FontWeight.w800, color: cAccentText),
            ),
          ),
        ],
      ),
    );
    if (ok == true) store.removeVideo(m.video.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.myVideos.reversed.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTitle('Мои ролики${list.isEmpty ? '' : ' · ${list.length}'}'),
            Expanded(
              child: list.isEmpty
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Картинка декоративная: на низком экране ужимается, а не обрезает текст.
                          Flexible(
                            child: ExcludeSemantics(
                              child: Image.asset('assets/ill_my_videos.png', height: 173),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Пока пусто. Добавь свой ролик с YouTube — мы подготовим к нему субтитры, '
                            'перевод и словарик. Твои ролики видны только тебе.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                          ),
                          SizedBox(height: 14),
                          Pill('Добавить ролик', on: true, onTap: () => showAddVideo(context)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12),
                      itemBuilder: (_, i) => _MyVideoCard(list[i], onRemove: () => _remove(context, list[i])),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MyVideoCard extends StatelessWidget {
  const _MyVideoCard(this.m, {required this.onRemove});
  final MyVideo m;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            VideoCard(m.video),
            Positioned(
              right: 16,
              top: 16,
              child: Material(
                color: cInk.withValues(alpha: 0.85),
                shape: CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: 'Удалить ролик',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: cOnInk),
                  onPressed: onRemove,
                ),
              ),
            ),
          ],
        ),
        if (m.status == SubsStatus.failed)
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Row(
              children: [
                Flexible(
                  child: Text('Не удалось создать субтитры.', style: TextStyle(fontSize: 13, color: cMuted)),
                ),
                SizedBox(width: 10),
                Pill('Повторить', onTap: () => store.generateSubs(m.video.id)),
              ],
            ),
          ),
      ],
    );
  }
}
