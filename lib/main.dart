import 'package:flutter/material.dart';
import 'features/prayer/prayer_times_service.dart';
import 'features/quotes/quote_picker_service.dart';
import 'features/notifications/notification_service.dart';
import 'features/prayer_tracking/prayer_stats_page.dart';
import 'features/widget/prayer_widget_service.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/settings_page.dart';
import 'features/quran/quran_page.dart';
import 'features/qibla/qibla_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';
import 'features/calendar/calendar_page.dart';
import 'features/hajj/hajj_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'features/common_words/common_words_page.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize widget service
  await PrayerWidgetService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final useDark = prefs.getBool('useAmoledTheme') ?? true;
  themeNotifier.value = useDark ? ThemeMode.dark : ThemeMode.light;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            // This is the theme of your application.
            //
            // TRY THIS: Try running your application with "flutter run". You'll see
            // the application has a purple toolbar. Then, without quitting the app,
            // try changing the seedColor in the colorScheme below to Colors.green
            // and then invoke "hot reload" (save your changes or press the "hot
            // reload" button in a Flutter-supported IDE, or press "r" if you used
            // the command line to start the app).
            //
            // Notice that the counter didn't reset back to zero; the application
            // state is not lost during the reload. To reset the state, use hot
            // restart instead.
            //
            // This works for code too, not just values: Most code changes can be
            // tested with just a hot reload.
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
          ),
          themeMode: mode,
          home: const AppScaffold(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PrayerTimesService? _prayerTimesService;
  final QuotePickerService _quotePickerService = QuotePickerService();

  DateTime? _nextPrayerTime;
  String? _nextPrayerName;
  String? _quote;
  Timer? _timer;
  Duration _countdown = Duration.zero;
  bool _locationLoaded = false;
  String? _locationError;
  bool _isRefreshing = false;
  bool _isUsingCache = false;

  // Quote topics and selection
  List<String> _topics = [];
  String? _selectedTopic;

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // load available topics
    _quotePickerService.getTopics().then((topics) {
      setState(() => _topics = topics);
    });
    _initLocationAndLoadData();
  }

  Future<void> _initLocationAndLoadData() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = AppLocalizations.of(context)!.locationServicesDisabled;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = AppLocalizations.of(context)!.locationPermissionDenied;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = AppLocalizations.of(context)!.locationPermissionPermanentlyDenied;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final prefs = await SharedPreferences.getInstance();
      final calcMethodString = prefs.getString('calculationMethod') ?? 'Method 2 (University of Islamic Sciences)';
      final method = calcMethodString.contains('4') ? 4 : 2;
      final madhabString = prefs.getString('madhab') ?? 'Shafi';
      const madhabList = ['Shafi', 'Hanafi', 'Maliki', 'Hanbali'];
      var madhab = madhabList.indexOf(madhabString);
      // If madhab not found, default to Shafi (0)
      if (madhab == -1) madhab = 0;

      // Store location and settings for widget
      await prefs.setDouble('location_latitude', position.latitude);
      await prefs.setDouble('location_longitude', position.longitude);
      await prefs.setInt('calculation_method', method);
      await prefs.setInt('madhab', madhab);

      _prayerTimesService = PrayerTimesService(
        latitude: position.latitude,
        longitude: position.longitude,
        method: method,
        madhab: madhab,
      );
      setState(() {
        _locationLoaded = true;
        _locationError = null;
      });
      _loadData();
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  Future<void> _loadData() async {
    if (_prayerTimesService == null) return;
    try {
      final nextPrayerTime = await _prayerTimesService!.getNextPrayerTime();
      final nextPrayerName = await _prayerTimesService!.getNextPrayerName();
      final quote = await _quotePickerService.getQuote(topic: _selectedTopic);

      // Schedule notifications for today's prayers
      final prayerTimes = await _prayerTimesService!.getTodayPrayerTimes();
      await NotificationService().schedulePrayerNotifications(prayerTimes);

      // Update home screen widget
      await PrayerWidgetService.updateWidgetWithStoredSettings();

      setState(() {
        _nextPrayerTime = nextPrayerTime;
        _nextPrayerName = nextPrayerName;
        _quote = quote;
        _countdown = nextPrayerTime.difference(DateTime.now());
        _locationError = null;
        _isUsingCache = false;
      });
      _startTimer();
    } catch (e) {
      // Try to use cached data on error
      try {
        final cachedTimes = await _prayerTimesService!.getTodayPrayerTimes();
        final now = DateTime.now();
        final upcoming = cachedTimes.entries.where((e) => e.value.isAfter(now)).toList();
        if (upcoming.isNotEmpty) {
          upcoming.sort((a, b) => a.value.compareTo(b.value));
          final nextPrayer = upcoming.first;
          setState(() {
            _nextPrayerTime = nextPrayer.value;
            _nextPrayerName = nextPrayer.key;
            _countdown = nextPrayer.value.difference(now);
            _isUsingCache = true;
            _locationError = AppLocalizations.of(context)!.usingCachedPrayerTimes;
          });
          _startTimer();
        } else {
          setState(() {
            _locationError = 'Failed to load prayer times: ${e.toString()}';
          });
        }
      } catch (cacheError) {
        setState(() {
          _locationError = 'Failed to load prayer times: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_prayerTimesService == null || _isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _prayerTimesService!.refreshPrayerTimes();
      await _loadData();
    } catch (e) {
      setState(() {
        _locationError = 'Failed to refresh: ${e.toString()}';
      });
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_nextPrayerTime == null) return;
      final now = DateTime.now();
      final diff = _nextPrayerTime!.difference(now);
      if (diff.isNegative) {
        _timer?.cancel();
        _loadData();
      } else {
        setState(() {
          _countdown = diff;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_locationLoaded)
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshData,
              tooltip: AppLocalizations.of(context)!.refreshPrayerTimes,
            ),
        ],
      ),
      body: SafeArea(
        child: _locationError != null && !_isUsingCache
            ? Center(child: Text(_locationError!))
            : !_locationLoaded
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isUsingCache)
                        Container(
                          color: Colors.orange.withOpacity(0.2),
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _locationError ?? AppLocalizations.of(context)!.usingCachedPrayerTimes,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TableCalendar(
                          firstDay: DateTime.now().subtract(Duration(days: 365)),
                          lastDay: DateTime.now().add(Duration(days: 365)),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (sel, focus) {
                            setState(() {
                              _selectedDay = sel;
                              _focusedDay = focus;
                            });
                          },
                          calendarBuilders: CalendarBuilders(
                            dayBuilder: (context, date, _) {
                              final hijri = HijriCalendar.fromDate(date);
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${date.day}', style: TextStyle(fontSize: 16)),
                                  SizedBox(height: 2),
                                  Text('${hijri.hDay}', style: TextStyle(fontSize: 10)),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              _nextPrayerName != null
                                  ? '${AppLocalizations.of(context)!.nextPrayer}: $_nextPrayerName'
                                  : AppLocalizations.of(context)!.loading,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _nextPrayerTime != null ? _formatDuration(_countdown) : '--:--:--',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (_topics.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedTopic,
                            hint: Text(AppLocalizations.of(context)!.selectTopic),
                            items: _topics.map((t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(t),
                            )).toList(),
                            onChanged: (value) {
                              setState(() { _selectedTopic = value; });
                              _loadData();
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                          child: Card(
                            key: ValueKey<String>(_quote ?? ''),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _quote ?? '...',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

// Root widget with bottom navigation between Home and Settings
class AppScaffold extends StatefulWidget {
  const AppScaffold({Key? key}) : super(key: key);
  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const MyHomePage(title: 'Immutable5'),
    const PrayerStatsPage(),
    const QiblaPage(),
    const CalendarPage(),
    const HajjPage(),
    const CommonWordsPage(),
    const QuranPage(),
    const SettingsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: AppLocalizations.of(context)!.home),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Qibla'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: AppLocalizations.of(context)!.calendar),
          BottomNavigationBarItem(icon: Icon(Icons.directions_walk), label: AppLocalizations.of(context)!.hajj),
          BottomNavigationBarItem(icon: Icon(Icons.translate), label: AppLocalizations.of(context)!.commonWords),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: AppLocalizations.of(context)!.quran),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: AppLocalizations.of(context)!.settings),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
