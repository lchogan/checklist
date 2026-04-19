"""Capture state screenshots from Gem App v2.html prototype.

Comprehensive capture: seeded + true-empty states, every sheet variant, and
every interactive affordance exposed by the prototype.

Approach:
- Seed-by-reload: inject the desired app state into localStorage then reload
  the page. AppProvider reads localStorage on mount, so this is the reliable
  way to produce arbitrary states. `app.reset()` does NOT empty data — it
  restores the seeded INITIAL_STATE, which is why earlier captures looked the
  same as the seed.
- Interact-by-click: after navigating, click real buttons (by text or by
  position inside the phone frame) to trigger sheets/menus/inline forms.
"""
from __future__ import annotations

import json
import pathlib
from playwright.sync_api import sync_playwright, Page, expect

PROTOTYPE = pathlib.Path(
    "/tmp/claude-design-h-dgHpZ8CANjWOhp9g17FMaA/checklist-app/project/Gem App v2.html"
)
OUT = pathlib.Path(__file__).resolve().parent.parent / "docs" / "superpowers" / "prototype-captures"
OUT.mkdir(parents=True, exist_ok=True)

# ── Helper: inject state, reload, wait for prototype to be live ─────────
EMPTY_STATE = {"tags": [], "templates": [], "archivedTemplateIds": [], "runs": []}


def inject_state_and_reload(page: Page, state: dict | None) -> None:
    """Set localStorage to the given state (or clear it to re-seed) and reload.

    Passing `state=None` clears localStorage so the next mount falls back to
    INITIAL_STATE (the seeded data).
    """
    page.evaluate(
        """(stateObj) => {
            if (stateObj === null) {
                localStorage.removeItem('gem-app-state');
            } else {
                localStorage.setItem('gem-app-state', JSON.stringify(stateObj));
            }
        }""",
        state,
    )
    page.reload()
    page.wait_for_selector(".phone", timeout=10000)
    page.wait_for_function("() => window.__gemApp != null", timeout=5000)
    page.wait_for_timeout(400)


def nav(page: Page, screen: str, params: dict | None = None) -> None:
    params_js = json.dumps(params or {})
    page.evaluate(f"() => window.__gemApp.nav({json.dumps(screen)}, {params_js})")
    page.wait_for_timeout(350)


def screenshot_phone(page: Page, name: str) -> None:
    phone = page.locator(".phone").first
    phone.wait_for(state="visible", timeout=5000)
    phone.screenshot(path=str(OUT / name))
    print(f"  {name}")


def click_in_phone(page: Page, selector: str, nth: int = 0) -> None:
    """Click a locator scoped to inside the phone frame."""
    loc = page.locator(f".phone {selector}").nth(nth)
    loc.click(timeout=2000)
    page.wait_for_timeout(300)


def click_text_in_phone(page: Page, text: str) -> None:
    page.locator(".phone").locator(f"text={text}").first.click(timeout=2000)
    page.wait_for_timeout(300)


def click_button_in_phone(page: Page, contains: str) -> None:
    page.locator(".phone").get_by_role("button", name=contains, exact=False).first.click(timeout=2000)
    page.wait_for_timeout(300)


def click_top_right_icon(page: Page) -> None:
    """Click the top-right icon button inside the phone (kebab / add)."""
    phone_box = page.locator(".phone").first.bounding_box()
    if not phone_box:
        raise RuntimeError("phone not visible")
    x = phone_box["x"] + phone_box["width"] - 34
    y = phone_box["y"] + 74
    page.mouse.click(x, y)
    page.wait_for_timeout(300)


def type_in_focused(page: Page, text: str) -> None:
    page.keyboard.type(text, delay=12)
    page.wait_for_timeout(150)


# ── State builders ──────────────────────────────────────────────────────

