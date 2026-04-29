import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/widgets/banner_widget.dart';
import 'package:family_altar/widgets/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.title, super.key});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                ).copyWith(color: const Color(0xFFE0C097), fontSize: 24),
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
        toolbarHeight: 80,
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
                  color: const Color(0xFFE0C097),
                  fontSize: 35,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Volume I',
                style: AppFonts.normal(context).copyWith(
                  color: const Color(0xFFE0C097),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // actions: const [SizedBox(width: 48)],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final isLandscape = mediaQuery.orientation == Orientation.landscape;
          final maxHeight = constraints.maxHeight;
          final safeBottomInset = mediaQuery.padding.bottom;

          if (isLandscape) {
            final bannerHeight = (maxHeight * 0.42).clamp(130.0, 260.0);

            final bottomPadding = safeBottomInset + 12;

            final calendarHeight = (maxHeight - bannerHeight - bottomPadding).clamp(
              220.0,
              620.0,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: bannerHeight,
                    child: const FamilyAltarBanner(),
                  ),
                  SizedBox(
                    height: calendarHeight,
                    child: const FamilyAltarCalendar(),
                  ),
                ],
              ),
            );
          }

          const minBannerHeight = 140.0;
          final desiredCalendarHeight = (maxHeight * 0.62).clamp(360.0, 620.0);
          final maxCalendarHeight = (maxHeight - minBannerHeight).clamp(
            0.0,
            maxHeight,
          );
          final calendarHeight = desiredCalendarHeight > maxCalendarHeight
              ? maxCalendarHeight
              : desiredCalendarHeight;

          return Column(
            children: <Widget>[
              const Expanded(child: FamilyAltarBanner()),
              SizedBox(
                height: calendarHeight,
                child: const FamilyAltarCalendar(),
              ),
            ],
          );
        },
      ),
    );
  }
}
