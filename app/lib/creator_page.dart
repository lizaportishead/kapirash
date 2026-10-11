import 'package:flutter/material.dart';

import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';

/// Открывает страницу креатора поверх таббара.
void openCreator(BuildContext context, String channel) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (_) => CreatorPage(channel: channel)));
}

String _plural(int n, String one, String few, String many) {
  final d = n % 10, h = n % 100;
  if (d == 1 && h != 11) return one;
  if (d >= 2 && d <= 4 && (h < 12 || h > 14)) return few;
  return many;
}

class CreatorPage extends StatelessWidget {
  const CreatorPage({super.key, required this.channel});
  final String channel;

  @override
  Widget build(BuildContext context) {
    final list = videos.where((v) => v.channel == channel).toList();
    final levels = ({for (final v in list) v.level}.toList()..sort()).join(', ');
    final topics = {for (final v in list) v.topic}.join(', ');
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: IconButton(
                      tooltip: 'Назад',
                      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) => SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      if (i > 0) {
                        return VideoCard(list[i - 1], showChannel: false);
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            CreatorAvatar(channel, size: 64),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    channel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                      color: cText,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${list.length} ${_plural(list.length, 'ролик', 'ролика', 'роликов')} · $levels',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cMuted),
                                  ),
                                  Text(
                                    topics,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: cFaint),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

/// Кружок с первой буквой канала вместо аватарки.
class CreatorAvatar extends StatelessWidget {
  const CreatorAvatar(this.channel, {super.key, required this.size});
  final String channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: cAccent, shape: BoxShape.circle),
      child: Text(
        channel.characters.first.toUpperCase(),
        style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w800, height: 1, color: cInk),
      ),
    );
  }
}
