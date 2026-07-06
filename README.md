# 🚫 PiP Click Blocker

> Block all interactions on Chrome's Picture-in-Picture window — no clicks, no dragging, no resizing.

---

## What It Does

Chrome's native PiP mini-player floats on top of everything, but it can be accidentally clicked, moved, paused, or closed. This project solves that with two complementary tools:

| Tool | Target | Method |
|---|---|---|
| **Chrome Extension** | Document PiP API windows | Injects a transparent click-blocking overlay |
| **AutoHotkey Script** | Native Chrome video PiP mini-player | `WS_EX_TRANSPARENT` + position lock via Win32 API |

---

## Chrome Extension

Blocks clicks inside PiP windows opened via the [Document Picture-in-Picture API](https://developer.chrome.com/docs/web-platform/document-picture-in-picture/) (Chrome 116+). Works on sites that use custom PiP implementations.

### Installation

1. Open Chrome and navigate to `chrome://extensions`
2. Enable **Developer mode** (toggle in the top-right corner)
3. Click **Load unpacked**
4. Select the `pip-click-blocker` folder
5. The extension icon will appear in your toolbar

### Usage

Click the extension icon to open the popup:

- **Block Document PiP clicks** — blocks all mouse interaction inside Document PiP windows *(on by default)*
- **Block native video PiP** — prevents `<video>` elements from entering PiP at all *(off by default)*

> **Note:** Toggling either switch automatically reloads the active tab.

### How It Works

When a Document PiP window opens, the extension injects a full-viewport transparent `<div>` with `z-index: 2147483647` and `pointer-events: all` into the PiP document. Every `click`, `mousedown`, `pointerdown`, `touchstart`, and `contextmenu` event is captured and cancelled before it reaches the page content.

It also wraps `documentPictureInPicture.requestWindow()` so programmatically opened PiP windows (e.g. video conferencing tools) are caught as well.

---

## AutoHotkey Script (`pip_blocker.ahk`)

Targets Chrome's **native video PiP mini-player** — the floating window that appears when you click the music/media icon in the Chrome toolbar and select *Picture in Picture*. This window is rendered at the OS level and cannot be reached by browser extensions.

### Requirements

- [AutoHotkey v2](https://www.autohotkey.com/) *(Download → v2.x)*

### Installation

Double-click `pip_blocker.ahk`. A tray icon will appear in the system tray.

### Hotkeys

| Hotkey | Action |
|---|---|
| `Ctrl` + `Shift` + `P` | Toggle lock/unlock on the PiP window |
| `Ctrl` + `Shift` + `F` | Debug — show info about the detected PiP window |

### Usage

1. Open a PiP window in Chrome (click the media icon → *Picture in Picture*)
2. Press **Ctrl+Shift+P**
3. The PiP window is now fully locked:
   - All mouse clicks pass through it to whatever is underneath
   - The window cannot be moved or resized
   - The video continues playing normally
4. Press **Ctrl+Shift+P** again to restore normal behavior

### How It Works

The script uses the Windows API (`SetWindowLong`) to apply two extended window style flags to the PiP window:

- **`WS_EX_LAYERED`** (`0x80000`) — required prerequisite for transparency effects
- **`WS_EX_TRANSPARENT`** (`0x20`) — makes the window pass all mouse events to the window beneath it

It also removes the **`WS_THICKFRAME`** style to disable resizing, and runs a 150 ms timer that continuously resets the window's position and size if anything attempts to change them.

The PiP window is detected automatically by scanning all `Chrome_WidgetWin_1` windows and scoring them based on title, size, aspect ratio, and always-on-top status.

---

## Project Structure

```
pip-click-blocker/
├── manifest.json          # Chrome extension manifest (MV3)
├── content_script.js      # Click-blocking logic injected into pages
├── popup.html             # Extension popup UI
├── popup.js               # Popup toggle logic (reads/writes chrome.storage)
├── pip_blocker.ahk        # AutoHotkey v2 script for native PiP
└── icons/
    ├── icon16.png
    ├── icon48.png
    └── icon128.png
```

---

## Compatibility

| | Chrome Extension | AutoHotkey Script |
|---|---|---|
| Chrome native video PiP | ❌ Not applicable | ✅ Full support |
| Document PiP API | ✅ Full support | ❌ Not needed |
| YouTube (music icon PiP) | ❌ | ✅ |
| YouTube (in-player PiP button) | ✅ | ✅ |
| Windows | ✅ | ✅ |
| macOS / Linux | ✅ | ❌ (AHK is Windows-only) |

---

## Limitations

- Chrome's **native PiP playback controls** (the play/pause/close overlay that appears on hover) live inside privileged browser UI. The AutoHotkey script makes the entire window click-through, so these controls are also unreachable — which is the intended behavior.
- The AutoHotkey script targets `Chrome_WidgetWin_1` windows. If Chrome's internal window class changes in a future update, the detection heuristics may need adjustment. Use `Ctrl+Shift+F` to verify detection.
