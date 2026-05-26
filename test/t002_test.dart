// TDD 合约：T002 - 主壳层 + 底部 Tab 导航

import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanzi_app/design/hanzi_design_spec.dart';
import 'package:hanzi_app/design/hanzi_shared_widgets.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T002 主壳层 + 底部 Tab 导航', () {
    testWidgets('test_tab_switch', (tester) async {
      await tester.binding.setSurfaceSize(const Size(812, 375));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: AppOrientation.designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => CsApp(
            title: 'T002',
            debugShowCheckedModeBanner: false,
            home: child,
          ),
          child: const _TabSwitchHarness(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tab-0')), findsOneWidget);
      await tester.tap(find.text('识字'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tab-1')), findsOneWidget);

      await tester.tap(find.text('游戏'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tab-2')), findsOneWidget);
    });

    test('test_nav_tokens_defined', () {
      expect(HanziDesignSpec.navSelectedBackground, isA<Color>());
      expect(HanziDesignSpec.navBarHeight, greaterThan(0));
      expect(HanziBottomNavBar.defaultItems, hasLength(4));
    });
  });
}

class _TabSwitchHarness extends StatefulWidget {
  const _TabSwitchHarness();

  @override
  State<_TabSwitchHarness> createState() => _TabSwitchHarnessState();
}

class _TabSwitchHarnessState extends State<_TabSwitchHarness> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          Center(key: Key('tab-0'), child: Text('拼音页')),
          Center(key: Key('tab-1'), child: Text('识字页')),
          Center(key: Key('tab-2'), child: Text('游戏页')),
          Center(key: Key('tab-3'), child: Text('学习页')),
        ],
      ),
      bottomNavigationBar: HanziBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: HanziBottomNavBar.defaultItems,
      ),
    );
  }
}
