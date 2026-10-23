import 'package:flutter/material.dart';

import 'store.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';
import 'l10n.dart';

/// Открывает историю просмотров поверх таббара.
void openHistory(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'HistoryPage'),
      builder: (_) => HistoryPage(),
    ),
  );
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  constraints: BoxConstraints(maxWidth: 720),
                  child: ListenableBuilder(
                    listenable: store,
                    builder: (context, _) {
                      // Сверху — открытые последними.
                      final list = store.history.reversed.map(videoById).nonNulls.toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PageTitle('${ui('История')}${list.isEmpty ? '' : ' · ${list.length}'}'),
                          Expanded(
                            child: list.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                                      child: Text(
                                        ui('Пока пусто. Здесь появятся ролики, которые ты открывала.'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                                    itemCount: list.length,
                                    separatorBuilder: (_, _) => SizedBox(height: 12),
                                    itemBuilder: (_, i) => VideoCard(list[i], key: ValueKey(list[i].id)),
                                  ),
                          ),
                        ],
                      );
                    },
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
