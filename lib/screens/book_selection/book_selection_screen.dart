import 'dart:math' as math;

import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:family_altar/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookSelectionScreen extends StatelessWidget {
  const BookSelectionScreen({required this.title, super.key});

  static const _bookConfigs = [
    BookItemData(
      imagePath: 'assets/images/FamilyAltarVolumeICover.jpg',
      title: 'Volume I',
    ),
    BookItemData(
      imagePath: 'assets/images/FamilyAltarVolumeIICover.jpg',
      title: 'Volume II',
      isAvailable: false,
    ),
    BookItemData(
      imagePath: 'assets/images/FamilyAltarVolumeIIICover.jpg',
      title: 'Volume III',
      isAvailable: false,
    ),
  ];

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: context.appBarColor,
        title: Text(
          title,
          style: AppFonts.bold(
            context,
            size: FontSize.large,
          ).copyWith(color: context.appBarTitleColor),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
            size: AppIcons.getIconSize(IconSize.medium),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bookConfigs.length,
        itemBuilder: (_, index) => BookItem(data: _bookConfigs[index]),
        separatorBuilder: (_, _) => const SizedBox(height: 16),
      ),
    );
  }
}

class BookItem extends StatefulWidget {
  const BookItem({required this.data, super.key});

  final BookItemData data;

  @override
  State<BookItem> createState() => _BookItemState();
}

class _BookItemState extends State<BookItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 650),
    vsync: this,
  );
  late final Animation<double> _flipAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleBook() {
    if (!widget.data.isAvailable) return;
    if (_flipAnimation.value < 0.5) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _closeBook() {
    if (!widget.data.isAvailable) return;
    _controller.reverse();
  }

  Future<void> _handleSectionTap(Section section) async {
    if (!widget.data.isAvailable) return;
    if (section == Section.dailyReading) {
      final date = await Utils.getLastAccessedDay();
      if (!mounted) return;
      await context.push('/reader', extra: date);
    } else {
      if (!mounted) return;
      await context.push('/foreword-preface', extra: section);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (_, _) {
          final progress = _flipAnimation.value;
          return SizedBox(
            width: 240,
            height: 370,
            child: Stack(
              children: [
                _BookInnerPage(
                  title: widget.data.title,
                  sections: widget.data.sections,
                  progress: progress,
                  onClose: _closeBook,
                  onSectionTap: _handleSectionTap,
                ),
                _AnimatedBookCover(
                  imagePath: widget.data.imagePath,
                  progress: progress,
                  isComingSoon: !widget.data.isAvailable,
                  onTap: _toggleBook,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum Section { foreword, preface, dailyReading }

extension SectionLabel on Section {
  String get displayName {
    switch (this) {
      case Section.foreword:
        return 'Foreword';
      case Section.preface:
        return 'Preface';
      case Section.dailyReading:
        return 'Daily Reading';
    }
  }
}

class BookItemData {
  const BookItemData({
    required this.imagePath,
    required this.title,
    this.sections = const [
      Section.foreword,
      Section.preface,
      Section.dailyReading,
    ],
    this.isAvailable = true,
  });

  final String imagePath;
  final String title;
  final List<Section> sections;
  final bool isAvailable;
}

class _AnimatedBookCover extends StatelessWidget {
  const _AnimatedBookCover({
    required this.imagePath,
    required this.progress,
    required this.onTap,
    this.isComingSoon = false,
  });

  final String imagePath;
  final double progress;
  final VoidCallback onTap;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    final angle = progress * math.pi;
    final isBackVisible = angle > math.pi / 2;
    final displayAngle = isBackVisible ? angle - math.pi : angle;
    final isFullyOpen = progress >= 0.95;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: isFullyOpen || isComingSoon,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform(
                alignment: Alignment.centerLeft,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(displayAngle),
                child:
                    isBackVisible
                        ? const _BookCoverInterior()
                        : _BookCoverFront(imagePath: imagePath),
              ),
              if (isComingSoon) const _ComingSoonBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCoverFront extends StatelessWidget {
  const _BookCoverFront({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}

class _BookCoverInterior extends StatelessWidget {
  const _BookCoverInterior();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: const Color.fromARGB(255, 253, 233, 152)),
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(235, 248, 231, 126).withValues(alpha: 0.25),
            const Color.fromARGB(255, 255, 221, 136).withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBanner extends StatelessWidget {
  const _ComingSoonBanner();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        child: Transform.rotate(
          angle: -math.pi / 4,
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade900.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'COMING SOON',
              textAlign: TextAlign.center,
              style: AppFonts.bold(context).copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookInnerPage extends StatelessWidget {
  const _BookInnerPage({
    required this.title,
    required this.sections,
    required this.progress,
    required this.onClose,
    required this.onSectionTap,
  });

  final String title;
  final List<Section> sections;
  final double progress;
  final VoidCallback onClose;
  final ValueChanged<Section> onSectionTap;

  @override
  Widget build(BuildContext context) {
    final opacity = progress.clamp(0.0, 1.0);

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 370,
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.textColor.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: progress < 0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppFonts.bold(
                          context,
                          size: FontSize.large,
                        ).copyWith(color: Colors.black),
                      ),
                      AnimatedOpacity(
                        opacity: progress > 0.6 ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          onPressed: onClose,
                          icon: Icon(Icons.close, color: context.textColor),
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a section to begin reading:',
                    style: AppFonts.normal(
                      context,
                      size: FontSize.small,
                    ).copyWith(color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  ...sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          foregroundColor: Colors.black,
                          textStyle: AppFonts.bold(context),
                        ),
                        onPressed: () => onSectionTap(section),
                        child: Text(section.displayName),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