def seed_state_one_list_no_runs() -> dict:
    """Home with exactly one checklist, no runs."""
    return {
        "tags": [],
        "templates": [{
            "id": "tpl-a", "name": "Road Trip", "category": "Travel",
            "createdAt": "2026-04-10",
            "items": [
                {"id": "r1", "text": "Charger", "tags": []},
                {"id": "r2", "text": "Sunglasses", "tags": []},
                {"id": "r3", "text": "Snacks", "tags": []},
            ],
        }],
        "archivedTemplateIds": [],
        "runs": [],
    }


def seed_state_live_plus_finished() -> dict:
    """A list with finished runs but no live run — 'last completed N ago'."""
    from datetime import datetime, timedelta, timezone
    now = datetime.now(timezone.utc)
    days = lambda n: (now - timedelta(days=n)).isoformat().replace("+00:00", "Z")
    return {
        "tags": [],
        "templates": [{
            "id": "tpl-gym", "name": "Gym Bag", "category": "Daily",
            "createdAt": "2026-04-01",
            "items": [
                {"id": "g1", "text": "Shoes", "tags": []},
                {"id": "g2", "text": "Shorts", "tags": []},
                {"id": "g3", "text": "Water bottle", "tags": []},
                {"id": "g4", "text": "Headphones", "tags": []},
            ],
        }],
        "archivedTemplateIds": [],
        "runs": [
            {"id": "r-y", "templateId": "tpl-gym", "label": "",
             "startedAt": days(1), "finishedAt": days(1),
             "status": "finished",
             "checks": {"g1": "complete", "g2": "complete", "g3": "complete", "g4": "complete"}},
        ],
    }


# ── Capture orchestration ───────────────────────────────────────────────

RESULTS: list[dict] = []


def record(name: str, description: str, status: str = "ok") -> None:
    RESULTS.append({"file": name, "description": description, "status": status})


