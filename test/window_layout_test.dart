import 'package:digi_players/core/layout/window_layout.dart';
import 'package:digi_players/core/layout/window_layout_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('窗口判断按尺寸表', () {
    const cases = <_Case>[
      _Case(466, 678, HorizontalSizeClass.compact, 0, false, false),
      _Case(678, 466, HorizontalSizeClass.compact, 0, false, false),
      _Case(678, 466, HorizontalSizeClass.unspecified, 0, false, false),
      _Case(669, 951, HorizontalSizeClass.regular, 0, true, true),
      _Case(669, 951, HorizontalSizeClass.unspecified, 0, true, true),
      _Case(669, 951, HorizontalSizeClass.regular, 84, true, false),
      _Case(951, 669, HorizontalSizeClass.regular, 0, true, true),
      _Case(820, 1180, HorizontalSizeClass.regular, 0, true, true),
      _Case(507, 768, HorizontalSizeClass.regular, 0, true, false),
      _Case(507, 768, HorizontalSizeClass.unspecified, 0, false, false),
      _Case(400, 800, HorizontalSizeClass.unspecified, 0, false, false),
      _Case(1200, 800, HorizontalSizeClass.unspecified, 0, true, true),
    ];

    for (final row in cases) {
      final layout = WindowLayout.resolve(
        width: row.width,
        height: row.height,
        horizontalPadding: row.padding,
        sizeClass: row.sizeClass,
      );
      expect(
        layout.wide,
        row.wide,
        reason: '${row.width}×${row.height} ${row.sizeClass.name} 宽窗口',
      );
      expect(
        layout.canSplit,
        row.canSplit,
        reason: '${row.width}×${row.height} ${row.sizeClass.name} 可双栏',
      );
    }
  });

  test('认不出的通道值当成 unspecified', () {
    expect(
      HorizontalSizeClass.fromChannel(null),
      HorizontalSizeClass.unspecified,
    );
    expect(
      HorizontalSizeClass.fromChannel('phone'),
      HorizontalSizeClass.unspecified,
    );
    expect(
      HorizontalSizeClass.fromChannel('regular'),
      HorizontalSizeClass.regular,
    );
    expect(
      HorizontalSizeClass.fromChannel('compact'),
      HorizontalSizeClass.compact,
    );
  });

  testWidgets('左右安全区分开相加，不用较大的一边乘二', (tester) async {
    // 700 − 10 − 40 = 650，够双栏。若用 max(10, 40) × 2，可用宽度是 620，不够。
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(700, 800),
          padding: EdgeInsets.only(left: 10, right: 40),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: WindowLayoutScope(
            sizeClass: HorizontalSizeClass.regular,
            child: _LayoutLabel(),
          ),
        ),
      ),
    );

    expect(find.text('wide canSplit'), findsOneWidget);
  });

  testWidgets('通道缺失时保持 unspecified', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WindowLayoutHost(child: _SizeClassLabel())),
    );
    await tester.pumpAndSettle();

    expect(find.text('unspecified'), findsOneWidget);
  });

  testWidgets('通道抛错时保持 unspecified', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(WindowLayout.sizeClassChannel),
      (call) async => throw PlatformException(code: 'fail'),
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(WindowLayout.sizeClassChannel),
        null,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(home: WindowLayoutHost(child: _SizeClassLabel())),
    );
    await tester.pumpAndSettle();

    expect(find.text('unspecified'), findsOneWidget);
  });

  testWidgets('窗口尺寸变化时重新读取 size class', (tester) async {
    var answer = 'regular';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(WindowLayout.sizeClassChannel),
      (call) async {
        if (call.method == WindowLayout.foldMethod) {
          return {
            'active': false,
            'left': 0,
            'top': 0,
            'width': 0,
            'height': 0,
          };
        }
        expect(call.method, WindowLayout.sizeClassMethod);
        return answer;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(WindowLayout.sizeClassChannel),
        null,
      );
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: WindowLayoutHost(child: _SizeClassLabel())),
    );
    await tester.pumpAndSettle();
    expect(find.text('regular'), findsOneWidget);

    answer = 'compact';
    tester.view.physicalSize = const Size(466, 678);
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();
    expect(find.text('compact'), findsOneWidget);
  });
}

class _Case {
  const _Case(
    this.width,
    this.height,
    this.sizeClass,
    this.padding,
    this.wide,
    this.canSplit,
  );

  final double width;
  final double height;
  final HorizontalSizeClass sizeClass;
  final double padding;
  final bool wide;
  final bool canSplit;
}

class _LayoutLabel extends StatelessWidget {
  const _LayoutLabel();

  @override
  Widget build(BuildContext context) {
    final layout = WindowLayoutScope.layoutOf(context);
    final label = [
      if (layout.wide) 'wide',
      if (layout.canSplit) 'canSplit',
    ].join(' ');
    return Text(label);
  }
}

class _SizeClassLabel extends StatelessWidget {
  const _SizeClassLabel();

  @override
  Widget build(BuildContext context) {
    return Text(WindowLayoutScope.sizeClassOf(context).name);
  }
}
