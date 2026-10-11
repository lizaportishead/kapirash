import 'dart:math';

import 'package:flutter/material.dart';

import 'store.dart';
import 'theme.dart';

/// Открывает режим «Учить слова» поверх таббара.
void openLearn(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(builder: (_) => LearnPage()));
}

/// Карточки по сохранённым словам: переворачиваем, отвечаем «знаю» или «ещё учу».
/// Слова, которые ещё учим, возвращаются в конец колоды, пока не останется ни одного.
class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  late List<SavedWord> _queue;
  late int _total;
  bool _flipped = false;

  // Номер показа: одно и то же слово может вернуться, а карточке нужен новый ключ.
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _queue = [...store.words]..shuffle();
    _total = _queue.length;
    _flipped = false;
    _step++;
  }

  void _answer(bool known) => setState(() {
    final w = _queue.removeAt(0);
    if (!known) _queue.add(w);
    _flipped = false;
    _step++;
  });

  @override
  Widget build(BuildContext context) {
    final done = _total - _queue.length;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(4, 6, 16, 6),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Закрыть',
                        icon: Icon(Icons.close, size: 24, color: cText),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _total == 0 ? 0 : done / _total,
                            minHeight: 8,
                            backgroundColor: cCard2,
                            color: cViolet,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '$done / $_total',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _queue.isEmpty ? _finish() : _study(_queue.first)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _study(SavedWord w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
            // Свайп вправо — «знаю», влево — «ещё учу».
            child: Dismissible(
              key: ValueKey(_step),
              onDismissed: (d) => _answer(d == DismissDirection.startToEnd),
              child: _FlipCard(w, flipped: _flipped, onTap: () => setState(() => _flipped = !_flipped)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _flipped
              ? Row(
                  children: [
                    Expanded(
                      child: BigButton('Ещё учу', bg: cCard2, fg: cText, onTap: () => _answer(false)),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: BigButton('Знаю', bg: cAccent, fg: cInk, onTap: () => _answer(true)),
                    ),
                  ],
                )
              : BigButton('Показать перевод', onTap: () => setState(() => _flipped = true)),
        ),
      ],
    );
  }

  Widget _finish() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Готово!',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: cText),
                ),
                SizedBox(height: 8),
                Text(
                  'Повторено слов: $_total',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                ),
              ],
            ),
          ),
          BigButton('Ещё раз', bg: cCard2, fg: cText, onTap: () => setState(_restart)),
          SizedBox(height: 8),
          BigButton('Закончить', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

/// Карточка слова: спереди слово, на обороте — перевод и фраза из ролика.
class _FlipCard extends StatelessWidget {
  const _FlipCard(this.w, {required this.flipped, required this.onTap});
  final SavedWord w;
  final bool flipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final word = Text(
      store.conv(w.key),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: cText),
    );
    final front = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        word,
        Spacer(),
        Text(
          'Нажми, чтобы перевернуть',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFaint),
        ),
      ],
    );
    final back = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        word,
        if (w.tr.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            w.tr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cAccentText),
          ),
        ],
        if (w.ctx.isNotEmpty) ...[
          SizedBox(height: 20),
          Text(
            store.conv(w.ctx),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, height: 1.45, color: cMuted),
          ),
        ],
      ],
    );
    return Semantics(
      button: true,
      label: flipped ? null : 'Показать перевод',
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: flipped ? 1 : 0),
          duration: Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          builder: (_, v, _) {
            final showBack = v > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(pi * v),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(28)),
                // Оборот рисуем отзеркаленным, иначе текст после поворота читается задом наперёд.
                child: showBack ? Transform.flip(flipX: true, child: back) : front,
              ),
            );
          },
        ),
      ),
    );
  }
}
