import 'package:flutter/material.dart';

import 'deep_link.dart';
import 'l10n.dart';
import 'store.dart';
import 'theme.dart';

/// Открывает таблицу лидеров поверх таббара.
void openLeaderboard(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: urlSettings('LeaderboardPage', '/leaderboard'),
      builder: (_) => LeaderboardPage(),
    ),
  );
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<LeaderRow>?> _rows = store.fetchLeaderboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...pageHeader(context, ui('Рейтинг')),
                Expanded(
                  child: FutureBuilder<List<LeaderRow>?>(
                    future: _rows,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return Center(child: CircularProgressIndicator(color: cViolet));
                      }
                      final rows = snap.data;
                      if (rows == null || rows.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              rows == null
                                  ? ui('Не получилось загрузить рейтинг. Попробуй позже.')
                                  : ui('Пока никого нет. Выполни задание, чтобы попасть в рейтинг.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                            ),
                          ),
                        );
                      }
                      return ListView(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          Container(
                            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(8)),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                _line(ui('Место'), null, ui('Ролики'), ui('Заданий'), null, head: true),
                                for (final r in rows) _line('${r.rank}', r, '${r.videos}', '${r.tasks}', r, me: r.isMe),
                              ],
                            ),
                          ),
                        ],
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

  static const _tags = {'A': 'A2', 'B1': 'B1', 'B2': 'B2+'};
  static const _tagColors = {'A': Color(0xFF1FA971), 'B2': Color(0xFFE8890C)};

  /// Строка таблицы; в шапке [who] и [lvl] пусты, и подписи берутся из текста.
  Widget _line(
    String rank,
    LeaderRow? who,
    String videos,
    String tasks,
    LeaderRow? lvl, {
    bool head = false,
    bool me = false,
  }) {
    final style = TextStyle(
      fontSize: head ? 12 : 14,
      fontWeight: head || me ? FontWeight.w700 : FontWeight.w500,
      color: head ? cMuted : cText,
    );
    Widget cell(String t, double w, {TextAlign a = TextAlign.right}) => SizedBox(
      width: w,
      child: Text(t, textAlign: a, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
    );
    Widget name() {
      if (who == null) return Text(ui('Имя'), style: style);
      final initial = who.name.characters.first.toUpperCase();
      return Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: cAccent,
            // Буква остаётся под фото: видна, пока оно грузится или если не загрузилось.
            foregroundImage: who.avatar == null ? null : NetworkImage(who.avatar!),
            onForegroundImageError: who.avatar == null ? null : (_, _) {},
            child: Text(
              initial,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cInk),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(who.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
        ],
      );
    }

    Widget level() {
      if (lvl == null) return Text(ui('Уровень'), style: style);
      final tag = _tags[lvl.level];
      if (tag == null) return Text('—', style: style);
      final c = _tagColors[lvl.level] ?? cViolet;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(
          tag,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c),
        ),
      );
    }

    return Container(
      color: me ? cViolet.withValues(alpha: 0.12) : null,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: head ? 10 : 9),
      decoration: head
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: cLine)),
            )
          : null,
      child: Row(
        children: [
          cell(rank, 48, a: TextAlign.left),
          Expanded(child: name()),
          cell(videos, 64),
          cell(tasks, 72),
          SizedBox(
            width: 84,
            child: Align(alignment: Alignment.centerRight, child: level()),
          ),
        ],
      ),
    );
  }
}
