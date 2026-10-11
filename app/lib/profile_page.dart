import 'package:flutter/material.dart';

import 'auth_page.dart';
import 'store.dart';
import 'theme.dart';

// Вход замокан, поэтому и профиль тоже: имя берём из почты.
const _mockName = 'Аня Смирнова';

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
          PageTitle('Профиль'),
          SizedBox(height: 8),
          ..._body().map((w) => Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: w)),
        ],
      ),
    );
  }

  List<Widget> _body() {
    final email = store.user ?? mockEmail;
    final name = email == mockEmail ? _mockName : email.split('@').first;
    return [
      Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: cAccent,
            child: Text(
              name.characters.first.toUpperCase(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cInk),
            ),
          ),
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
      ),
      SizedBox(height: 18),
      _Group([
        _Row(
          icon: Icons.translate_rounded,
          title: 'Письмо',
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
          icon: Icons.dark_mode_outlined,
          title: 'Тёмная тема',
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
        _Row(icon: Icons.logout_rounded, title: 'Выйти', onTap: store.signOut),
      ]),
    ];
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
