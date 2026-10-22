import 'package:flutter/material.dart';

import 'icons.dart';
import 'recommend.dart';
import 'store.dart';
import 'theme.dart';
import 'l10n.dart';

Map<String, (String, String, String)> get _levelInfo => {
  'A': (ui('Знаю основы'), 'A2', ui('Знаю базовые слова и простые фразы. Нужны короткие ролики и неспешная речь.')),
  'B1': (
    ui('Могу объясниться'),
    'B1',
    ui('Понимаю суть, когда говорят неспешно и о знакомом. Не хватает слов, чтобы следить за всем.'),
  ),
  'B2': (ui('Понимаю почти всё'), 'B2+', ui('Смотрю без подготовки. Хочу живую речь, сленг и тонкости.')),
};

/// Анкета после онбординга: уровень и темы. Первый раз показывается вместо каталога, из профиля открывается поверх него.
class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key, this.edit = false});

  /// Открыта из профиля: закрывается обратно, а не сменяет собой весь экран.
  final bool edit;

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

/// Открывает анкету из профиля или с главной, чтобы поменять ответы.
void openSurvey(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SurveyPage(edit: true)));
}

class _SurveyPageState extends State<SurveyPage> {
  int _step = 0;
  late String? _level = store.level;
  late final Set<String> _topics = {...store.interests};
  final _all = catalogTopics();

  void _skip() {
    if (widget.edit) return Navigator.pop(context);
    store.finishSurvey();
  }

  void _next() {
    if (_step == 0) return setState(() => _step = 1);
    store.finishSurvey(level: _level, interests: _topics.toList());
    if (widget.edit) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.edit || _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Row(
                      children: [
                        if (_step == 1)
                          IconButton(
                            tooltip: ui('Назад'),
                            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                            onPressed: () => setState(() => _step = 0),
                          ),
                        Spacer(),
                        TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: cText,
                            textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          child: Text(widget.edit ? ui('Закрыть') : ui('Пропустить')),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Row(
                      children: [
                        for (var i = 0; i < 2; i++)
                          Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
                              decoration: BoxDecoration(
                                color: i <= _step ? cViolet : cLine,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: KeyedSubtree(key: ValueKey(_step), child: _step == 0 ? _levelStep() : _topicStep()),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: BigButton(
                      _step == 0 ? ui('Дальше') : ui('Готово'),
                      onTap: _step == 0 && _level == null ? null : _next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Semantics(
    header: true,
    child: Text(
      text,
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5, color: cText),
    ),
  );

  Widget _levelStep() {
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      children: [
        _title(ui('Какой у тебя уровень?')),
        SizedBox(height: 10),
        Text(
          ui('Подберём ролики, которые можно понять. Поменять ответ можно в любой момент.'),
          style: TextStyle(fontSize: 15, height: 1.4, color: cMuted),
        ),
        SizedBox(height: 20),
        for (final l in surveyLevels) ...[
          _LevelCard(l, selected: _level == l, onTap: () => setState(() => _level = l)),
          SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _topicStep() {
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      children: [
        _title(ui('Что тебе интересно?')),
        SizedBox(height: 10),
        Text(
          ui('Выбери любые темы — их ролики окажутся наверху. Можно не выбирать ничего.'),
          style: TextStyle(fontSize: 15, height: 1.4, color: cMuted),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _all)
              Pill(
                topicLabel(t),
                on: _topics.contains(t),
                icon: _topics.contains(t) ? KIcons.done : null,
                onTap: () => setState(() => _topics.contains(t) ? _topics.remove(t) : _topics.add(t)),
              ),
          ],
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard(this.level, {required this.selected, required this.onTap});
  final String level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (title, tag, text) = _levelInfo[level]!;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? cViolet.withValues(alpha: 0.1) : cCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: selected ? cViolet : Colors.transparent, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cText),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: cAccent, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        tag,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cInk),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(text, style: TextStyle(fontSize: 14, height: 1.4, color: cMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
