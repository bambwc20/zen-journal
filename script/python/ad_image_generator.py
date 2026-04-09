#!/usr/bin/env python3
"""
광고 이미지 + 스토어 스크린샷 자동 생성 파이프라인

HTML/CSS 템플릿 + Playwright 스크린샷 + Pillow LANCZOS 다운스케일
- 광고 이미지 19종 (Google/Meta/TikTok/ASA)
- 스토어 스크린샷 Apple 5장 + Google 5장 + Feature Graphic 1장

사용법:
  python3 ad_image_generator.py --config config.json --output ./assets/ads/
  python3 ad_image_generator.py --store --config config.json --output ./docs/store_assets/

TODO (CI 이전 시):
  - assets/fonts/NotoSansKR-Regular.woff2 로컬 포함
  - @font-face src에 local() 우선, url() 폴백 순서 지정
  - 또는 Docker: RUN apt-get install -y fonts-noto-cjk
"""

import asyncio
import json
import argparse
import sys
from pathlib import Path
from string import Template

from PIL import Image
from playwright.async_api import async_playwright

SCRIPT_DIR = Path(__file__).parent
TEMPLATES_DIR = SCRIPT_DIR / "ad_templates"

# ─── 광고 사이즈 정의 ───────────────────────────────────────────────
AD_SIZES = {
    "micro_banner": [
        ("google_mobile_banner", 320, 50, "banner_micro.html"),
        ("google_large_mobile", 320, 100, "banner_micro.html"),
        ("google_leaderboard", 728, 90, "banner_micro.html"),
    ],
    "small_banner": [
        ("google_medium_rect", 300, 250, "banner_small.html"),
        ("google_billboard", 970, 250, "banner_small.html"),
    ],
    "skyscraper": [
        ("google_skyscraper", 160, 600, "skyscraper.html"),
        ("google_half_page", 300, 600, "skyscraper.html"),
    ],
    "feed": [
        ("google_landscape", 1200, 628, "feed.html"),
        ("google_square", 1200, 1200, "feed.html"),
        ("google_portrait", 960, 1200, "feed.html"),
        ("meta_feed_square", 1080, 1080, "feed.html"),
        ("meta_feed_portrait", 1080, 1350, "feed.html"),
        ("logo_wide", 1200, 300, "feed.html"),
    ],
    "story": [
        ("meta_story", 1080, 1920, "story.html"),
        ("tiktok_feed", 1080, 1920, "story.html"),
        ("asa_iphone", 1242, 2208, "story.html"),
    ],
}

# 스토어 스크린샷 사이즈
STORE_SIZES = {
    "apple": ("apple_screen", 1320, 2868, "store_screen.html"),
    "google": ("google_screen", 1080, 1920, "store_screen.html"),
    "feature_graphic": ("feature_graphic", 1024, 500, "feature_graphic.html"),
}

MAX_FILE_SIZE = {
    "micro_banner": 150 * 1024,
    "small_banner": 150 * 1024,
    "skyscraper": 150 * 1024,
    "feed": 5 * 1024 * 1024,
    "story": 5 * 1024 * 1024,
    "store": 5 * 1024 * 1024,
}


def _placeholder_icon(size=256):
    """스크린샷/아이콘이 없을 때 사용할 플레이스홀더 생성"""
    img = Image.new("RGB", (size, size), "#6B9B7A")
    path = TEMPLATES_DIR / "_placeholder_icon.png"
    img.save(path)
    return str(path)


def _placeholder_screenshot(w=390, h=844):
    """앱 스크린샷 없을 때 그라디언트 플레이스홀더"""
    img = Image.new("RGB", (w, h), "#F5E6D3")
    path = TEMPLATES_DIR / "_placeholder_screen.png"
    img.save(path)
    return str(path)


def _get_template_params_micro(w, h, config):
    """극소 배너 (320x50, 320x100, 728x90)"""
    is_tall = h >= 100
    return {
        "WIDTH": str(w),
        "HEIGHT": str(h),
        "ICON_SIZE": str(min(h - 10, 36)),
        "FONT_SIZE_HEADLINE": "14" if h <= 50 else "16",
        "FONT_SIZE_SUB": "11" if h <= 50 else "13",
        "FONT_SIZE_CTA": "12" if h <= 50 else "14",
        "CTA_PADDING": "4px 12px" if h <= 50 else "6px 16px",
        "SHOW_SUBTEXT": "block" if is_tall else "none",
        "ICON_PATH": config.get("icon_path", ""),
        "HEADLINE": config.get("headline", ""),
        "SUBTEXT": config.get("subtext", ""),
        "CTA": config.get("cta", "Install"),
    }


