import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_video.dart';
import 'clips_page.dart';
import 'feed_page.dart';
import 'icons.dart';
import 'my_videos_page.dart';
import 'onboarding_page.dart';
import 'profile_page.dart';
import 'stories_page.dart';
import 'store.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'words_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    cloud = Supabase.instance.client;
  }
  await store.load();
  runApp(KapirasApp());
}

class KapirasApp extends StatefulWidget {
  const KapirasApp({super.key});

  @override
  State<KapirasApp> createState() => _KapirasAppState();
}

class _KapirasAppState extends State<KapirasApp> {
  bool _dark = store.dark;
  bool _onboarded = store.onboarded;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  // Цвета в theme.dart — глобальные геттеры, поэтому при смене темы перестраиваем всё дерево,
  // включая const-виджеты и открытые поверх экраны.
  void _onStore() {
    if (store.onboarded != _onboarded) setState(() => _onboarded = store.onboarded);
    if (store.dark == _dark) return;
    setState(() => _dark = store.dark);
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    context.visitChildElements(visit);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kapiraš',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _dark ? Brightness.dark : Brightness.light,
        fontFamily: kFont,
        scaffoldBackgroundColor: cBg,
        colorScheme: _dark
            ? ColorScheme.dark(primary: cViolet, onPrimary: cOnViolet, surface: cCard2, onSurface: cText)
            : ColorScheme.light(primary: cViolet, onPrimary: cOnViolet, surface: cCard2, onSurface: cText),
      ),
      builder: (_, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: child!,
      ),
      home: AnimatedSwitcher(
        duration: Duration(milliseconds: 250),
        // Вход необязателен: после онбординга поверх каталога один раз зовём войти, позже — из профиля.
        child: _onboarded ? HomeShell() : OnboardingPage(),
      ),
    );
  }
}

/// Добавление своих роликов временно скрыто: без него нет ни кнопки «плюс», ни вкладки «Мои ролики».
const kAddVideoEnabled = false;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  // В середине таббара — пустая ячейка под кнопку «плюс», поэтому индексы справа от неё сдвинуты.
  // Пока добавление скрыто, ячейки нет и сдвигать нечего.
  static const _plus = kAddVideoEnabled ? 2 : 99;

  static const _profile = kAddVideoEnabled ? 5 : 4;

  // Пасхалка: три быстрых тапа по вкладке «Профиль» заново открывают онбординг.
  int _profileTaps = 0;
  DateTime _lastProfileTap = DateTime(0);

  void _select(int tab) {
    final now = DateTime.now();
    _profileTaps = tab == _profile && now.difference(_lastProfileTap) < Duration(milliseconds: 500)
        ? _profileTaps + 1
        : (tab == _profile ? 1 : 0);
    _lastProfileTap = now;
    if (_profileTaps == 3) return store.replayOnboarding();
    setState(() => _tab = tab);
  }

  Future<void> _addVideo() async {
    if (await showAddVideo(context) && mounted) setState(() => _tab = 1);
  }

  @override
  Widget build(BuildContext context) {
    // Десктоп и широкий планшет: меню слева, контент шире. Телефон: таббар снизу.
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = IndexedStack(
      index: _tab,
      children: [
        FeedPage(),
        if (kAddVideoEnabled) MyVideosPage(),
        ClipsPage(),
        StoriesPage(),
        WordsPage(),
        ProfilePage(),
      ],
    );
    if (wide) return _wideShell(pages);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 720), child: pages),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cLine)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: cBg,
            indicatorColor: cAccent,
            height: 64,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (s) => TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: s.contains(WidgetState.selected) ? cText : cFaint,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (s) => IconThemeData(color: s.contains(WidgetState.selected) ? cInk : cFaint),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              NavigationBar(
                selectedIndex: _tab < _plus ? _tab : _tab + 1,
                onDestinationSelected: (i) => i == _plus ? _addVideo() : _select(i < _plus ? i : i - 1),
                destinations: [
                  NavigationDestination(
                    icon: Icon(KIcons.catalog),
                    selectedIcon: Icon(KIcons.catalogOn),
                    label: 'Каталог',
                  ),
                  if (kAddVideoEnabled) ...[
                    NavigationDestination(
                      icon: Icon(KIcons.videos),
                      selectedIcon: Icon(KIcons.videosOn),
                      label: 'Мои ролики',
                    ),
                    ExcludeSemantics(
                      child: NavigationDestination(icon: SizedBox(width: 24, height: 24), label: ''),
                    ),
                  ],
                  NavigationDestination(icon: Icon(KIcons.clips), selectedIcon: Icon(KIcons.clipsOn), label: 'Клипы'),
                  NavigationDestination(
                    icon: Icon(KIcons.stories),
                    selectedIcon: Icon(KIcons.storiesOn),
                    label: 'Рассказы',
                  ),
                  NavigationDestination(
                    icon: Icon(KIcons.words),
                    selectedIcon: Icon(KIcons.wordsOn),
                    label: 'Мои слова',
                  ),
                  NavigationDestination(
                    icon: Icon(KIcons.profile),
                    selectedIcon: Icon(KIcons.profileOn),
                    label: 'Профиль',
                  ),
                ],
              ),
              if (kAddVideoEnabled)
                SafeArea(
                  top: false,
                  child: Semantics(
                    button: true,
                    label: 'Добавить ролик',
                    child: Material(
                      color: cViolet,
                      shape: CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _addVideo,
                        child: SizedBox(width: 52, height: 52, child: Icon(KIcons.plus, size: 26, color: cOnViolet)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wideShell(Widget pages) {
    final items = <(int, IconData, IconData, String)>[
      (0, KIcons.catalog, KIcons.catalogOn, 'Каталог'),
      if (kAddVideoEnabled) (1, KIcons.videos, KIcons.videosOn, 'Мои ролики'),
      (kAddVideoEnabled ? 2 : 1, KIcons.clips, KIcons.clipsOn, 'Клипы'),
      (kAddVideoEnabled ? 3 : 2, KIcons.stories, KIcons.storiesOn, 'Рассказы'),
      (kAddVideoEnabled ? 4 : 3, KIcons.words, KIcons.wordsOn, 'Мои слова'),
    ];
    final profile = (_profile, KIcons.profile, KIcons.profileOn, 'Профиль');
    Widget item((int, IconData, IconData, String) it) {
      final (page, icon, on, label) = it;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: _tab == page ? cAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _select(page),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(_tab == page ? on : icon, size: 26, color: _tab == page ? cInk : cMuted),
                  SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: _tab == page ? FontWeight.w700 : FontWeight.w500,
                      color: _tab == page ? cText : cMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: cLine)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(28, 24, 20, 20),
                    child: Text(
                      'Kapiraš',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1, color: cViolet),
                    ),
                  ),
                  Divider(height: 1, color: cLine),
                  SizedBox(height: 12),
                  for (final it in items) item(it),
                  if (kAddVideoEnabled)
                    Padding(
                      padding: EdgeInsets.fromLTRB(12, 16, 12, 0),
                      child: FilledButton.icon(
                        onPressed: _addVideo,
                        style: FilledButton.styleFrom(backgroundColor: cViolet, foregroundColor: cOnViolet),
                        icon: Icon(KIcons.plus),
                        label: Text('Добавить ролик'),
                      ),
                    ),
                  Spacer(),
                  item(profile),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 1200), child: pages),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
