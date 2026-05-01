import 'package:family_altar/navigation_service.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/widgets/banner_widget.dart';
import 'package:family_altar/widgets/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.title, super.key});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  bool _isSubscribedToRoute = false;
  bool _isRouteCurrent = false;

  bool get _isPhone {
    final display = View.of(context).display;
    final logicalSize = display.size / display.devicePixelRatio;
    return logicalSize.shortestSide < 600;
  }

  void _updatePreferredOrientations() {
    if (!mounted) {
      return;
    }

    if (_isRouteCurrent && _isPhone) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      return;
    }

    SystemChrome.setPreferredOrientations(const []);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isSubscribedToRoute) {
      final route = ModalRoute.of(context);
      if (route != null) {
        routeObserver.subscribe(this, route);
        _isSubscribedToRoute = true;
        _isRouteCurrent = route.isCurrent;
      }
    }

    _updatePreferredOrientations();
  }

  @override
  void didChangeMetrics() {
    _updatePreferredOrientations();
  }

  @override
  void didPush() {
    _isRouteCurrent = true;
    _updatePreferredOrientations();
  }

  @override
  void didPopNext() {
    _isRouteCurrent = true;
    _updatePreferredOrientations();
  }

  @override
  void didPushNext() {
    _isRouteCurrent = false;
    _updatePreferredOrientations();
  }

  @override
  void didPop() {
    _isRouteCurrent = false;
    _updatePreferredOrientations();
  }

  @override
  void dispose() {
    if (_isSubscribedToRoute) {
      routeObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(const []);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,

      drawer: Drawer(
        backgroundColor: context.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: context.appBarColor),
              child: Text(
                widget.title,
                style: AppFonts.bold(
                  context,
                ).copyWith(color: context.appBarTitleColor, fontSize: 24),
              ),
            ),

            ListTile(
              leading: Icon(Icons.menu_book, color: context.textColor),
              title: Text(
                'Select Volume',
                style: TextStyle(color: context.textColor),
              ),
              onTap: () {
                context
                  ..pop()
                  ..push(
                    '/book-selection?title=${Uri.encodeComponent(widget.title)}',
                  );
              },
            ),

            ListTile(
              leading: Icon(Icons.settings, color: context.textColor),
              title: Text(
                'Settings',
                style: TextStyle(color: context.textColor),
              ),
              onTap: () {
                context
                  ..pop()
                  ..push('/settings');
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: context.appBarColor,
        centerTitle: true,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: context.textColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),

        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.allura(
                  color: context.appBarTitleColor,
                  fontSize: 35,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Volume I',
                style: AppFonts.normal(context).copyWith(
                  color: context.appBarTitleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // actions: const [SizedBox(width: 48)],
      ),

      extendBody: true,

      body: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final isLandscape = mediaQuery.orientation == Orientation.landscape;
          final maxHeight = constraints.maxHeight;

          if (isLandscape) {
            final bannerHeight = (maxHeight * 0.42).clamp(130.0, 260.0);

            return Column(
              children: <Widget>[
                SizedBox(
                  height: bannerHeight,
                  child: const FamilyAltarBanner(),
                ),
                const Expanded(child: FamilyAltarCalendar()),
              ],
            );
          }

          return const Column(
            children: <Widget>[
              Expanded(child: FamilyAltarBanner()),
              FamilyAltarCalendar(),
            ],
          );
        },
      ),
    );
  }
}