def _get_template_params_small(w, h, config):
    """소형 배너 (300x250, 970x250)"""
    is_wide = w > 600
    phone_h = int(h * 0.5) if not is_wide else int(h * 0.7)
    phone_w = int(phone_h * 0.48)
    return {
        "WIDTH": str(w),
        "HEIGHT": str(h),
        "DIRECTION": "row" if is_wide else "column",
        "GAP": "20" if is_wide else "10",
        "PADDING": "20px 30px" if is_wide else "15px",
        "FONT_SIZE_HEADLINE": "22" if is_wide else "18",
        "FONT_SIZE_FEATURE": "13",
        "FONT_SIZE_CTA": "14",
        "CTA_PADDING": "8px 20px",
        "PHONE_W": str(phone_w),
        "PHONE_H": str(phone_h),
        "SCREEN_RADIUS": "12",
        "NOTCH_H": "12",
        "SHOW_PHONE": "block",
        "SHOW_FEATURES": "flex" if is_wide else "none",
        "FEATURES_HTML": _build_features_html(config.get("features", [])[:3]),
        "SCREENSHOT_PATH": config.get("screenshot_path", ""),
        "HEADLINE": config.get("headline", ""),
        "CTA": config.get("cta", "Install Free"),
    }


def _get_template_params_skyscraper(w, h, config):
    """스카이스크래퍼 (160x600, 300x600)"""
    is_narrow = w <= 200
    phone_h = int(h * 0.3)
    phone_w = int(phone_h * 0.48)
    if phone_w > w * 0.85:
        phone_w = int(w * 0.85)
        phone_h = int(phone_w / 0.48)
    return {
        "WIDTH": str(w),
        "HEIGHT": str(h),
        "PADDING": "15px 8px" if is_narrow else "20px 15px",
        "ICON_SIZE": "36" if is_narrow else "48",
        "FONT_SIZE_NAME": "16" if is_narrow else "22",
        "FONT_SIZE_HEADLINE": "11" if is_narrow else "14",
        "FONT_SIZE_FEATURE": "11" if is_narrow else "14",
        "FONT_SIZE_CTA": "12" if is_narrow else "15",
        "CTA_PADDING": "8px 12px" if is_narrow else "10px 20px",
        "PHONE_W": str(phone_w),
        "PHONE_H": str(phone_h),
        "SCREEN_RADIUS": "8" if is_narrow else "12",
        "NOTCH_H": "8" if is_narrow else "14",
        "ICON_PATH": config.get("icon_path", ""),
        "APP_NAME": config.get("app_name", ""),
        "HEADLINE": config.get("headline", ""),
        "SCREENSHOT_PATH": config.get("screenshot_path", ""),
        "FEATURES_HTML": _build_features_html(config.get("features", [])[:3]),
        "CTA": config.get("cta", "Install"),
    }


def _get_template_params_feed(w, h, config):
    """피드/디스플레이 (1080x1080, 1200x628, etc.)"""
    ratio = h / w
    is_landscape = ratio < 0.7
    is_logo = h <= 400
    phone_h = int(h * (0.45 if is_landscape else 0.55))
    phone_w = int(phone_h * 0.48)
    return {
        "WIDTH": str(w),
        "HEIGHT": str(h),
        "PADDING": "30px" if not is_logo else "20px 40px",
        "FONT_SIZE_HEADLINE": "24" if is_logo else ("32" if is_landscape else "40"),
        "FONT_SIZE_SUB": "16" if is_logo else "20",
        "FONT_SIZE_CTA": "16",
        "FONT_SIZE_APPNAME": "16",
        "CTA_PADDING": "10px 24px",
        "BOTTOM_ICON": "36",
        "PHONE_W": str(phone_w),
        "PHONE_H": str(phone_h),
        "SCREEN_RADIUS": "16",
        "NOTCH_H": "18",
        "SHOW_PHONE": "none" if is_logo else "block",
        "SHOW_SUBTEXT": "block",
        "ICON_PATH": config.get("icon_path", ""),
        "APP_NAME": config.get("app_name", ""),
        "HEADLINE": config.get("headline", ""),
        "SUBTEXT": config.get("subtext", ""),
        "SCREENSHOT_PATH": config.get("screenshot_path", ""),
        "CTA": config.get("cta", "Install Free"),
    }


