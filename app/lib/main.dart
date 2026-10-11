import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'add_video.dart';
import 'auth_page.dart';
import 'feed_page.dart';
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
  int _stage = _stageNow;

  // Что показываем: онбординг, вход или само приложение.
  static int get _stageNow => !store.onboarded
      ? 0
      : store.user == null
      ? 1
      : 2;

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
    if (_stageNow != _stage) setState(() => _stage = _stageNow);
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
        child: switch (_stage) {
          0 => OnboardingPage(),
          1 => AuthPage(),
          _ => HomeShell(),
        },
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  // В середине таббара — пустая ячейка под кнопку «плюс», поэтому индексы справа от неё сдвинуты.
  static const _plus = 2;

  Future<void> _addVideo() async {
    if (await showAddVideo(context) && mounted) setState(() => _tab = 1);
  }

  Widget _wordsIcon(IconData icon) => ListenableBuilder(
    listenable: store,
    builder: (_, _) => Badge(
      isLabelVisible: store.words.isNotEmpty,
      backgroundColor: cText,
      textColor: cBg,
      label: Text('${store.words.length}'),
      child: Icon(icon),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: IndexedStack(index: _tab, children: [FeedPage(), MyVideosPage(), WordsPage(), ProfilePage()]),
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
                fontWeight: FontWeight.w700,
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
                    icon: Icon(PhosphorIconsLight.squaresFour),
                    selectedIcon: Icon(PhosphorIconsRegular.squaresFour),
                    label: 'Каталог',
                  ),
                  NavigationDestination(
                    icon: Icon(PhosphorIconsLight.filmSlate),
                    selectedIcon: Icon(PhosphorIconsRegular.filmSlate),
                    label: 'Мои ролики',
                  ),
                  ExcludeSemantics(
                    child: NavigationDestination(icon: SizedBox(width: 24, height: 24), label: ''),
                  ),
                  NavigationDestination(
                    icon: _wordsIcon(PhosphorIconsLight.bookmarkSimple),
                    selectedIcon: _wordsIcon(PhosphorIconsRegular.bookmarkSimple),
                    label: 'Мои слова',
                  ),
                  NavigationDestination(
                    icon: Icon(PhosphorIconsLight.user),
                    selectedIcon: Icon(PhosphorIconsRegular.user),
                    label: 'Профиль',
                  ),
                ],
              ),
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
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(PhosphorIconsRegular.plus, size: 26, color: cOnViolet),
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
  }
}
