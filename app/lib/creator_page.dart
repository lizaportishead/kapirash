import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'feed_page.dart';
import 'icons.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';
import 'l10n.dart';

/// Открывает страницу креатора поверх таббара.
void openCreator(BuildContext context, String channel) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'CreatorPage'),
      builder: (_) => CreatorPage(channel: channel),
    ),
  );
}

class CreatorPage extends StatelessWidget {
  const CreatorPage({super.key, required this.channel});
  final String channel;

  @override
  Widget build(BuildContext context) {
    final list = videos.where((v) => v.channel == channel).toList();
    final topics = {for (final v in list) topicLabel(v.topic)}.join(', ');
    final url = creators[channel]?.url;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackBar(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                                    '${list.length} ${plural(list.length, 'ролик', 'ролика', 'роликов')}',
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
                            if (url != null)
                              IconButton(
                                tooltip: ui('Канал на YouTube'),
                                icon: Icon(KIcons.youtube, size: 26, color: cText),
                                onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (_, box) {
                            final cols = (box.maxWidth / 340).floor().clamp(1, 4);
                            final cardW = (box.maxWidth - 24 - 12 * (cols - 1)) / cols;
                            return GridView.builder(
                              padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: videoCardHeight(cardW),
                              ),
                              itemCount: list.length,
                              itemBuilder: (_, i) => VideoCard(list[i], showChannel: false),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Аватарка канала с YouTube; пока она грузится или если её нет — кружок с первой буквой.
class CreatorAvatar extends StatelessWidget {
  const CreatorAvatar(this.channel, {super.key, required this.size});
  final String channel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatar = creators[channel]?.avatar;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cAccent, shape: BoxShape.circle),
      child: avatar == null
          ? _letter()
          : Image.network(
              avatar,
              width: size,
              height: size,
              fit: BoxFit.cover,
              frameBuilder: (_, child, frame, _) => frame == null ? _letter() : child,
              errorBuilder: (_, _, _) => _letter(),
            ),
    );
  }

  Widget _letter() {
    return Text(
      channel.characters.first.toUpperCase(),
      style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w800, height: 1, color: cInk),
    );
  }
}