def _get_template_params_story(w, h, config):
    """스토리/전체화면 (1080x1920, 1242x2208)"""
    phone_h = int(h * 0.5)
    phone_w = int(phone_h * 0.48)
    return {
        "WIDTH": str(w),
        "HEIGHT": str(h),
        "PADDING": "40px 30px",
        "FONT_SIZE_HEADLINE": "38",
        "FONT_SIZE_SUB": "20",
        "FONT_SIZE_CTA": "20",
        "CTA_PADDING": "16px 40px",
        "PHONE_W": str(phone_w),
        "PHONE_H": str(phone_h),
        "SCREEN_RADIUS": "24",
        "NOTCH_H": "24",
        "ICON_PATH": config.get("icon_path", ""),
        "APP_NAME": config.get("app_name", ""),
        "HEADLINE": config.get("headline", ""),
        "SUBTEXT": config.get("subtext", ""),
        "SCREENSHOT_PATH": config.get("screenshot_path", ""),
        "CTA": config.get("cta", "Install Free"),
    }


def _get_template_params_store(w, h, config, idx=0):
    """스토어 스크린샷 (Apple 1320x2868, Google 1080x1920)"""
    is_apple = w > 1200
    captions = config.get("captions", [])
    caption = captions[idx] if idx < len(captions) else config.get("headline", "")
    subcaptions = config.get("subcaptions", [])
    subcaption = subcaptions[idx] if idx < len(subcaptions) else config.get("subtext", "")
    screenshots = config.get("screenshots", [])
    screenshot = screenshots[idx] if idx < len(screenshots) else config.get("screenshot_path", "")
    phone_h = int(h * 0.65)
    phone_w = int(phone_h * 0.48)
    return {
        "WIDTH": str(w),
        "HEIGHT": str(h),
        "PADDING": "40px 30px" if is_apple else "30px 20px",
        "TOP_PAD": "60" if is_apple else "40",
        "FONT_SIZE_CAPTION": "52" if is_apple else "40",
        "FONT_SIZE_SUB": "28" if is_apple else "22",
        "PHONE_W": str(phone_w),
        "PHONE_H": str(phone_h),
        "SCREEN_RADIUS": "28" if is_apple else "20",
        "NOTCH_H": "28" if is_apple else "20",
        "CAPTION": caption,
        "SUBCAPTION": subcaption,
        "SCREENSHOT_PATH": screenshot,
    }


def _get_template_params_feature_graphic(config):
    """Feature Graphic (1024x500)"""
    return {
        "ICON_PATH": config.get("icon_path", ""),
        "APP_NAME": config.get("app_name", ""),
        "TAGLINE": config.get("subtext", ""),
        "SCREENSHOT_PATH": config.get("screenshot_path", ""),
        "FEATURES_HTML": _build_features_html(config.get("features", [])[:4]),
    }


def _build_features_html(features):
    items = []
    for f in features:
        items.append(f'<div class="feature-item"><span class="check">✓</span> {f}</div>')
    return "\n    ".join(items)


def _fill_template(template_name, params):
    """HTML 템플릿 읽고 {{KEY}} 플레이스홀더 치환"""
    html = (TEMPLATES_DIR / template_name).read_text(encoding="utf-8")
    # base.css 경로를 절대 경로로 변환
    css_path = (TEMPLATES_DIR / "base.css").as_uri()
    html = html.replace('href="base.css"', f'href="{css_path}"')
    for key, val in params.items():
        html = html.replace("{{" + key + "}}", str(val))
    return html


async def _ensure_fonts(page):
    """폰트 로딩 완료 대기 — Google Fonts CDN + document.fonts.ready"""
    await page.wait_for_load_state("networkidle")
    await page.evaluate("() => document.fonts.ready")
    loaded = await page.evaluate("""() => {
        return document.fonts.check("16px Nunito") &&
               document.fonts.check("16px 'Noto Sans KR'");
    }""")
    if not loaded:
        await page.wait_for_timeout(2000)
        await page.evaluate("() => document.fonts.ready")


