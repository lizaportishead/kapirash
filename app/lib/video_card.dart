import 'package:flutter/material.dart';

import 'clips_page.dart';
import 'creator_page.dart';
import 'player_page.dart';
import 'store.dart';
import 'theme.dart';
import 'videos.dart';

/// Карточка ролика в списке. Имя канала ведёт на страницу креатора, если [showChannel] включён.
/// Внизу превью — шкала просмотра, как на YouTube.
class VideoCard extends StatelessWidget {
  const VideoCard(this.v, {super.key, this.showChannel = true});
  final Video v;
  final bool showChannel;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: cInk,
      child: Center(child: Icon(Icons.play_arrow_rounded, size: 56, color: cOnInk.withValues(alpha: 0.5))),
    );
    return Material(
      color: cCard,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openVideo(context, v),
        child: Padding(
          padding: EdgeInsets.all(8),
          // Метки и шкала меняются, пока карточка на экране: ролик посмотрели, сохранили из него слово.
          child: ListenableBuilder(listenable: store, builder: (context, _) => _body(context, placeholder)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Widget placeholder) {
    // У своего ролика — состояние субтитров. Уровень (B1, B2) пока не показываем.
    final tag = v.mine ? (store.myVideo(v.id)?.status.label ?? '') : '';
    final progress = store.progressOf(v);
    final words = store.wordCount(v.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (v.tiktok)
                  ClipCover(v)
                else
                  Image.network(
                    'https://i.ytimg.com/vi/${v.id}/hqdefault.jpg',
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
                if (tag.isNotEmpty) Positioned(left: 10, top: 10, child: VideoTag(tag, accent: true)),
                if (words > 0)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: VideoTag('$words ${plural(words, 'слово', 'слова', 'слов')}', accent: true),
                  ),
                if (v.duration.isNotEmpty) Positioned(right: 10, bottom: 10, child: VideoTag(v.duration)),
                if (progress > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      // Едва начатый ролик всё равно должен показать заметный кусочек шкалы.
                      value: progress < 0.03 ? 0.03 : progress,
                      minHeight: 4,
                      color: cViolet,
                      backgroundColor: cOnInk.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(8, 12, 0, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _text(context)),
              LikeButton(v.id),
            ],
          ),
        ),
      ],
    );
  }

  Widget _text(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          v.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.25, color: cText),
        ),
        if (v.mine)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              v.channel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: cMuted),
            ),
          )
        else if (showChannel)
          Row(
            children: [
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => openCreator(context, v.channel),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CreatorAvatar(v.channel, size: 20),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            v.channel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(' · ${v.topic}', style: TextStyle(fontSize: 13, color: cMuted)),
            ],
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(v.topic, style: TextStyle(fontSize: 13, color: cMuted)),
          ),
      ],
    );
  }
}

class VideoTag extends StatelessWidget {
  const VideoTag(this.text, {super.key, this.accent = false});
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? cViolet : cInk.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent ? cOnViolet : cOnInk),
      ),
    );
  }
}

/// Сердечко ролика: ставит и снимает отметку, список отмеченных — на экране «Любимое».
class LikeButton extends StatelessWidget {
  const LikeButton(this.videoId, {super.key});
  final String videoId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final on = store.isLiked(videoId);
        return IconButton(
          tooltip: on ? 'Убрать сердечко' : 'Поставить сердечко',
          isSelected: on,
          icon: Icon(Icons.favorite_border_rounded, size: 22, color: cMuted),
          selectedIcon: Icon(Icons.favorite_rounded, size: 22, color: cViolet),
          onPressed: () => store.toggleLike(videoId),
        );
      },
    );
  }
}
