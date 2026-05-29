import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_core/cs_core.dart';
import 'package:cs_ui/cs_ui.dart';
import 'router/app_router.dart' show appRouterProvider;
import 'utils/app_orientation.dart';
import 'design/hanzi_design_spec.dart';
import 'design/hanzi_shared_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppOrientation.lockLandscape();
  await CsClient.initialize(
    supabaseUrl: 'https://ljmkxoptnzimpompabsq.supabase.co',
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqbWt4b3B0bnppbXBvbXBhYnNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MzgxMzIsImV4cCI6MjA5MTIxNDEzMn0.CUbc6E49wyt-9WV2978T5kvMsW7CkqUwKn1o_1xBrZw',
    appId: 'hanzi-cursor',
    urlScheme: 'mountainhanzicursor',
    environment: kReleaseMode ? CsEnvironment.prod : CsEnvironment.dev,
  );
  runApp(const ProviderScope(child: HanziApp()));
}

class HanziApp extends ConsumerWidget {
  const HanziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return ScreenUtilInit(
      designSize: AppOrientation.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => CsApp.router(
        title: '宝宝识字',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // auth guard 会根据登录状态决定实际跳到 /login 还是 /
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HanziDesignSpec.surfaceWarm,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CsImage(
              configKey: 'splash_bg_canvas_image',
              description: 'Splash 全屏绘本风背景',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: CsImage(
              configKey: 'splash_decor_top_right_image',
              description: '右上装饰',
              width: 105.w,
              height: 89.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 15.w,
            top: 46.h,
            child: CsImage(
              configKey: 'splash_decor_top_left_icon',
              description: '左上星形装饰',
              width: 29.w,
              height: 29.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: CsImage(
              configKey: 'splash_decor_bottom_left_image',
              description: '左下装饰',
              width: 35.w,
              height: 96.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 32.w,
            bottom: 28.h,
            child: CsImage(
              configKey: 'splash_decor_bottom_right_image',
              description: '右下装饰',
              width: 48.w,
              height: 47.h,
              fit: BoxFit.contain,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: HanziDesignSpec.pagePaddingH.w,
                vertical: HanziDesignSpec.pagePaddingV.h,
              ),
              child: Row(
                key: const Key('hanzi-splash-landscape'),
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 38,
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: HanziSurfaceCard(
                          padding: EdgeInsets.all(20.w),
                          shadowColor: HanziDesignSpec.cardShadowBlue,
                          child: SizedBox(
                            width: 200.w,
                            height: 220.h,
                            child: const Center(
                              child: CsImage(
                                configKey: 'img_splash_logo',
                                description: 'App Logo',
                                width: 160,
                                height: 180,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: HanziDesignSpec.sectionGap.w),
                  Expanded(
                    flex: 62,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '宝宝识字',
                            style: HanziDesignSpec.hubTitleStyle.copyWith(
                              fontSize: HanziDesignSpec.hubTitleStyle.fontSize,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '趣味学汉字，快乐每一天！',
                            style: HanziDesignSpec.hubSubtitleStyle,
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CsImage(
                                configKey: 'splash_chip_left_icon',
                                description: '快乐学左侧图标',
                                width: 17.w,
                                height: 22.h,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF30BBB9),
                                  borderRadius: BorderRadius.circular(28.r),
                                  border: Border.all(
                                    color: const Color(0xFF3FBEBD),
                                  ),
                                ),
                                child: Text(
                                  '快乐学',
                                  style: TextStyle(
                                    color: const Color(0xFFE1F4F4),
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              CsImage(
                                configKey: 'splash_chip_right_icon',
                                description: '快乐学右侧图标',
                                width: 18.w,
                                height: 21.h,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: 40.w,
                            height: 40.w,
                            child: const CircularProgressIndicator(
                              color: HanziDesignSpec.headerBlue,
                              strokeWidth: 3,
                              backgroundColor: Color(0xFFD5ECFB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
