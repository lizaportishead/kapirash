import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_video.dart';
import 'analytics.dart';
import 'feed_page.dart';
import 'home_page.dart';
import 'icons.dart';
import 'install_banner.dart';
import 'kap_loader.dart';
import 'auth_page.dart';
import 'my_videos_page.dart';
import 'onboarding_page.dart';
import 'profile_page.dart';
import 'podcasts_page.dart';
import 'stories_page.dart';
import 'store.dart';
import 'survey_page.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'words_page.dart';
import 'l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Пока поднимаем облако и читаем сохранённое, показываем лоадер вместо пустого экрана.
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
            ? Color(0xFF0E0E12)
            : Color(0xFFFFFFFF),
        child: KapLoading(size: 96),
      ),
    ),
  );
  if (supabaseKey.isNotEmpty) {
    // После входа через Google initialize ждёт обмена кода из ссылки на сессию; если запрос завис или упал,
    // не держим заставку вечно: клиент уже создан, а сессия подхватится позже через onAuthStateChange.
    final init = Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    try {
      await init.timeout(Duration(seconds: 8));
    } catch (e) {
      debugPrint('Supabase init: $e');
      unawaited(init.then<void>((_) {}, onError: (_) {}));
    }
    cloud = Supabase.instance.client;
  }
  await store.load();
  await initAnalytics();
  identifyUser(cloud?.auth.currentUser?.id);
  runApp(KapirasApp());
}

class KapirasApp extends StatefulWidget {
  const KapirasApp({super.key});

  @override
  State<KapirasApp> createState() => _KapirasAppState();
}

class _KapirasAppState extends State<KapirasApp> {
  bool _dark = store.dark;
  String _lang = store.lang;
  bool _onboarded = store.onboarded;
  bool _surveyDone = store.surveyDone;

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

  // Цвета в theme.dart и тексты из ui() — глобальные, поэтому при смене темы или языка перестраиваем всё дерево,
  // включая const-виджеты и открытые поверх экраны.
  void _onStore() {
    if (store.onboarded != _onboarded) setState(() => _onboarded = store.onboarded);
    if (store.surveyDone != _surveyDone) setState(() => _surveyDone = store.surveyDone);
    if (store.dark == _dark && store.lang == _lang) return;
    setState(() {
      _dark = store.dark;
      _lang = store.lang;
    });
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
      navigatorObservers: analyticsObservers(),
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
        // Порядок: приветствие, предложение войти (поверх), анкета, потом приложение.
        child: !_onboarded
            ? (kIsWeb ? _WebStart() : OnboardingPage())
            : !_surveyDone
            ? SurveyPage()
            : HomeShell(),
      ),
    );
  }
}

/// Старт веба: на телефоне (PWA) сначала три слайда, потом вход; на широком экране вход со слайдами сбоку.
class _WebStart extends StatefulWidget {
  const _WebStart();

  static bool slidesSeen = false;

  @override
  State<_WebStart> createState() => _WebStartState();
}

class _WebStartState extends State<_WebStart> {
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 1100;
    if (narrow && !_WebStart.slidesSeen && store.user == null) {
      return OnboardingPage(onDone: () => setState(() => _WebStart.slidesSeen = true));
    }
    return AuthPage(intro: true, start: true);
  }
}

/// Добавление своих роликов временно скрыто: без него нет ни кнопки «плюс», ни вкладки «Мои ролики».
const kAddVideoEnabled = false;

