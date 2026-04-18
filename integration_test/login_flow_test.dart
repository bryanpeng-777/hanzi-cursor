import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cs_framework/cs_framework.dart';
import 'package:hanzi_app/main.dart' as app;

/// 登录关键链路集成测试
///
/// 测试场景（真实 App 启动 + 真实 Supabase 连接）：
/// IT1 - 冷启动无 session → SplashScreen → 出现登录页
/// IT2 - 登录页点「跳过」→ 匿名登录 → 进入主页
/// IT3 - 已有 session → 重新进入主页路由 → 不再跳回登录页
/// IT4 - 登录页点「忘记密码？」→ 出现找回密码页
///
/// 运行方式（需连接模拟器）：
///   flutter test integration_test/login_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── 工具：等待 SplashScreen 结束（2 秒动画 + 缓冲）────────────────────────
  Future<void> waitForSplash(WidgetTester tester) async {
    // SplashScreen 有 2 秒 Timer，pumpAndSettle 默认 100ms 超时会提前退出
    // 用 pump(Duration) 精确推进假时间
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  // ── IT1：冷启动无 session → 显示登录页 ──────────────────────────────────
  testWidgets('IT1: 无 session 冷启动 → SplashScreen → 登录页', (tester) async {
    // 确保无 session（CsClient 首次调用 main() 时会初始化）
    app.main();
    await tester.pump(); // 第一帧
    await tester.pump(const Duration(milliseconds: 100)); // 等 CsClient 初始化

    // 如有残留 session 则注销
    if (AuthManager.isLoggedIn) {
      await AuthManager.signOut();
      await tester.pumpAndSettle();
    }

    // 等 SplashScreen 走完
    await waitForSplash(tester);

    // ── 验证 ─────────────────────────────────────────────────────────────
    // 登录页标题（我们传入的 title 参数）
    expect(find.text('宝宝识字'), findsWidgets);
    // 「登录」「注册」Tab 都在（可能不止一个，用 findsWidgets）
    expect(find.text('登录'), findsWidgets);
    expect(find.text('注册'), findsWidgets);
    // 跳过按钮是登录页最独特的标识，findsOneWidget
    expect(find.text('跳过，先逛逛'), findsOneWidget);
    // 没有主页的 Tab 导航（说明没进主页）
    expect(find.text('拼音'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 2)));

  // ── IT2：点「跳过」→ 匿名登录 → 进入主页 ────────────────────────────────
  testWidgets('IT2: 点击「跳过」→ 匿名登录 → 出现主页底部导航', (tester) async {
    // 确保无 session，重新进入登录页
    if (AuthManager.isLoggedIn) await AuthManager.signOut();
    app.main();
    await tester.pump();
    await waitForSplash(tester);

    // 确认在登录页
    expect(find.text('跳过，先逛逛'), findsOneWidget);

    // ── 点击「跳过，先逛逛」────────────────────────────────────────────────
    await tester.tap(find.text('跳过，先逛逛'));
    // 等待匿名登录网络请求 + 路由跳转
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // ── 验证进入主页 ──────────────────────────────────────────────────────
    // 主页底部 Tab 出现（拼音 Tab 是 index 0，始终可见）
    expect(find.text('拼音'), findsOneWidget,
        reason: '应该出现主页底部导航 Tab');
    // 登录页的跳过按钮消失
    expect(find.text('跳过，先逛逛'), findsNothing);
    // 确认 Supabase 已有用户
    expect(AuthManager.isLoggedIn, isTrue);
    expect(AuthManager.isAnonymous, isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));

  // ── IT3：已有 session → 不再重定向到登录页 ────────────────────────────────
  testWidgets('IT3: 已有 session → 访问主页路由不跳回登录页', (tester) async {
    // 依赖 IT2 已经完成匿名登录，或手动确保已登录
    if (!AuthManager.isLoggedIn) {
      await AuthManager.signInAnonymously();
    }

    app.main();
    await tester.pump();
    await waitForSplash(tester);

    // ── 验证直接进入主页，无登录页 ────────────────────────────────────────
    expect(find.text('跳过，先逛逛'), findsNothing,
        reason: '已登录用户不应看到登录页');
    expect(find.text('拼音'), findsOneWidget,
        reason: '应该直接显示主页底部导航');
  }, timeout: const Timeout(Duration(minutes: 2)));

  // ── IT4：登录页点「忘记密码？」→ 找回密码页 ──────────────────────────────
  testWidgets('IT4: 点击「忘记密码？」→ 出现找回密码页', (tester) async {
    // 确保在登录页
    if (AuthManager.isLoggedIn) await AuthManager.signOut();
    app.main();
    await tester.pump();
    await waitForSplash(tester);

    expect(find.text('跳过，先逛逛'), findsOneWidget);

    // ── 点击「忘记密码？」────────────────────────────────────────────────────
    await tester.tap(find.text('忘记密码？'));
    await tester.pumpAndSettle();

    // ── 验证出现找回密码页 ────────────────────────────────────────────────
    // CsForgotPasswordPage 有 AppBar 标题「找回密码」或表单提示「输入注册邮箱」
    final onForgotPage = find.text('找回密码').evaluate().isNotEmpty
        || find.text('输入注册邮箱').evaluate().isNotEmpty;
    expect(onForgotPage, isTrue, reason: '应该跳转到找回密码页');
    // 不在主页
    expect(find.text('拼音'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