async def _render_and_save(page, html_content, output_path, w, h, max_size):
    """2x 렌더링 → LANCZOS 다운스케일 → 파일 크기 검증"""
    # 임시 HTML 파일 저장
    tmp_html = TEMPLATES_DIR / "_tmp_render.html"
    tmp_html.write_text(html_content, encoding="utf-8")

    await page.set_viewport_size({"width": w, "height": h})
    await page.goto(tmp_html.as_uri())
    await _ensure_fonts(page)

    # 2x 스크린샷
    tmp_png = output_path.with_suffix(".tmp.png")
    await page.screenshot(path=str(tmp_png), full_page=False)

    # LANCZOS 다운스케일 (2x → 1x)
    img = Image.open(tmp_png)
    img = img.resize((w, h), Image.LANCZOS)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(str(output_path), format="PNG", optimize=True)
    tmp_png.unlink(missing_ok=True)

    # 파일 크기 검증 → 초과 시 JPEG 전환
    if output_path.stat().st_size > max_size:
        jpg_path = output_path.with_suffix(".jpg")
        img.save(str(jpg_path), format="JPEG", quality=85, optimize=True)
        output_path.unlink()
        print(f"  → PNG 초과({output_path.stat().st_size if output_path.exists() else 0}B), JPEG 전환: {jpg_path.name}")
        return jpg_path

    return output_path


def _resolve_paths(config):
    """config의 상대 경로를 절대 경로(file URI)로 변환"""
    base = Path(config.get("_base_dir", ".")).resolve()
    for key in ("icon_path", "screenshot_path"):
        val = config.get(key, "")
        if val and not val.startswith("file://") and not val.startswith("/") and not val.startswith("http"):
            config[key] = str((base / val).resolve())
    screenshots = config.get("screenshots", [])
    config["screenshots"] = [
        str((base / s).resolve()) if s and not s.startswith(("/", "file://", "http")) else s
        for s in screenshots
    ]
    return config


# ─── 광고 이미지 생성 ────────────────────────────────────────────────

async def generate_ads(config, output_dir):
    """19종 광고 이미지 일괄 생성"""
    output_dir = Path(output_dir)
    results = []

    async with async_playwright() as p:
        browser = await p.chromium.launch()
        context = await browser.new_context(device_scale_factor=2)
        page = await context.new_page()

        for category, sizes in AD_SIZES.items():
            max_size = MAX_FILE_SIZE[category]
            for name, w, h, template in sizes:
                print(f"[AD] {name} ({w}x{h})...", end=" ")

                if category == "micro_banner":
                    params = _get_template_params_micro(w, h, config)
                elif category == "small_banner":
                    params = _get_template_params_small(w, h, config)
                elif category == "skyscraper":
                    params = _get_template_params_skyscraper(w, h, config)
                elif category == "feed":
                    params = _get_template_params_feed(w, h, config)
                elif category == "story":
                    params = _get_template_params_story(w, h, config)
                else:
                    continue

                html = _fill_template(template, params)

                # 채널별 하위 폴더
                if name.startswith("google") or name.startswith("logo"):
                    sub = "google"
                elif name.startswith("meta"):
                    sub = "meta"
                elif name.startswith("tiktok"):
                    sub = "tiktok"
                elif name.startswith("asa"):
                    sub = "asa"
                else:
                    sub = "other"

                out_path = output_dir / sub / f"{name}_{w}x{h}.png"
                result = await _render_and_save(page, html, out_path, w, h, max_size)
                results.append(result)
                print(f"OK → {result.name}")

        await browser.close()

    return results


# ─── 스토어 스크린샷 생성 ────────────────────────────────────────────

async def generate_store(config, output_dir):
    """스토어 스크린샷 (Apple 5장 + Google 5장 + Feature Graphic)"""
    output_dir = Path(output_dir)
    results = []
    num_screens = min(len(config.get("screenshots", [])), 5)
    if num_screens == 0:
        num_screens = min(len(config.get("captions", [])), 5)
    if num_screens == 0:
        num_screens = 1

    async with async_playwright() as p:
        browser = await p.chromium.launch()
        context = await browser.new_context(device_scale_factor=2)
        page = await context.new_page()
        max_size = MAX_FILE_SIZE["store"]

        # Apple 스크린샷
        apple_name, apple_w, apple_h, apple_tpl = STORE_SIZES["apple"]
        for i in range(num_screens):
            print(f"[STORE] {apple_name}_{i+1:02d} ({apple_w}x{apple_h})...", end=" ")
            params = _get_template_params_store(apple_w, apple_h, config, i)
            html = _fill_template(apple_tpl, params)
            out_path = output_dir / f"{apple_name}_{i+1:02d}.png"
            result = await _render_and_save(page, html, out_path, apple_w, apple_h, max_size)
            results.append(result)
            print(f"OK → {result.name}")

        # Google 스크린샷
        gp_name, gp_w, gp_h, gp_tpl = STORE_SIZES["google"]
        for i in range(num_screens):
            print(f"[STORE] {gp_name}_{i+1:02d} ({gp_w}x{gp_h})...", end=" ")
            params = _get_template_params_store(gp_w, gp_h, config, i)
            html = _fill_template(gp_tpl, params)
            out_path = output_dir / f"{gp_name}_{i+1:02d}.png"
            result = await _render_and_save(page, html, out_path, gp_w, gp_h, max_size)
            results.append(result)
            print(f"OK → {result.name}")

        # Feature Graphic
        fg_name, fg_w, fg_h, fg_tpl = STORE_SIZES["feature_graphic"]
        print(f"[STORE] {fg_name} ({fg_w}x{fg_h})...", end=" ")
        params = _get_template_params_feature_graphic(config)
        html = _fill_template(fg_tpl, params)
        out_path = output_dir / f"{fg_name}.png"
        result = await _render_and_save(page, html, out_path, fg_w, fg_h, max_size)
        results.append(result)
        print(f"OK → {result.name}")

        await browser.close()

    return results