/// Вкладка «Рассказы» (книги) в меню; если выключить, рассказы открываются только из «Моих слов».
const kStoriesTabEnabled = true;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _tabN = ValueNotifier<int>(0);
  final _navKey = GlobalKey<NavigatorState>();
  int get _tab => _tabN.value;
  set _tab(int v) => _tabN.value = v;

  // В середине таббара — пустая ячейка под кнопку «плюс», поэтому индексы справа от неё сдвинуты.
  // Пока добавление скрыто, ячейки нет и сдвигать нечего.
  static const _home = 0, _feed = 1;
  static const _plus = kAddVideoEnabled ? 3 : 99;
  static const _first = kAddVideoEnabled ? 3 : 2;
  static const _stories = kStoriesTabEnabled ? _first : 99;
  static const _podcasts = _first + (kStoriesTabEnabled ? 1 : 0);
  static const _words = _podcasts + 1;
  static const _profile = _podcasts + 2;

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
    _navKey.currentState?.popUntil((r) => r.isFirst);
    setState(() => _tab = tab);
    trackScreen(_tabName(tab));
  }

  String _tabName(int t) => t == _home
      ? 'Home'
      : t == _feed
      ? 'Feed'
      : t == _stories
      ? 'Stories'
      : t == _podcasts
      ? 'Podcasts'
      : t == _words
      ? 'Words'
      : t == _profile
      ? 'Profile'
      : 'Tab$t';

  @override
  void initState() {
    super.initState();
    trackScreen(_tabName(_tab));
  }

  Future<void> _addVideo() async {
    await showAddVideo(context);
  }

  @override
  Widget build(BuildContext context) {
    // Десктоп и широкий планшет: меню слева, контент шире. Телефон: таббар снизу.
    final wide = MediaQuery.sizeOf(context).width >= 900;
    Widget buildPages() => IndexedStack(
      index: _tab,
      children: [
        HomePage(
          onVideos: () => _select(_feed),
          onStories: () => _select(_stories),
          onPodcasts: () => _select(_podcasts),
        ),
        FeedPage(),
        if (kAddVideoEnabled) MyVideosPage(),
        if (kStoriesTabEnabled) StoriesPage(),
        PodcastsPage(),
        WordsPage(),
        ProfilePage(),
      ],
    );
    if (wide) return _wideShell(buildPages);
    final pages = buildPages();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(child: pages),
                InstallBanner(),
              ],
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
                onDestinationSelected: (i) => i == _plus ? _addVideo() : _select(i < _plus ? i : i - 1),
                destinations: [
                  NavigationDestination(
                    icon: Icon(KIcons.home),
                    selectedIcon: Icon(KIcons.homeOn),
                    label: ui('Главная'),
                  ),
                  NavigationDestination(
                    icon: Icon(KIcons.catalog),
                    selectedIcon: Icon(KIcons.catalogOn),
                    label: ui('Видео'),
                  ),
                  if (kAddVideoEnabled) ...[
                    NavigationDestination(
                      icon: Icon(KIcons.videos),
                      selectedIcon: Icon(KIcons.videosOn),
                      label: ui('Мои ролики'),
                    ),
                    ExcludeSemantics(
                      child: NavigationDestination(icon: SizedBox(width: 24, height: 24), label: ''),
                    ),
                  ],
                  if (kStoriesTabEnabled)
                    NavigationDestination(
                      icon: Icon(KIcons.stories),
                      selectedIcon: Icon(KIcons.storiesOn),
                      label: ui('Рассказы'),
                    ),
                  NavigationDestination(
                    icon: Icon(KIcons.headphones),
                    selectedIcon: Icon(KIcons.headphonesOn),
                    label: ui('Подкасты'),
                  ),
                  NavigationDestination(
                    icon: Icon(KIcons.words),
                    selectedIcon: Icon(KIcons.wordsOn),
                    label: ui('Словарь'),
                  ),
                  NavigationDestination(
                    icon: store.user == null ? Icon(KIcons.profile) : ProfileAvatar(radius: 13),
                    selectedIcon: store.user == null ? Icon(KIcons.profileOn) : ProfileAvatar(radius: 13),
                    label: ui('Профиль'),
                  ),
                ],
              ),
              if (kAddVideoEnabled)
                SafeArea(
                  top: false,
                  child: Semantics(
                    button: true,
                    label: ui('Добавить ролик'),
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

  Widget _wideShell(Widget Function() buildPages) {
    final items = <(int, IconData, IconData, String)>[
      (_home, KIcons.home, KIcons.homeOn, ui('Главная')),
      (_feed, KIcons.catalog, KIcons.catalogOn, ui('Видео')),
      if (kAddVideoEnabled) (2, KIcons.videos, KIcons.videosOn, ui('Мои ролики')),
      if (kStoriesTabEnabled) (_stories, KIcons.stories, KIcons.storiesOn, ui('Рассказы')),
      (_podcasts, KIcons.headphones, KIcons.headphonesOn, ui('Подкасты')),
      (_words, KIcons.words, KIcons.wordsOn, ui('Словарь')),
    ];
    final profile = (_profile, KIcons.profile, KIcons.profileOn, ui('Профиль'));
    Widget item((int, IconData, IconData, String) it, {VoidCallback? onTap, Widget? avatar}) {
      final (page, icon, on, label) = it;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: _tab == page ? cAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? () => _select(page),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  avatar != null
                      ? SizedBox(width: 24, height: 24, child: avatar)
                      : Icon(_tab == page ? on : icon, size: 24, color: _tab == page ? cInk : cMuted),
                  SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
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
                  // Высота совпадает с PageTitle и шапками страниц справа.
                  SizedBox(
                    height: kTopBarHeight,
                    child: Padding(
                      padding: EdgeInsets.only(left: 28),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: 'Kapiraš',
                            children: [
                              TextSpan(
                                text: '?',
                                style: TextStyle(color: cAccent),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 22.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.75,
                            color: cViolet,
                          ),
                        ),
                      ),
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
                        label: Text(ui('Добавить ролик')),
                      ),
                    ),
                  Spacer(),
                  item(profile, avatar: store.user == null ? null : ProfileAvatar(radius: 12)),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              // Свой навигатор: страницы второго уровня открываются здесь, а сайдбар остаётся на месте.
              // Поля и ширину держат только вкладки; открытые поверх страницы занимают всю область, и их шапка идёт на всю ширину.
              child: Navigator(
                key: _navKey,
                observers: analyticsObservers(),
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28),
                        child: ValueListenableBuilder<int>(valueListenable: _tabN, builder: (_, _, _) => buildPages()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
