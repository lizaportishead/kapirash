import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'icons.dart';
import 'player_page.dart' show SubPage;
import 'store.dart';
import 'theme.dart';

class QuizQuestion {
  QuizQuestion.fromJson(Map<String, dynamic> j)
    : task = j['t'] as String?,
      text = j['q'] as String,
      options = (j['o'] as List).cast<String>(),
      answer = j['a'] as int,
      why = j['e'] as String? ?? '';

  /// Что нужно сделать; у вопросов на понимание заданием служит сам вопрос.
  final String? task;

  /// Вопрос или фраза из ролика; слово между звёздочками подсвечено.
  final String text;
  final List<String> options;
  final int answer;

  /// Пояснение к правильному ответу — для разбора ошибок.
  final String why;
}

class QuizSection {
  QuizSection.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String,
      about = j['about'] as String? ?? '',
      icon = _icons[j['icon']] ?? KIcons.tasks,
      questions = [for (final q in j['questions'] as List) QuizQuestion.fromJson(q as Map<String, dynamic>)];
  final String title, about;
  final IconData icon;
  final List<QuizQuestion> questions;
}

/// Задания к ролику лежат в assets рядом с субтитрами; у большинства роликов их нет.
Future<List<QuizSection>> loadQuiz(String videoId) async {
  try {
    final j = jsonDecode(await rootBundle.loadString('assets/$videoId.quiz.json')) as Map<String, dynamic>;
    return [for (final s in j['sections'] as List) QuizSection.fromJson(s as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}

const _icons = {'idea': KIcons.idea, 'translate': KIcons.translate, 'puzzle': KIcons.puzzle};

const _cWrong = Color(0xFFFFCFC9);

/// Список заданий к ролику: карточка на раздел, на ней — пройден ли он и с каким результатом.
class QuizList extends StatelessWidget {
  const QuizList({super.key, required this.videoId, required this.sections, this.inline = false});
  // Внутри общей прокрутки страницы список сам не прокручивается.
  final bool inline;
  final String videoId;
  final List<QuizSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListView.separated(
        shrinkWrap: inline,
        physics: inline ? NeverScrollableScrollPhysics() : null,
        padding: inline
            ? EdgeInsets.only(top: 4)
            : EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.paddingOf(context).bottom),
        itemCount: sections.length,
        separatorBuilder: (_, _) => SizedBox(height: 8),
        itemBuilder: (context, i) => _card(context, sections[i]),
      ),
    );
  }

  Widget _card(BuildContext context, QuizSection s) {
    final r = store.quizResult(videoId, s.title);
    return Material(
      color: cCard,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SubPage(
              title: s.title,
              child: QuizPage(s, videoId: videoId),
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: cAccent, borderRadius: BorderRadius.circular(16)),
                child: Icon(s.icon, size: 26, color: cInk),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cText),
                    ),
                    if (s.about.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(s.about, style: TextStyle(fontSize: 13, height: 1.3, color: cMuted)),
                    ],
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (r != null) ...[Icon(KIcons.done, size: 16, color: cAccentText), SizedBox(width: 4)],
                        Text(
                          r == null ? 'Не пройдено · ${s.questions.length} вопросов' : 'Пройдено · ${r[0]} из ${r[1]}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: r == null ? cFaint : cAccentText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(KIcons.caretRight, size: 18, color: cFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Один раздел заданий: вопросы по одному, после ответа видно правильный вариант, в конце — счёт.
class QuizPage extends StatefulWidget {
  const QuizPage(this.section, {super.key, required this.videoId});
  final QuizSection section;
  final String videoId;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _i = 0;
  int? _picked;
  // Выбранные варианты по порядку вопросов — по ним собирается разбор ошибок.
  final _answers = <int>[];
  bool _review = false;

  List<QuizQuestion> get _qs => widget.section.questions;
  bool get _done => _i >= _qs.length;
  List<int> get _wrong => [
    for (var k = 0; k < _answers.length; k++)
      if (_answers[k] != _qs[k].answer) k,
  ];
  int get _right => _answers.length - _wrong.length;

  void _pick(int k) {
    if (_picked != null) return;
    setState(() {
      _picked = k;
      _answers.add(k);
    });
  }

  void _next() {
    setState(() {
      _i++;
      _picked = null;
    });
    if (_done) store.setQuizResult(widget.videoId, widget.section.title, _right, _qs.length);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 12 + MediaQuery.paddingOf(context).bottom;
    if (_review) return _mistakes(bottom);
    if (_done) return _result(bottom);
    final q = _qs[_i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (_i + (_picked == null ? 0 : 1)) / _qs.length,
                    minHeight: 6,
                    backgroundColor: cCard2,
                    color: cViolet,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                '${_i + 1} / ${_qs.length}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (q.task != null) ...[
                  Text(
                    q.task!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cMuted),
                  ),
                  SizedBox(height: 8),
                ],
                _question(q.text),
                SizedBox(height: 20),
                for (var k = 0; k < q.options.length; k++) ...[_option(q, k), SizedBox(height: 8)],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          child: BigButton(_i == _qs.length - 1 ? 'Результат' : 'Дальше', onTap: _picked == null ? null : _next),
        ),
      ],
    );
  }

  Widget _question(String text, {double size = 20}) {
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++)
            TextSpan(
              text: parts[i],
              style: i.isOdd ? TextStyle(backgroundColor: cAccent, color: cInk) : null,
            ),
        ],
      ),
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, height: 1.35, color: cText),
    );
  }

  Widget _option(QuizQuestion q, int k) {
    final answered = _picked != null;
    final right = answered && k == q.answer, wrong = answered && k == _picked && !right;
    final marked = right || wrong;
    return Semantics(
      button: true,
      label: right
          ? 'Верно'
          : wrong
          ? 'Неверно'
          : null,
      child: Material(
        color: right
            ? cAccent
            : wrong
            ? _cWrong
            : cCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: answered ? null : () => _pick(k),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    q.options[k],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      // Остальные варианты после ответа приглушены, чтобы взгляд шёл к правильному.
                      color: marked
                          ? cInk
                          : answered
                          ? cFaint
                          : cText,
                    ),
                  ),
                ),
                if (marked) ...[SizedBox(width: 8), Icon(right ? Icons.check : Icons.close, size: 18, color: cInk)],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _result(double bottom) {
    final all = _qs.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_right из $all',
                  style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: cText),
                ),
                SizedBox(height: 8),
                Text(
                  _right == all
                      ? 'Всё верно!'
                      : _right >= all * 0.7
                      ? 'Хороший результат'
                      : 'Пересмотри ролик и попробуй ещё раз',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: cMuted),
                ),
              ],
            ),
          ),
          // Главное действие — разбор, если есть что разбирать.
          if (_wrong.isNotEmpty) ...[
            BigButton('Разбор ошибок', onTap: () => setState(() => _review = true)),
            SizedBox(height: 8),
            BigButton('Закрыть', onTap: () => Navigator.pop(context), bg: cCard2, fg: cText),
          ] else
            BigButton('Закрыть', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _mistakes(double bottom) {
    final wrong = _wrong;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: wrong.length,
            separatorBuilder: (_, _) => SizedBox(height: 8),
            itemBuilder: (_, n) {
              final q = _qs[wrong[n]];
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Вопрос ${wrong[n] + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cFaint),
                    ),
                    SizedBox(height: 4),
                    _question(q.text, size: 16),
                    SizedBox(height: 12),
                    _answerRow(q.options[_answers[wrong[n]]], right: false),
                    SizedBox(height: 6),
                    _answerRow(q.options[q.answer], right: true),
                    if (q.why.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text(q.why, style: TextStyle(fontSize: 14, height: 1.45, color: cMuted)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          child: BigButton('Закрыть', onTap: () => Navigator.pop(context)),
        ),
      ],
    );
  }

  Widget _answerRow(String text, {required bool right}) {
    return Semantics(
      label: right ? 'Правильный ответ' : 'Твой ответ',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: right ? cAccent : _cWrong, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(right ? Icons.check : Icons.close, size: 16, color: cInk),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, color: cInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