# ─── 검증 ────────────────────────────────────────────────────────────

def verify_results(results, expected_sizes=None):
    """생성 결과 검증: 파일 존재, 해상도, 크기"""
    print(f"\n{'='*60}")
    print(f"검증 결과 ({len(results)}개 파일)")
    print(f"{'='*60}")

    errors = []
    for path in results:
        path = Path(path)
        if not path.exists():
            errors.append(f"❌ 파일 없음: {path}")
            continue

        img = Image.open(path)
        size_kb = path.stat().st_size / 1024
        size_str = f"{size_kb:.1f}KB" if size_kb < 1024 else f"{size_kb/1024:.1f}MB"
        print(f"  ✅ {path.name:40s} {img.size[0]:>5d}x{img.size[1]:<5d} {size_str:>10s}")

    if errors:
        print(f"\n⚠️ 오류 {len(errors)}건:")
        for e in errors:
            print(f"  {e}")
    else:
        print(f"\n✅ 전체 {len(results)}개 파일 검증 통과")

    return len(errors) == 0


# ─── CLI ────────────────────────────────────────────────────────────

def load_config(config_path):
    """JSON 설정 로드 + 기본값 적용"""
    with open(config_path, "r", encoding="utf-8") as f:
        config = json.load(f)
    config["_base_dir"] = str(Path(config_path).parent)

    # 기본값
    config.setdefault("app_name", "App")
    config.setdefault("headline", "Your App Name")
    config.setdefault("subtext", "")
    config.setdefault("cta", "Install Free")
    config.setdefault("features", [])
    config.setdefault("captions", [])
    config.setdefault("subcaptions", [])
    config.setdefault("screenshots", [])

    # 아이콘/스크린샷 기본 플레이스홀더
    if not config.get("icon_path"):
        config["icon_path"] = _placeholder_icon()
    if not config.get("screenshot_path"):
        config["screenshot_path"] = _placeholder_screenshot()

    return _resolve_paths(config)


async def main():
    parser = argparse.ArgumentParser(description="광고 이미지 & 스토어 스크린샷 자동 생성")
    parser.add_argument("--config", required=True, help="설정 JSON 파일 경로")
    parser.add_argument("--output", required=True, help="출력 디렉토리")
    parser.add_argument("--ads", action="store_true", help="광고 이미지 생성 (19종)")
    parser.add_argument("--store", action="store_true", help="스토어 스크린샷 생성")
    parser.add_argument("--all", action="store_true", help="광고 + 스토어 전부 생성")
    parser.add_argument("--verify-only", action="store_true", help="기존 파일 검증만")
    args = parser.parse_args()

    config = load_config(args.config)
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)

    if args.verify_only:
        files = list(output.rglob("*.png")) + list(output.rglob("*.jpg"))
        verify_results(files)
        return

    all_results = []

    if args.ads or args.all:
        print("\n🎨 광고 이미지 생성 시작...\n")
        ad_results = await generate_ads(config, output)
        all_results.extend(ad_results)

    if args.store or args.all:
        store_out = output if args.store and not args.all else output / "store"
        print("\n📱 스토어 스크린샷 생성 시작...\n")
        store_results = await generate_store(config, store_out)
        all_results.extend(store_results)

    if not args.ads and not args.store and not args.all:
        print("옵션을 지정하세요: --ads, --store, 또는 --all")
        sys.exit(1)

    verify_results(all_results)


if __name__ == "__main__":
    asyncio.run(main())
