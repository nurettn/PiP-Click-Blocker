# 🚫 PiP Click Blocker

> Lock Chrome's Picture-in-Picture window — no clicks, no dragging, no resizing.

---

## Requirements

- [AutoHotkey v2](https://www.autohotkey.com/) *(Download → v2.x)*

---

## Installation

Double-click `pip_blocker.ahk`. A tray icon will appear in the system tray.

---

## Usage

1. Open a PiP window in Chrome (click the media icon in the toolbar → *Picture in Picture*)
2. Press **Ctrl+Shift+P**
3. The PiP window is now fully locked:
   - All mouse clicks pass through it to whatever is underneath
   - The window cannot be moved or resized
   - The video continues playing normally
4. Press **Ctrl+Shift+P** again to restore normal behavior

---

## Hotkeys

| Hotkey | Action |
|---|---|
| `Ctrl` + `Shift` + `P` | Toggle lock / unlock |
| `Ctrl` + `Shift` + `F` | Debug — show info about the detected PiP window |

---

## How It Works

Uses the Windows API (`SetWindowLong`) to apply two extended window style flags:

- **`WS_EX_LAYERED`** + **`WS_EX_TRANSPARENT`** — all mouse events pass through the window to whatever is beneath it
- **`WS_THICKFRAME` removed** — disables resizing
- A **150 ms timer** continuously resets the window's position and size if anything tries to move it

The PiP window is detected automatically by scanning `Chrome_WidgetWin_1` windows and scoring them based on title, size, aspect ratio, and always-on-top status.

---

## Limitations

- Chrome's hover controls (play/pause/close overlay) are also unreachable while locked — which is the intended behavior.
- If the detected window is wrong, press `Ctrl+Shift+F` to see which window the script found.
