import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/widgets/banner_widget.dart';
import 'package:family_altar/widgets/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

      // Drawer (Side Sheet) implementation remains the same
      drawer: Drawer(
        backgroundColor:
            context.backgroundColor, // Assuming a theme color for drawer background
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: context.appBarColor, // Revert to original AppBar color
              ),
              child: Text(
                widget.title,
                style: AppFonts.bold(context).copyWith(
                  color: const Color(
                    0xFFE0C097,
                  ), // Assuming a theme color for title
                  fontSize: 24,
                ),
              ),
            ),

            ListTile(
              leading: Icon(Icons.menu_book, color: context.textColor),
              title: Text(
                'Select Volume',
                style: TextStyle(color: context.textColor),
              ),
              onTap: () {
                context.pop();
                context.push(
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
                context.pop();
                context.push('/settings');
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: context.appBarColor, // Revert to original AppBar color
      centerTitle: true,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: context.textColor,
                ), // Revert to original text color
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),

        title: Center(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.title,
              style: AppFonts.bold(context).copyWith(
                color: const Color(0xFFE0C097), 
                fontSize: 20,
                fontFamily: 'Cursive',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '  Volume I',
              style: AppFonts.bold(context).copyWith(
                color: const Color(0xFFE0C097), 
                fontSize: 14,
                fontFamily: 'Cursive',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),

        actions: const [SizedBox(width: 48)],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Banner
            const FamilyAltarBanner(),

            // Calendar widget
            const FamilyAltarCalendar(),
         
          ],
        ),
      ),
    );
  }
}
