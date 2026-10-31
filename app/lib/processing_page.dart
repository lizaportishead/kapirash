import 'dart:async';

import 'package:flutter/material.dart';

import 'kap_loader.dart';
import 'player_page.dart';
import 'store.dart';
import 'theme.dart';
import 'videos.dart';
import 'l10n.dart';

/// Сколько обычно готовится ролик, минут: очередь проверяется раз в 5 минут, распознавание идёт примерно в реальном времени.
/// Точнее сказать нельзя: длина ролика заранее неизвестна.
const kSubsEtaMinutes = 30;

/// Экран своего ролика, пока он не готов: статус, лоадер и примерное время. Его можно закрыть —
/// подготовка идёт дальше, а ролик лежит в каталоге в «Моих роликах» и откроется, когда будет готов.
void openProcessing(BuildContext context, Video v) {
  Navigator.of(context).push(MaterialPageRoute<void>(settings: RouteSettings(name: 'ProcessingPage'),builder: (_) => ProcessingPage(v)));
}

class ProcessingPage extends StatefulWidget {
  const ProcessingPage(this.video, {super.key});
  final Video video;

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Оставшееся время считается от часов, поэтому экран обновляется и без событий от store.
    _tick = Timer.periodic(Duration(seconds: 20), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _eta(MyVideo m) {
    final left = kSubsEtaMinutes - DateTime.now().difference(m.added).inMinutes;
    if (left <= 0) return ui('Занимает чуть дольше обычного — ещё немного');
    return ui('Осталось примерно {0}', ['$left ${plural(left, 'минута', 'минуты', 'минут')}']);
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: Text(ui('Отменить?'), style: TextStyle(fontWeight: FontWeight.w800, color: cText)),
        content: Text(
          ui('Ролик пропадёт из «Моих роликов». Добавить его можно будет заново.'),
          style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ui('Нет'), style: TextStyle(color: cText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ui('Отменить'), style: TextStyle(fontWeight: FontWeight.w800, color: cAccentText)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    store.removeVideo(widget.video.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560),
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final m = store.myVideo(v.id);
                final status = m?.status ?? SubsStatus.failed;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8, top: 4),
                        child: IconButton(
                          tooltip: ui('Закрыть'),
                          icon: Icon(Icons.close_rounded, size: 26, color: cText),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ColoredBox(
                                color: cInk,
                                child: Opacity(
                                  opacity: status == SubsStatus.ready ? 1 : 0.55,
                                  child: Image.network(
                                    'https://i.ytimg.com/vi/${v.id}/hqdefault.jpg',
                                    fit: BoxFit.cover,
                                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                                    errorBuilder: (_, _, _) => SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            v.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25, color: cText),
                          ),
                          SizedBox(height: 4),
                          Text(v.channel, style: TextStyle(fontSize: 14, color: cMuted)),
                          SizedBox(height: 32),
                          Center(
                            child: switch (status) {
                              SubsStatus.processing => KapLoader(size: 64),
                              SubsStatus.ready => Icon(Icons.check_circle_rounded, size: 64, color: cViolet),
                              SubsStatus.failed => Icon(Icons.error_outline_rounded, size: 64, color: cMuted),
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            switch (status) {
                              SubsStatus.processing => ui('Готовим субтитры'),
                              SubsStatus.ready => ui('Ролик готов'),
                              SubsStatus.failed => ui('Не получилось подготовить'),
                            },
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: cText),
                          ),
                          SizedBox(height: 8),
                          Text(
                            switch (status) {
                              SubsStatus.processing =>
                                '${m == null ? '' : '${_eta(m)}. '}${ui('Распознаём речь, переводим и собираем словарик. Окно можно закрыть: ролик будет в каталоге, в разделе «Мои ролики», и откроется, когда будет готов.')}',
                              SubsStatus.ready => ui('Субтитры, перевод и словарик на месте.'),
                              SubsStatus.failed => '${m?.error == null ? '' : '${m!.error}\n\n'}${ui('Попробуй ещё раз. Если опять не выйдет — ролик можно удалить и добавить заново.')}',
                            },
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                          ),
                          SizedBox(height: 24),
                          if (status == SubsStatus.ready)
                            BigButton(
                              ui('Смотреть'),
                              onTap: () {
                                Navigator.pop(context);
                                openVideo(context, v);
                              },
                            )
                          else if (status == SubsStatus.failed)
                            BigButton(ui('Повторить'), onTap: () => store.generateSubs(v.id))
                          else
                            BigButton(ui('Закрыть'), onTap: () => Navigator.pop(context)),
                          if (status != SubsStatus.ready)
                            TextButton(
                              onPressed: _cancel,
                              child: Text(ui('Отменить и удалить'), style: TextStyle(color: cMuted)),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