def capture_all(page: Page) -> None:
    # ── 01–04: Home variants ────────────────────────────────────────
    inject_state_and_reload(page, None)  # restore seed
    nav(page, "home", {})
    screenshot_phone(page, "01-home-seeded.png")
    record("01-home-seeded.png", "Home — seeded grid of 5 lists with live runs")

    inject_state_and_reload(page, EMPTY_STATE)
    nav(page, "home", {})
    screenshot_phone(page, "02-home-empty.png")
    record("02-home-empty.png", "Home — true empty state (no lists)")

    inject_state_and_reload(page, seed_state_one_list_no_runs())
    nav(page, "home", {})
    screenshot_phone(page, "03-home-one-list.png")
    record("03-home-one-list.png", "Home — one list, zero runs")

    # ── 04–12: List screen variants ─────────────────────────────────
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];  // Packing List
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live');
        a.nav('list', { templateId: tpl.id, runId: live.id });
    }""")
    page.wait_for_timeout(350)
    screenshot_phone(page, "04-list-live-single.png")
    record("04-list-live-single.png", "List — single live run (Tokyo / Packing List)")

    # Multi-run: start a 2nd live run on Packing List
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        a.startRun(tpl.id, 'Portland');
        a.nav('list', { templateId: tpl.id, chooseRun: true });
    }""")
    page.wait_for_timeout(400)
    screenshot_phone(page, "05-list-multirun-chooser.png")
    record("05-list-multirun-chooser.png", "List — multi-run chooser sheet open")

    # Multi-run: chooser closed, switcher pill visible
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        const live = a.state.runs.filter(r => r.templateId === tpl.id && r.status === 'live');
        a.nav('list', { templateId: tpl.id, runId: live[0].id });
    }""")
    page.wait_for_timeout(350)
    screenshot_phone(page, "06-list-multirun-switcher.png")
    record("06-list-multirun-switcher.png", "List — 2 live runs, switcher pill shown")

    # Near-complete
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live');
        tpl.items.slice(0, tpl.items.length - 1).forEach(it => {
            if (live.checks[it.id] !== 'complete') a.toggleCheck(live.id, it.id);
        });
        a.nav('list', { templateId: tpl.id, runId: live.id });
    }""")
    page.wait_for_timeout(400)
    screenshot_phone(page, "07-list-near-complete.png")
    record("07-list-near-complete.png", "List — one item left unchecked")

    # All complete — auto-opens CompletionSheet
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[3];  // Gym Bag — small template
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live') ||
                     a.state.runs.find(r => r.templateId === tpl.id);
        let rid;
        if (!live || live.status !== 'live') {
            rid = a.startRun(tpl.id, '');
        } else {
            rid = live.id;
        }
        a.nav('list', { templateId: tpl.id, runId: rid });
    }""")
    page.wait_for_timeout(300)
    # Click each item to check it (triggers auto-sheet when last one flips)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[3];
        const run = a.state.runs.filter(r => r.templateId === tpl.id && r.status === 'live').pop();
        tpl.items.forEach(it => {
            if (run.checks[it.id] !== 'complete') a.toggleCheck(run.id, it.id);
        });
    }""")
    page.wait_for_timeout(600)
    screenshot_phone(page, "08-completion-sheet-all-done.png")
    record("08-completion-sheet-all-done.png", "CompletionSheet — all items checked (auto-opened)")

    # Partial completion sheet: click Finish run while some unchecked
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live');
        a.nav('list', { templateId: tpl.id, runId: live.id });
    }""")
    page.wait_for_timeout(400)
    try:
        page.locator(".phone").get_by_text("Finish run").first.click(timeout=2000)
        page.wait_for_timeout(400)
        screenshot_phone(page, "09-completion-sheet-partial.png")
        record("09-completion-sheet-partial.png", "CompletionSheet — partial (some items unchecked)")
    except Exception as e:
        record("09-completion-sheet-partial.png", "CompletionSheet — partial", f"FAILED: {e}")

    # Discard confirm inside CompletionSheet
    try:
        page.locator(".phone").get_by_text("Discard run").first.click(timeout=2000)
        page.wait_for_timeout(400)
        screenshot_phone(page, "10-completion-sheet-discard-confirm.png")
        record("10-completion-sheet-discard-confirm.png", "CompletionSheet — discard confirmation")
    except Exception as e:
        record("10-completion-sheet-discard-confirm.png", "Discard confirm", f"FAILED: {e}")

    # List with empty items
    inject_state_and_reload(page, seed_state_one_list_no_runs())
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        // Make a template with zero items for this capture
        a.state.templates[0].items = [];
        a.nav('list', { templateId: tpl.id });
    }""")
    page.wait_for_timeout(300)
    screenshot_phone(page, "11-list-empty-items.png")
    record("11-list-empty-items.png", "List — template exists but has no items")

    # List with finished runs but no live run
    inject_state_and_reload(page, seed_state_live_plus_finished())
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        a.nav('list', { templateId: tpl.id });
    }""")
    page.wait_for_timeout(350)
    screenshot_phone(page, "12-list-no-current-run.png")
    record("12-list-no-current-run.png", "List — finished runs present, no live run (last-finished pill)")

    # AddItemInline — open on single-run list
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live');
        a.nav('list', { templateId: tpl.id, runId: live.id });
    }""")
    page.wait_for_timeout(350)
    try:
        page.locator(".phone").get_by_text("Add item").first.click(timeout=2000)
        page.wait_for_timeout(400)
        screenshot_phone(page, "13-list-add-item-open.png")
        record("13-list-add-item-open.png", "List — AddItemInline form open (with tag picker, future-only toggle)")
    except Exception as e:
        record("13-list-add-item-open.png", "AddItemInline open", f"FAILED: {e}")

    # List kebab menu
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live');
        a.nav('list', { templateId: tpl.id, runId: live.id });
    }""")
    page.wait_for_timeout(350)
    try:
        click_top_right_icon(page)
        screenshot_phone(page, "14-list-menu-default.png")
        record("14-list-menu-default.png", "ListMenuSheet — default menu (edit/rename/history/archive/delete)")
    except Exception as e:
        record("14-list-menu-default.png", "ListMenuSheet default", f"FAILED: {e}")

    # Rename list variant
    try:
        page.locator(".phone").get_by_text("Rename list").first.click(timeout=2000)
        page.wait_for_timeout(350)
        screenshot_phone(page, "15-list-menu-rename-list.png")
        record("15-list-menu-rename-list.png", "ListMenuSheet — Rename list variant (text input)")
    except Exception as e:
        record("15-list-menu-rename-list.png", "Rename list", f"FAILED: {e}")

    # Name this run variant
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live');
        a.nav('list', { templateId: tpl.id, runId: live.id });
    }""")
    page.wait_for_timeout(350)
    try:
        click_top_right_icon(page)
        # Match either "Rename this run" (if labelled) or "Name this run"
        label = "Rename this run" if page.locator(".phone").get_by_text("Rename this run").count() else "Name this run"
        page.locator(".phone").get_by_text(label).first.click(timeout=2000)
        page.wait_for_timeout(350)
        screenshot_phone(page, "16-list-menu-name-run.png")
        record("16-list-menu-name-run.png", "ListMenuSheet — Name/rename this run variant")
    except Exception as e:
        record("16-list-menu-name-run.png", "Name run", f"FAILED: {e}")

    # Delete list confirm
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live');
        a.nav('list', { templateId: tpl.id, runId: live.id });
    }""")
    page.wait_for_timeout(350)
    try:
        click_top_right_icon(page)
        page.locator(".phone").get_by_text("Delete list").first.click(timeout=2000)
        page.wait_for_timeout(350)
        screenshot_phone(page, "17-list-menu-delete-confirm.png")
        record("17-list-menu-delete-confirm.png", "ListMenuSheet — Delete list confirmation")
    except Exception as e:
        record("17-list-menu-delete-confirm.png", "Delete confirm", f"FAILED: {e}")

    # Archive confirm
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const tpl = a.state.templates[0];
        const live = a.state.runs.find(r => r.templateId === tpl.id && r.status === 'live');
        a.nav('list', { templateId: tpl.id, runId: live.id });
    }""")
    page.wait_for_timeout(350)
    try:
        click_top_right_icon(page)
        page.locator(".phone").get_by_text("Archive list").first.click(timeout=2000)
        page.wait_for_timeout(350)
        screenshot_phone(page, "18-list-menu-archive-confirm.png")
        record("18-list-menu-archive-confirm.png", "ListMenuSheet — Archive list confirmation (prototype only — we're cutting archive)")
    except Exception as e:
        record("18-list-menu-archive-confirm.png", "Archive confirm", f"FAILED: {e}")

    # ── Past run detail ─────────────────────────────────────────────
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        const past = a.state.runs.find(r => r.status === 'finished');
        a.nav('run', { runId: past.id });
    }""")
    page.wait_for_timeout(350)
    screenshot_phone(page, "19-past-run-detail.png")
    record("19-past-run-detail.png", "CompletedRun detail — sealed / read-only")

    # Partial past run
    page.evaluate("""() => {
        const a = window.__gemApp;
        const past = a.state.runs.find(r => r.status === 'partial');
        if (past) a.nav('run', { runId: past.id });
    }""")
    page.wait_for_timeout(350)
    screenshot_phone(page, "20-past-run-partial.png")
    record("20-past-run-partial.png", "CompletedRun detail — partial (prototype status; v4 cuts this)")

    # ── History ─────────────────────────────────────────────────────
    nav(page, "history", {})
    screenshot_phone(page, "21-history-seeded.png")
    record("21-history-seeded.png", "History — seeded (11 past runs, grouped by month)")

    inject_state_and_reload(page, EMPTY_STATE)
    nav(page, "history", {})
    screenshot_phone(page, "22-history-empty.png")
    record("22-history-empty.png", "History — true empty (no finished runs)")

    # History for a single list (prototype sends templateId param)
    inject_state_and_reload(page, None)
    page.evaluate("""() => {
        const a = window.__gemApp;
        a.nav('history', { templateId: a.state.templates[1].id });  // Morning Routine
    }""")
    page.wait_for_timeout(350)
    screenshot_phone(page, "23-history-for-one-list.png")
    record("23-history-for-one-list.png", "History — scoped to one checklist (Morning Routine)")

    # ── Tags ────────────────────────────────────────────────────────
    inject_state_and_reload(page, None)
    nav(page, "tags", {})
    screenshot_phone(page, "24-tags-seeded.png")
    record("24-tags-seeded.png", "Tags screen — seeded with 6 tags")

    inject_state_and_reload(page, EMPTY_STATE)
    nav(page, "tags", {})
    screenshot_phone(page, "25-tags-empty.png")
    record("25-tags-empty.png", "Tags screen — empty state")

    # Tag editor (edit existing) — click pencil icon
    inject_state_and_reload(page, None)
    nav(page, "tags", {})
    try:
        # Each tag row has a pencil icon at its right edge. Click the first.
        page.locator(".phone button").filter(has_text="Beach").first.click(timeout=2000)
        page.wait_for_timeout(350)
        screenshot_phone(page, "26-tag-editor-edit.png")
        record("26-tag-editor-edit.png", "TagEditorSheet — edit existing tag")
    except Exception as e:
        record("26-tag-editor-edit.png", "TagEditorSheet edit", f"FAILED: {e}")

    # Tag editor (new tag)
    inject_state_and_reload(page, None)
    nav(page, "tags", {})
    try:
        page.locator(".phone").get_by_text("New tag").first.click(timeout=2000)
        page.wait_for_timeout(350)
        screenshot_phone(page, "27-tag-editor-new.png")
        record("27-tag-editor-new.png", "TagEditorSheet — create new tag")
    except Exception as e:
        record("27-tag-editor-new.png", "TagEditorSheet new", f"FAILED: {e}")

    # ── Settings ────────────────────────────────────────────────────
    nav(page, "settings", {})
    screenshot_phone(page, "28-settings-seeded.png")
    record("28-settings-seeded.png", "Settings — seeded (stats, shortcuts, danger zone)")

    # ── Create checklist sheet (from home) ──────────────────────────
    inject_state_and_reload(page, None)
    nav(page, "home", {})
    try:
        click_top_right_icon(page)  # + button on home
        screenshot_phone(page, "29-create-checklist-sheet.png")
        record("29-create-checklist-sheet.png", "CreateChecklistSheet — empty form with category pills")
    except Exception as e:
        record("29-create-checklist-sheet.png", "CreateChecklistSheet", f"FAILED: {e}")

    # Create checklist with name entered
    try:
        page.keyboard.type("Europe 2026", delay=20)
        page.wait_for_timeout(250)
        screenshot_phone(page, "30-create-checklist-with-name.png")
        record("30-create-checklist-with-name.png", "CreateChecklistSheet — name typed, Create enabled")
    except Exception as e:
        record("30-create-checklist-with-name.png", "CreateChecklistSheet typing", f"FAILED: {e}")


def write_index() -> None:
    lines = [
        "# Prototype interaction captures",
        "",
        f"Source: `{PROTOTYPE.name}`",
        "Generated by `scripts/capture_prototype.py`.",
        "",
        "Each image is a screenshot of the 402×874 phone frame as rendered by",
        "the HTML prototype in headless Chromium.",
        "",
        "| # | File | State | Status |",
        "|---|---|---|---|",
    ]
    for i, r in enumerate(RESULTS, 1):
        lines.append(f"| {i} | [{r['file']}]({r['file']}) | {r['description']} | {r['status']} |")
    (OUT / "index.md").write_text("\n".join(lines) + "\n")


def main() -> None:
    if not PROTOTYPE.exists():
        raise SystemExit(f"prototype not found: {PROTOTYPE}")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1200, "height": 1100},
            device_scale_factor=3,
        )
        page = context.new_page()
        page.goto(PROTOTYPE.as_uri())
        page.wait_for_selector(".phone", timeout=10000)
        page.wait_for_function("() => window.__gemApp != null", timeout=10000)
        page.wait_for_timeout(600)

        capture_all(page)
        write_index()
        browser.close()

    print(f"\nDone. {len(RESULTS)} captures → {OUT}")


if __name__ == "__main__":
    main()
