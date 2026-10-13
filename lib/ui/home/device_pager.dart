import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';

/// Swipeable devices, one per page, ported from the Kotlin `DevicePager`.
///
/// Reports the current page through [onPageSettled]: once for page 0 when first
/// shown, then each time a swipe settles on a different page. `HomeScreen` uses
/// it to fetch a device's status the first time it is swiped to.
///
/// The pager sits inside the Home tab's vertical scroll, so it has no fixed
/// height: each page is measured, and the pager's height follows the page
/// under the finger (blending between neighbours mid-swipe so neither is
/// clipped). Dots appear only with more than one item; a single device shows
/// no pager chrome at all.
class DevicePager<T> extends StatefulWidget {
  const DevicePager({
    super.key,
    required this.items,
    required this.onPageSettled,
    required this.pageBuilder,
  });

  final List<T> items;
  final ValueChanged<int> onPageSettled;
  final Widget Function(T item) pageBuilder;

  @override
  State<DevicePager<T>> createState() => _DevicePagerState<T>();
}

class _DevicePagerState<T> extends State<DevicePager<T>> {
  final PageController _controller = PageController();

  /// Measured height of each page that has been laid out.
  final Map<int, double> _heights = {};
  int _settledPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPageSettled(0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _page => _controller.hasClients && _controller.position.haveDimensions
      ? _controller.page ?? _settledPage.toDouble()
      : _settledPage.toDouble();

  bool _onScrollEnd(ScrollEndNotification n) {
    if (n.depth != 0) return false;
    final page = _page.round().clamp(0, widget.items.length - 1);
    if (page != _settledPage) {
      setState(() => _settledPage = page);
      widget.onPageSettled(page);
    }
    return false;
  }

  void _onPageMeasured(int index, double height) {
    if (_heights[index] == height) return;
    // Measured during layout; the new height applies from the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _heights[index] = height);
    });
  }

  /// The pager's height for the current scroll position: the current page's
  /// height, blended towards the neighbour being swiped to.
  double _heightAt(double page) {
    final lower = page.floor().clamp(0, widget.items.length - 1);
    final upper = page.ceil().clamp(0, widget.items.length - 1);
    final a = _heights[lower] ?? _heights[upper] ?? 0;
    final b = _heights[upper] ?? a;
    return lerpDouble(a, b, page - page.floorToDouble())!;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Each page is `md` wider than the slot, with the extra on its right
            // as the gap between pages; the ClipRect trims it back to the slot.
            return ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => SizedBox(height: _heightAt(_page), child: child),
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: width + ClaroSpacing.md,
                  maxWidth: width + ClaroSpacing.md,
                  child: NotificationListener<ScrollEndNotification>(
                    onNotification: _onScrollEnd,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: items.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(right: ClaroSpacing.md),
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: _MeasureHeight(
                            onHeight: (h) => _onPageMeasured(i, h),
                            child: widget.pageBuilder(items[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (items.length > 1) ...[
          const SizedBox(height: ClaroSpacing.md),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _Dots(count: items.length, active: _page.round()),
          ),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              key: ValueKey('pager-dot-$i'),
              width: i == active ? 8 : 6,
              height: i == active ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == active ? ClaroColors.mint : ClaroColors.borderDark,
              ),
            ),
          ),
      ],
    );
  }
}

/// Reports its child's laid-out height every time it changes.
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureHeight(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureHeight renderObject) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onHeight);

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}
