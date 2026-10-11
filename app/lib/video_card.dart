import 'package:flutter/material.dart';

import 'creator_page.dart';
import 'player_page.dart';
import 'store.dart';
import 'theme.dart';
import 'videos.dart';

/// Карточка ролика в списке. Имя канала ведёт на страницу креатора, если [showChannel] включён.
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
    // У своего ролика вместо уровня — состояние субтитров.
    final tag = v.mine ? (store.myVideo(v.id)?.status.label ?? '') : v.level;
    return Material(
      color: cCard,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openVideo(context, v),
        child: Padding(padding: EdgeInsets.all(8), child: _body(context, placeholder, tag)),
      ),
    );
  }

  Widget _body(BuildContext context, Widget placeholder, String tag) {
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
                Image.network(
                  'https://i.ytimg.com/vi/${v.id}/hqdefault.jpg',
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, _, _) => placeholder,
                ),
                if (tag.isNotEmpty) Positioned(left: 10, top: 10, child: _Tag(tag, accent: true)),
                if (v.duration.isNotEmpty) Positioned(right: 10, bottom: 10, child: _Tag(v.duration)),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(8, 12, 8, 6),
          child: Column(
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
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.accent = false});
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
