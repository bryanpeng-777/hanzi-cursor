"""
探查灯塔看板「探索分析」面板中的过滤器 UI，截图并提取字段名
"""
import asyncio, json, sys, time
from pathlib import Path
from playwright.async_api import async_playwright

AUTH_FILE = Path.home() / ".claude/skills/beacon-data-fetcher/runtime/beacon_auth_state.json"
URL = "https://beacon.woa.com/datainsight/camp/PanelMax/58710/New_event_Card_Max/275429"
OUT_DIR = Path("/tmp/beacon_explore")
OUT_DIR.mkdir(exist_ok=True)

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(storage_state=str(AUTH_FILE), viewport={"width": 1920, "height": 1080})
        page = await ctx.new_page()

        print("1. 打开看板页面...", flush=True)
        await page.goto(URL, wait_until="domcontentloaded", timeout=60000)

        # 等待表格数据加载
        for i in range(30):
            rows = await page.query_selector_all(".el-table__body tr")
            print(f"   等待 {i*2}s, 表格行数={len(rows)}", flush=True)
            if len(rows) > 3:
                break
            await asyncio.sleep(2)

        await page.screenshot(path=str(OUT_DIR / "01_page_loaded.png"))
        print("   截图: 01_page_loaded.png", flush=True)

        # 点击「探索分析」按钮
        print("2. 点击探索分析...", flush=True)
        result = await page.evaluate("""() => {
            const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT);
            const candidates = [];
            while (walker.nextNode()) {
                const el = walker.currentNode;
                if (el.offsetParent === null && el.tagName !== 'BODY') continue;
                const text = (el.innerText || el.textContent || '').trim().substring(0, 50);
                if (text.includes('探索分析')) {
                    const rect = el.getBoundingClientRect();
                    if (rect.y < 250 && rect.width < 300) {
                        candidates.push({tag: el.tagName, text: text.substring(0,30), x: rect.x, y: rect.y, w: rect.width, h: rect.height,
                            cls: el.className.substring(0,50)});
                    }
                }
            }
            return candidates;
        }""")
        print(f"   探索分析候选: {json.dumps(result[:3], ensure_ascii=False)}", flush=True)

        # 点击探索分析
        await page.mouse.click(213, 194)
        await asyncio.sleep(2)
        await page.screenshot(path=str(OUT_DIR / "02_explore_panel_open.png"))
        print("   截图: 02_explore_panel_open.png", flush=True)

        # 查找过滤器相关元素
        print("3. 分析过滤器 UI...", flush=True)
        filter_info = await page.evaluate("""() => {
            const results = [];
            const all = document.querySelectorAll('*');
            for (const el of all) {
                if (el.offsetParent === null) continue;
                const text = (el.innerText || el.textContent || '').trim();
                if (text.includes('过滤') || text.includes('筛选') || text.includes('filter') ||
                    text.includes('版本') || text.includes('appver') || text.includes('app_ver') ||
                    text.includes('version') || text.includes('添加条件') || text.includes('添加过滤')) {
                    const rect = el.getBoundingClientRect();
                    if (rect.width > 0 && rect.width < 500) {
                        results.push({
                            tag: el.tagName,
                            text: text.substring(0, 60),
                            x: Math.round(rect.x), y: Math.round(rect.y),
                            w: Math.round(rect.width), h: Math.round(rect.height),
                            cls: el.className.substring(0, 60)
                        });
                    }
                }
            }
            return results.slice(0, 20);
        }""")
        print(f"   过滤器相关元素:", flush=True)
        for item in filter_info:
            print(f"     {json.dumps(item, ensure_ascii=False)}", flush=True)

        # 截图看面板内容
        await page.screenshot(path=str(OUT_DIR / "03_filter_elements.png"))

        # 查找「已过滤」或「+」添加条件按钮
        print("4. 查找添加过滤条件入口...", flush=True)
        add_filter = await page.evaluate("""() => {
            const results = [];
            const all = document.querySelectorAll('*');
            for (const el of all) {
                if (el.offsetParent === null) continue;
                const text = (el.innerText || '').trim();
                const rect = el.getBoundingClientRect();
                // 查找可点击的小元素，含有「+」或「添加」或「过滤」
                if (rect.width > 0 && rect.width < 200 && rect.height < 60) {
                    if (text === '+' || text.includes('添加') || 
                        (text.includes('过滤') && text.length < 20)) {
                        results.push({
                            tag: el.tagName, text: text,
                            x: Math.round(rect.x), y: Math.round(rect.y),
                            w: Math.round(rect.width), h: Math.round(rect.height),
                            cls: el.className.substring(0, 80)
                        });
                    }
                }
            }
            return results.slice(0, 15);
        }""")
        print(f"   添加过滤候选:", flush=True)
        for item in add_filter:
            print(f"     {json.dumps(item, ensure_ascii=False)}", flush=True)

        # 尝试点击过滤区域（y < 300 的「+」或「已过滤」）
        # 先截图当前面板全貌
        await page.screenshot(path=str(OUT_DIR / "04_panel_full.png"), full_page=False)

        # 滚动并截图左侧面板
        left_panel = await page.query_selector('[class*="setting"], [class*="panel"], [class*="filter"]')
        if left_panel:
            box = await left_panel.bounding_box()
            print(f"   左侧面板 box: {box}", flush=True)

        # 截取左侧区域
        await page.screenshot(path=str(OUT_DIR / "05_left_area.png"),
                               clip={"x": 0, "y": 150, "width": 450, "height": 700})
        print("   截图: 05_left_area.png (左侧面板区域)", flush=True)

        # 找「已过滤 1 项」的点击入口
        print("5. 点击已过滤区域...", flush=True)
        filtered_btn = await page.evaluate("""() => {
            const all = document.querySelectorAll('*');
            for (const el of all) {
                if (el.offsetParent === null) continue;
                const text = (el.innerText || '').trim();
                if (text.includes('已过滤') || text.includes('过滤条件')) {
                    const rect = el.getBoundingClientRect();
                    if (rect.width > 0 && rect.width < 400) {
                        return {text, x: Math.round(rect.x), y: Math.round(rect.y),
                                w: Math.round(rect.width), h: Math.round(rect.height),
                                tag: el.tagName, cls: el.className.substring(0, 80)};
                    }
                }
            }
            return null;
        }""")
        print(f"   已过滤按钮: {json.dumps(filtered_btn, ensure_ascii=False)}", flush=True)

        if filtered_btn:
            cx = filtered_btn['x'] + filtered_btn['w'] // 2
            cy = filtered_btn['y'] + filtered_btn['h'] // 2
            await page.mouse.click(cx, cy)
            await asyncio.sleep(1.5)
            await page.screenshot(path=str(OUT_DIR / "06_after_click_filter.png"))
            await page.screenshot(path=str(OUT_DIR / "06_left_after_click.png"),
                                   clip={"x": 0, "y": 150, "width": 500, "height": 800})
            print("   截图: 06_after_click_filter.png", flush=True)

            # 再次扫描页面内容，找版本字段
            print("6. 扫描过滤面板内容...", flush=True)
            panel_content = await page.evaluate("""() => {
                const results = [];
                const all = document.querySelectorAll('*');
                for (const el of all) {
                    if (el.offsetParent === null) continue;
                    const text = (el.innerText || '').trim();
                    const rect = el.getBoundingClientRect();
                    if (rect.x < 600 && rect.y > 150 && rect.width > 10 && rect.width < 450 
                        && rect.height < 50 && text.length > 0 && text.length < 60
                        && el.children.length < 3) {
                        results.push({tag: el.tagName, text, x: Math.round(rect.x), y: Math.round(rect.y)});
                    }
                }
                // 按 y 排序
                results.sort((a,b) => a.y - b.y);
                // 去重
                const seen = new Set();
                return results.filter(r => {
                    const key = r.text;
                    if (seen.has(key)) return false;
                    seen.add(key);
                    return true;
                }).slice(0, 40);
            }""")
            print("   面板内容（左侧）:", flush=True)
            for item in panel_content:
                print(f"     y={item['y']:3d} [{item['tag']}] {item['text']}", flush=True)

        await browser.close()
        print("\n完成！截图保存在 /tmp/beacon_explore/", flush=True)

asyncio.run(main())
