import 'package:flutter/material.dart';

import 'auth_page.dart';
import 'history_page.dart';
import 'store.dart';
import 'survey_page.dart';
import 'theme.dart';
import 'l10n.dart';
import 'legal.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListView(
        padding: EdgeInsets.only(bottom: 24),
        children: [
          PageTitle(ui('Профиль')),
          SizedBox(height: 8),
          ..._body().map((w) => Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: w)),
        ],
      ),
    );
  }

  List<Widget> _body() {
    final email = store.user;
    return [
      if (email == null) _SignIn() else _account(email),
      SizedBox(height: 18),
      // Карточки с фактами пока скрыты: _stats().
      _Group([
        _Row(
          icon: Icons.translate_rounded,
          title: ui('Письмо'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pill('Lat', on: !store.cyr, onTap: () => store.setCyr(false)),
              SizedBox(width: 6),
              Pill('Ћир', on: store.cyr, onTap: () => store.setCyr(true)),
            ],
          ),
        ),
        _Row(
          icon: Icons.language_rounded,
          title: ui('Язык'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pill('Русский', on: store.lang == 'ru', onTap: () => store.setLang('ru')),
              SizedBox(width: 6),
              Pill('English', on: store.lang == 'en', onTap: () => store.setLang('en')),
            ],
          ),
        ),
        _Row(
          icon: Icons.dark_mode_outlined,
          title: ui('Тёмная тема'),
          trailing: Switch(
            value: store.dark,
            activeThumbColor: cOnViolet,
            activeTrackColor: cViolet,
            onChanged: store.setDark,
          ),
        ),
      ]),
      SizedBox(height: 12),
      _Group([
        _Row(icon: Icons.tune_rounded, title: ui('Уровень и темы'), onTap: () => openSurvey(context)),
        _Row(icon: Icons.history_rounded, title: ui('История'), onTap: () => openHistory(context)),
      ]),
      SizedBox(height: 12),
      _Group([
        _Row(icon: Icons.privacy_tip_outlined, title: ui('Политика конфиденциальности'), onTap: openPrivacy),
        _Row(icon: Icons.description_outlined, title: ui('Условия использования'), onTap: openTerms),
      ]),
      if (email != null) ...[
        SizedBox(height: 12),
        _Group([
          _Row(icon: Icons.logout_rounded, title: ui('Выйти'), onTap: store.signOut),
          _Row(icon: Icons.delete_outline_rounded, title: ui('Удалить аккаунт'), onTap: _confirmDelete),
        ]),
      ],
    ];
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(ui('Удалить аккаунт?')),
        content: Text(ui('Аккаунт и данные в облаке будут удалены без возможности восстановления. Слова и прогресс на этом устройстве останутся.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(ui('Отмена'))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(ui('Удалить')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await store.deleteAccount();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ui('Не получилось удалить аккаунт. Напиши на info@kapiras.app'))));
    }
  }

  // ignore: unused_element
  Widget _stats() {
    const tags = {'A': 'A2', 'B1': 'B1', 'B2': 'B2+'};
    final tasks = store.quiz.length;
    return Row(
      children: [
        Expanded(child: _Stat(tags[store.level] ?? '—', ui('уровень'))),
        SizedBox(width: 8),
        Expanded(child: _Stat('$tasks', ui('заданий выполнено'))),
        SizedBox(width: 8),
        Expanded(child: _Stat('${store.words.length}', ui('слов добавлено'))),
      ],
    );
  }

  Widget _account(String email) {
    // Без имени в аккаунте берём его из почты.
    final name = store.fullName ?? email.split('@').first;
    return Row(
      children: [
        ProfileAvatar(radius: 32),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: cText),
              ),
              SizedBox(height: 2),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: cMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Блок для тех, кто не вошёл: вход необязателен, поэтому зовём, а не требуем.
class _SignIn extends StatelessWidget {
  const _SignIn();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final title = Text(
      ui('Войди в\u00A0аккаунт'),
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: cInk),
    );
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: cAccent, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: cInk.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.person_rounded, size: 26, color: cInk),
                ),
                SizedBox(width: 12),
                Expanded(child: title),
                SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: cViolet,
                      foregroundColor: cOnViolet,
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      shape: StadiumBorder(),
                      textStyle: TextStyle(fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => openAuth(context),
                    child: Text(ui('Войти')),
                  ),
                ),
              ],
            )
          else
            title,
          SizedBox(height: wide ? 12 : 6),
          Text(
            ui(
              'Слова, лайки, история и прогресс сохранятся в облаке и не пропадут, если сменишь телефон или '
              'переустановишь приложение.',
            ),
            style: TextStyle(fontSize: 14, height: 1.4, color: cInk),
          ),
          if (!wide) ...[
            SizedBox(height: 16),
            BigButton(ui('Войти'), onTap: () => openAuth(context)),
          ],
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.rows);
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cCard,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) Divider(height: 1, indent: 52, color: cLine), rows[i]],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.trailing, this.onTap});
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 56),
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cMuted),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cText),
              ),
            ),
            ?trailing,
            if (trailing == null && onTap != null)
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.chevron_right_rounded, size: 20, color: cFaint),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: cText),
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.25, color: cMuted),
          ),
        ],
      ),
    );
  }
}

/// Фото из аккаунта Google, а без него инициал; пустой, пока не вошли.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = store.avatarUrl;
    final name = store.fullName ?? store.user?.split('@').first ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: cAccent,
      // Буква остаётся под фото: видна, пока оно грузится или если не загрузилось.
      foregroundImage: photo == null ? null : NetworkImage(photo),
      onForegroundImageError: photo == null ? null : (_, _) {},
      child: Text(
        name.isEmpty ? '' : name.characters.first.toUpperCase(),
        style: TextStyle(fontSize: radius * 0.875, fontWeight: FontWeight.w800, color: cInk),
      ),
    );
  }
}
