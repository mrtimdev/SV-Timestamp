import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/services/photo_storage_service.dart';
import '../../../models/captured_photo.dart';
import '../../../core/utils/app_strings.dart';
import '../../settings/providers/settings_provider.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, this.storage});

  final PhotoStorageService? storage;
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with TickerProviderStateMixin {
  late final _storage = widget.storage ?? PhotoStorageService();
  String _query = '';
  final _searchController = TextEditingController();
  late final Future<List<CapturedPhoto>> _photos = _storage.list();

  late AnimationController _headerAnim;
  late Animation<double> _headerFade;

  final _deletedPaths = <String>{};
  final _deletingPaths = <String>{};

  Future<bool> _deletePhoto(CapturedPhoto photo) async {
    if (!_deletingPaths.add(photo.path)) return false;
    try {
      await _storage.delete(photo.path);
      if (mounted) {
        // Update the displayed snapshot immediately, without waiting for a
        // second directory scan or a callback from a recycled grid card.
        setState(() => _deletedPaths.add(photo.path));
      }
      return true;
    } catch (_) {
      if (mounted) {
        final strings = AppStrings(
          context.read<SettingsProvider>().settings.language,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.text(
                'Could not delete photo. Please try again.',
                'មិនអាចលុបរូបថតបានទេ។ សូមព្យាយាមម្ដងទៀត។',
              ),
            ),
          ),
        );
      }
      return false;
    } finally {
      _deletingPaths.remove(photo.path);
    }
  }

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _headerFade = CurvedAnimation(
      parent: _headerAnim,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(
      context.watch<SettingsProvider>().settings.language,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark : AppColors.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerScrolled) => [
          _GallerySliverAppBar(
            strings: strings,
            isDark: isDark,
            fadeAnim: _headerFade,
            query: _query,
            searchController: _searchController,
            onQueryChanged: (v) => setState(() => _query = v),
            onClearQuery: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
        ],
        body: FutureBuilder<List<CapturedPhoto>>(
          future: _photos,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              );
            }

            final allPhotos = snapshot.data!.where(
              (photo) => !_deletedPaths.contains(photo.path),
            );
            final visible = allPhotos
                .where(
                  (p) => DateFormat('MMM d, yyyy')
                      .format(p.capturedAt)
                      .toLowerCase()
                      .contains(_query.toLowerCase()),
                )
                .toList();

            if (visible.isEmpty) {
              return _EmptyGallery(
                strings: strings,
                hasFilter: _query.isNotEmpty,
                onClearFilter: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                  child: Row(
                    children: [
                      _CountBadge(
                        label:
                            '${visible.length} ${strings.text('captures', 'រូបថត')}',
                        isDark: isDark,
                      ),
                      const Spacer(),
                      Text(
                        strings.text('Swipe to browse', 'អូសដើម្បីរុករក'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 32),
                    itemCount: visible.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.76,
                        ),
                    itemBuilder: (context, index) => _PhotoCard(
                      key: ValueKey(visible[index].path),
                      photo: visible[index],
                      allPhotos: visible,
                      initialIndex: index,
                      strings: strings,
                      isDark: isDark,
                      onDelete: _deletePhoto,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sliver AppBar
// ─────────────────────────────────────────────
class _GallerySliverAppBar extends StatelessWidget {
  const _GallerySliverAppBar({
    required this.strings,
    required this.isDark,
    required this.fadeAnim,
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
    required this.onClearQuery,
  });

  final AppStrings strings;
  final bool isDark;
  final Animation<double> fadeAnim;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        background: FadeTransition(
          opacity: fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.text('Gallery', 'វិចិត្រសាល'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          strings.text(
                            'Timestamped captures',
                            'រូបថតមានត្រាពេលវេលា',
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onQueryChanged,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark
                            ? Colors.white38
                            : AppColors.primary.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      hintText: strings.text(
                        'Search by date...',
                        'ស្វែងរកតាមកាលបរិច្ឆេទ...',
                      ),
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? Colors.white30
                            : const Color(0xFF94A3B8),
                      ),
                      suffixIcon: query.isNotEmpty
                          ? GestureDetector(
                              onTap: onClearQuery,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
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

// ─────────────────────────────────────────────
//  Count Badge
// ─────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Photo Card (grid item)
// ─────────────────────────────────────────────
class _PhotoCard extends StatefulWidget {
  const _PhotoCard({
    super.key,
    required this.photo,
    required this.allPhotos,
    required this.initialIndex,
    required this.strings,
    required this.isDark,
    required this.onDelete,
  });

  final CapturedPhoto photo;
  final List<CapturedPhoto> allPhotos;
  final int initialIndex;
  final AppStrings strings;
  final bool isDark;
  final Future<bool> Function(CapturedPhoto) onDelete;

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressAnim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 0.035,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.965,
    ).animate(CurvedAnimation(parent: _pressAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressAnim.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context) {
    // Keep the route independent of this grid card's lifetime and index.
    final photos = List<CapturedPhoto>.of(widget.allPhotos);
    final initialIndex = widget.initialIndex;
    final strings = widget.strings;
    final onDelete = widget.onDelete;
    Navigator.of(context).push(
      _SlideUpPageRoute(
        builder: (_) => _FullScreenSlider(
          photos: photos,
          initialIndex: initialIndex,
          strings: strings,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _pressAnim.forward(),
        onTapUp: (_) {
          _pressAnim.reverse();
          _openDetail(context);
        },
        onTapCancel: () => _pressAnim.reverse(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.isDark ? AppColors.darkSurface : Colors.white,
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.isDark ? 0.25 : 0.08,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'photo_${widget.photo.path}',
                  child: Image.file(File(widget.photo.path), fit: BoxFit.cover),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xCC000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 30,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat(
                          'MMM d, yyyy',
                        ).format(widget.photo.capturedAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(widget.photo.capturedAt),
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: _CardQuickActions(
                    photo: widget.photo,
                    strings: widget.strings,
                    onDelete: widget.onDelete,
                  ),
                ),
                const Positioned(
                  right: 10,
                  bottom: 10,
                  child: Icon(
                    Icons.open_in_full_rounded,
                    size: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Card Quick Actions
// ─────────────────────────────────────────────
class _CardQuickActions extends StatelessWidget {
  const _CardQuickActions({
    required this.photo,
    required this.strings,
    required this.onDelete,
  });

  final CapturedPhoto photo;
  final AppStrings strings;
  final Future<bool> Function(CapturedPhoto) onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) async {
              if (value == 'share') {
                await SharePlus.instance.share(
                  ShareParams(files: [XFile(photo.path)]),
                );
              }
              if (value == 'delete') {
                await onDelete(photo);
              }
            },
            itemBuilder: (_) => [
              _menuItem(
                value: 'share',
                icon: Icons.ios_share_rounded,
                label: strings.text('Share', 'ចែករំលែក'),
                color: AppColors.primary,
              ),
              _menuItem(
                value: 'delete',
                icon: Icons.delete_sweep_rounded,
                label: strings.text('Delete', 'លុប'),
                color: AppColors.rose,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Full-Screen Slider
// ─────────────────────────────────────────────
class _FullScreenSlider extends StatefulWidget {
  const _FullScreenSlider({
    required this.photos,
    required this.initialIndex,
    required this.strings,
    required this.onDelete,
  });

  final List<CapturedPhoto> photos;
  final int initialIndex;
  final AppStrings strings;
  final Future<bool> Function(CapturedPhoto) onDelete;

  @override
  State<_FullScreenSlider> createState() => _FullScreenSliderState();
}

class _FullScreenSliderState extends State<_FullScreenSlider>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _current;
  bool _barsVisible = true;
  bool _deleting = false;
  late AnimationController _barsAnim;
  late Animation<double> _barsFade;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _barsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1,
    );
    _barsFade = CurvedAnimation(parent: _barsAnim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _barsAnim.dispose();
    super.dispose();
  }

  void _toggleBars() {
    setState(() => _barsVisible = !_barsVisible);
    if (_barsVisible) {
      _barsAnim.forward();
    } else {
      _barsAnim.reverse();
    }
  }

  CapturedPhoto get _currentPhoto => widget.photos[_current];

  Future<void> _deletePhoto() async {
    if (_deleting) return;
    _deleting = true;
    final photo = _currentPhoto;
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dCtx) => _ConfirmDeleteDialog(strings: widget.strings),
      );
      if (confirm != true || !mounted) return;
      final deleted = await widget.onDelete(photo);
      if (deleted && mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    } finally {
      _deleting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleBars,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: total,
                itemBuilder: (ctx, index) {
                  final photo = widget.photos[index];
                  return InteractiveViewer(
                    minScale: 0.85,
                    maxScale: 5.0,
                    child: Hero(
                      tag: 'photo_${photo.path}',
                      child: Image.file(File(photo.path), fit: BoxFit.contain),
                    ),
                  );
                },
              ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _barsFade,
                  child: _TopBar(
                    current: _current,
                    total: total,
                    onClose: () => Navigator.pop(context),
                    onShare: () => SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(_currentPhoto.path)],
                        text: 'Captured with SV Timestamp',
                      ),
                    ),
                    onDelete: _deletePhoto,
                    photo: _currentPhoto,
                  ),
                ),
              ),

              // Bottom info bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _barsFade,
                  child: _BottomBar(
                    photo: _currentPhoto,
                    current: _current,
                    total: total,
                  ),
                ),
              ),

              // Nav arrows
              if (total > 1) ...[
                if (_current > 0)
                  FadeTransition(
                    opacity: _barsFade,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _NavArrow(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                  ),
                if (_current < total - 1)
                  FadeTransition(
                    opacity: _barsFade,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _NavArrow(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Top Bar (full-screen viewer)
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.current,
    required this.total,
    required this.onClose,
    required this.onShare,
    required this.onDelete,
    required this.photo,
  });

  final int current;
  final int total;
  final VoidCallback onClose;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  _GlassIconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onClose,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${current + 1} / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _GlassIconBtn(
                    icon: Icons.ios_share_rounded,
                    onTap: onShare,
                    color: AppColors.primaryLight,
                    glowColor: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  _GlassIconBtn(
                    icon: Icons.delete_sweep_rounded,
                    onTap: onDelete,
                    color: AppColors.rose,
                    glowColor: AppColors.rose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Bottom Bar (full-screen viewer)
// ─────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.photo,
    required this.current,
    required this.total,
  });

  final CapturedPhoto photo;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.75),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(photo.capturedAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('hh:mm:ss a').format(photo.capturedAt),
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (total > 1) _DotIndicator(count: total, current: current),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Dot Indicator
// ─────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final show = count <= 20 ? count : 20;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(show, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 5),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primaryLight
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
//  Nav Arrow
// ─────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Glass Icon Button
// ─────────────────────────────────────────────
class _GlassIconBtn extends StatefulWidget {
  const _GlassIconBtn({
    required this.icon,
    required this.onTap,
    required this.color,
    this.glowColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color? glowColor;

  @override
  State<_GlassIconBtn> createState() => _GlassIconBtnState();
}

class _GlassIconBtnState extends State<_GlassIconBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 0.08,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.color.withValues(alpha: 0.3)),
                boxShadow: widget.glowColor != null
                    ? [
                        BoxShadow(
                          color: widget.glowColor!.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Confirm Delete Dialog
// ─────────────────────────────────────────────
class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.rose,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(strings.text('Delete photo?', 'លុបរូបថតនេះ?'))),
        ],
      ),
      content: Text(
        strings.text(
          'This action cannot be undone.',
          'រូបថតនេះនឹងត្រូវបានលុបជាអចិន្ត្រៃយ៍។',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.text('Cancel', 'បោះបង់')),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.rose,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.delete_forever_rounded, size: 16),
          label: Text(strings.text('Delete', 'លុប')),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Empty Gallery
// ─────────────────────────────────────────────
class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({
    required this.strings,
    this.hasFilter = false,
    this.onClearFilter,
  });

  final AppStrings strings;
  final bool hasFilter;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              hasFilter
                  ? strings.text('No matching photos', 'រកមិនឃើញរូបថតទេ')
                  : strings.text('No captures yet', 'មិនទាន់មានរូបថត'),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? strings.text(
                      'Try a different date range.',
                      'សូមសាកល្បងស្វែងរកកាលបរិច្ឆេទផ្សេង។',
                    )
                  : strings.text(
                      'Your timestamped photos will appear here.',
                      'រូបថតមានត្រាពេលវេលានឹងបង្ហាញនៅទីនេះ។',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13.5),
            ),
            const SizedBox(height: 28),
            if (hasFilter)
              OutlinedButton.icon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: Text(strings.text('Clear filter', 'សម្អាតការស្វែងរក')),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(strings.text('Open Camera', 'បើកកាមេរ៉ា')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Slide-Up Page Route
// ─────────────────────────────────────────────
class _SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  _SlideUpPageRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (ctx, anim, secondary) => builder(ctx),
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (ctx, anim, secondary, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: anim,
              curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            ),
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}
