import 'dart:math';

import 'package:flutter/material.dart';

import 'speak.dart';
import 'store.dart';
import 'theme.dart';
import 'l10n.dart';

/// Открывает режим «Учить слова» поверх таббара.
void openLearn(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(settings: RouteSettings(name: 'LearnPage'),builder: (_) => LearnPage()));
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
  var _swipe = GlobalKey<_SwipeCardState>();

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _queue = store.words.where((w) => !w.learned).toList()..shuffle();
    _total = _queue.length;
    _flipped = false;
    _swipe = GlobalKey<_SwipeCardState>();
  }

  void _answer(bool known) => setState(() {
    final w = _queue.removeAt(0);
    if (known) {
      store.setLearned(w.key, true);
    } else {
      _queue.add(w);
    }
    _flipped = false;
    _swipe = GlobalKey<_SwipeCardState>();
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
                        tooltip: ui('Закрыть'),
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
            child: _SwipeCard(
              key: _swipe,
              onSwiped: _answer,
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
                      child: BigButton(
                        ui('Ещё учу'),
                        bg: cCard2,
                        fg: cText,
                        onTap: () => _swipe.currentState?.fling(false),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: BigButton(
                        ui('Знаю'),
                        bg: cAccent,
                        fg: cInk,
                        onTap: () => _swipe.currentState?.fling(true),
                      ),
                    ),
                  ],
                )
              : BigButton(ui('Показать перевод'), onTap: () => setState(() => _flipped = true)),
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
                  ui('Готово!'),
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: cText),
                ),
                SizedBox(height: 8),
                Text(
                  ui('Повторено слов: {0}', [_total]),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                ),
              ],
            ),
          ),
          BigButton(ui('Ещё раз'), bg: cCard2, fg: cText, onTap: () => setState(_restart)),
          SizedBox(height: 8),
          BigButton(ui('Закончить'), onTap: () => Navigator.pop(context)),
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
    final head = w.lemma ?? w.key;
    final isForm = head != w.key;
    final tr = isForm && w.lemmaTr.isNotEmpty ? w.lemmaTr : w.tr;
    final word = Text(
      store.stressed(head),
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
          ui('Нажми, чтобы перевернуть'),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFaint),
        ),
      ],
    );
    final back = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        word,
        if (isForm) ...[
          SizedBox(height: 4),
          Text(
            store.stressed(w.key),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: cMuted),
          ),
        ],
        if (tr.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            tr,
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
      label: flipped ? null : ui('Показать перевод'),
      child: Stack(
        children: [
          Positioned.fill(
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
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              tooltip: ui('Прослушать {0}', [head]),
              icon: Icon(Icons.volume_up_rounded, size: 24, color: cViolet),
              onPressed: () => speakWord(head),
            ),
          ),
        ],
      ),
    );
  }
}

const _cKnow = Color(0xFF4CD964);
const _cAgain = Color(0xFFFF5A4D);

/// Карточка, которую можно утащить вправо («Знаю») или влево («Ещё учу»): наклоняется за пальцем,
/// рамка и подпись окрашиваются, а отпущенная далеко — улетает за край.
class _SwipeCard extends StatefulWidget {
  const _SwipeCard({super.key, required this.child, required this.onSwiped});
  final Widget child;
  final void Function(bool known) onSwiped;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this, duration: Duration(milliseconds: 260));
  double _dx = 0, _from = 0, _to = 0;
  double _width = 300;
  bool? _result;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() => setState(() => _dx = _from + (_to - _from) * Curves.easeOut.transform(_ctl.value)));
    _ctl.addStatusListener((s) {
      if (s == AnimationStatus.completed && _result != null) widget.onSwiped(_result!);
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _animateTo(double to) {
    _from = _dx;
    _to = to;
    _ctl.forward(from: 0);
  }

  /// Улетает за край с ответом [known]; зовётся и свайпом, и кнопками.
  void fling(bool known) {
    if (_result != null) return;
    _result = known;
    _animateTo((known ? 1 : -1) * _width * 1.4);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        _width = c.maxWidth;
        final p = (_dx / (_width * 0.35)).clamp(-1.0, 1.0);
        final color = p >= 0 ? _cKnow : _cAgain;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) {
            if (_result == null) setState(() => _dx += d.delta.dx);
          },
          onHorizontalDragEnd: (d) {
            if (_result != null) return;
            if (_dx.abs() > _width * 0.3 || d.velocity.pixelsPerSecond.dx.abs() > 700) {
              fling(_dx == 0 ? d.velocity.pixelsPerSecond.dx > 0 : _dx > 0);
            } else {
              _animateTo(0);
            }
          },
          child: Transform.translate(
            offset: Offset(_dx, 0),
            child: Transform.rotate(
              angle: _dx / _width * 0.35,
              child: Stack(
                children: [
                  widget.child,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: p.abs(),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Text(
                                p >= 0 ? ui('Знаю') : ui('Ещё учу'),
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
