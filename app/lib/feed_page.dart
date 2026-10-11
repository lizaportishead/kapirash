import 'package:flutter/material.dart';

import 'search_page.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String? _topic;

  static final _topics = {for (final v in videos) v.topic}.toList();

  @override
  Widget build(BuildContext context) {
    final list = _topic == null ? videos : videos.where((v) => v.topic == _topic).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          'Каталог',
          actions: [
            IconButton(
              tooltip: 'Поиск',
              icon: Icon(Icons.search_rounded, size: 24, color: cText),
              onPressed: () => openSearch(context),
            ),
          ],
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            children: [
              Pill('Все', on: _topic == null, onTap: () => setState(() => _topic = null)),
              for (final t in _topics) ...[
                SizedBox(width: 6),
                Pill(t, on: _topic == t, onTap: () => setState(() => _topic = _topic == t ? null : t)),
              ],
            ],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: list.length,
            separatorBuilder: (_, _) => SizedBox(height: 12),
            itemBuilder: (_, i) => VideoCard(list[i]),
          ),
        ),
      ],
    );
  }
}
