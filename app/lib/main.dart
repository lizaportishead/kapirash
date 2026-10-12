import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'add_video.dart';
import 'feed_page.dart';
import 'icons.dart';
import 'my_videos_page.dart';
import 'onboarding_page.dart';
import 'profile_page.dart';
import 'store.dart';
import 'theme.dart';
import 'words_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        // Вход необязателен: после онбординга сразу каталог, войти можно из профиля.
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

  Future<void> _addVideo() async {
    if (await showAddVideo(context) && mounted) setState(() => _tab = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: IndexedStack(
              index: _tab,
              children: [FeedPage(), if (kAddVideoEnabled) MyVideosPage(), WordsPage(), ProfilePage()],
            ),
          ),
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
                onDestinationSelected: (i) => i == _plus ? _addVideo() : setState(() => _tab = i < _plus ? i : i - 1),
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
}
