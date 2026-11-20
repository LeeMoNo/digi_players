import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'window_layout.dart';

/// 持有最近一次读到的水平 size class 和折痕。折痕不写回 [MediaQuery]。
class WindowLayoutScope extends InheritedWidget {
  const WindowLayoutScope({
    super.key,
    required this.sizeClass,
    this.fold,
    required super.child,
  });

  final HorizontalSizeClass sizeClass;
  final FoldSeam? fold;

  static HorizontalSizeClass sizeClassOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WindowLayoutScope>();
    return scope?.sizeClass ?? HorizontalSizeClass.unspecified;
  }

  /// 没有缝，或还没读到时，返回 null。
  static FoldSeam? foldOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WindowLayoutScope>();
    return scope?.fold;
  }

  /// 左右安全区分开相加。没有 host 时 size class 按 [HorizontalSizeClass.unspecified]。
  static WindowLayout layoutOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return WindowLayout.resolve(
      width: size.width,
      height: size.height,
      horizontalPadding: padding.left + padding.right,
      sizeClass: sizeClassOf(context),
    );
  }

  @override
  bool updateShouldNotify(WindowLayoutScope oldWidget) =>
      sizeClass != oldWidget.sizeClass || fold != oldWidget.fold;
}

/// 启动后第一帧，以及窗口尺寸变化时，向 iOS 要一次水平 size class。
/// Android 没有这条通道时保持 [HorizontalSizeClass.unspecified]。
class WindowLayoutHost extends StatefulWidget {
  const WindowLayoutHost({super.key, required this.child});

  final Widget child;

  @override
  State<WindowLayoutHost> createState() => _WindowLayoutHostState();
}

class _WindowLayoutHostState extends State<WindowLayoutHost>
    with WidgetsBindingObserver {
  final MethodChannel _channel = const MethodChannel(
    WindowLayout.sizeClassChannel,
  );

  HorizontalSizeClass _sizeClass = HorizontalSizeClass.unspecified;
  FoldSeam? _iosFold;
  var _ticket = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _refresh();
  }

  Future<void> _refresh() async {
    final ticket = ++_ticket;
    final next = await _readSizeClass();
    final fold = await _readFold();
    if (!mounted || ticket != _ticket) return;
    if (next == _sizeClass && fold == _iosFold) return;
    setState(() {
      _sizeClass = next;
      _iosFold = fold;
    });
  }

  Future<HorizontalSizeClass> _readSizeClass() async {
    try {
      final value = await _channel.invokeMethod<String>(
        WindowLayout.sizeClassMethod,
      );
      return HorizontalSizeClass.fromChannel(value);
    } catch (_) {
      return HorizontalSizeClass.unspecified;
    }
  }

  /// Android 没有这个方法。失败就当作没有 iOS 折痕，页面继续按步骤 1 到 6 显示。
  Future<FoldSeam?> _readFold() async {
    try {
      final value = await _channel.invokeMethod<Object>(
        WindowLayout.foldMethod,
      );
      return foldSeamFromChannel(value);
    } catch (_) {
      return null;
    }
  }

  FoldSeam? _seamFromFeatures(BuildContext context) {
    for (final feature in MediaQuery.displayFeaturesOf(context)) {
      final seam = foldSeamFromFeature(
        type: switch (feature.type) {
          DisplayFeatureType.fold => 'fold',
          DisplayFeatureType.hinge => 'hinge',
          DisplayFeatureType.cutout => 'cutout',
          DisplayFeatureType.unknown => 'unknown',
        },
        posture: switch (feature.state) {
          DisplayFeatureState.postureHalfOpened => 'halfOpened',
          DisplayFeatureState.postureFlat => 'flat',
          DisplayFeatureState.unknown => 'unknown',
        },
        left: feature.bounds.left,
        top: feature.bounds.top,
        width: feature.bounds.width,
        height: feature.bounds.height,
      );
      if (seam != null) return seam;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fold = _seamFromFeatures(context) ?? _iosFold;
    return WindowLayoutScope(
      sizeClass: _sizeClass,
      fold: fold,
      child: widget.child,
    );
  }
}
