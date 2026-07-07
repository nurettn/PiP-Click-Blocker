; ╔══════════════════════════════════════════════════════════════╗
; ║           PiP Click & Move Blocker  —  AutoHotkey v2        ║
; ║                                                              ║
; ║  Hotkeys:                                                    ║
; ║    Ctrl+Shift+P  →  Toggle block on the PiP window          ║
; ║    Ctrl+Shift+L  →  Toggle block on ACTIVE window (Force)  ║
; ║    Ctrl+Shift+F  →  Find & highlight PiP window (debug)     ║
; ║                                                              ║
; ║  How to use:                                                 ║
; ║    1. Open a Chrome PiP window (music icon → PiP)           ║
; ║    2. Press Ctrl+Shift+P                                     ║
; ║    3. The window becomes click-through and position-locked   ║
; ║    4. Press Ctrl+Shift+P (or L) again to unlock              ║
; ╚══════════════════════════════════════════════════════════════╝

#Requires AutoHotkey v2.0
#SingleInstance Force

; ── Win32 constants ─────────────────────────────────────────────
GWL_EXSTYLE       := -20
WS_EX_LAYERED     := 0x80000
WS_EX_TRANSPARENT := 0x20
GWL_STYLE         := -16
WS_THICKFRAME     := 0x40000   ; resizable border
SWP_NOMOVE        := 0x2
SWP_NOSIZE        := 0x1
SWP_NOZORDER      := 0x4
SWP_FRAMECHANGED  := 0x20

; ── State ────────────────────────────────────────────────────────
global isBlocked  := false
global targetHwnd := 0
global lockedX    := 0
global lockedY    := 0
global lockedW    := 0
global lockedH    := 0

; ── Tray setup ──────────────────────────────────────────────────
A_TrayMenu.Delete()
A_TrayMenu.Add("Enable Block  (Ctrl+Shift+P)", MenuToggle)
A_TrayMenu.Add("Disable Block (Ctrl+Shift+P)", MenuToggle)
A_TrayMenu.Add()
A_TrayMenu.Add("Status", MenuStatus)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Enable Block  (Ctrl+Shift+P)"
A_IconTip := "PiP Blocker — inactive"

; ════════════════════════════════════════════════════════════════
;  HOTKEYS
; ════════════════════════════════════════════════════════════════

; Main toggle (auto-detect PiP)
^+p:: ToggleBlock()

; Force toggle on the currently active window
^+l:: ToggleBlockActive()

; Debug: show info about detected PiP window
^+f:: {
    hwnd := FindPipWindow()
    if hwnd {
        t := WinGetTitle("ahk_id " hwnd)
        c := WinGetClass("ahk_id " hwnd)
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        MsgBox "Found PiP window:`n`nTitle: " t "`nClass: " c "`nHWND: " hwnd "`nPos:  x=" x " y=" y "`nSize: " w "x" h,
               "PiP Blocker — Debug", 64
    } else {
        MsgBox "No PiP window detected.`n`nMake sure a Chrome PiP window is open.",
               "PiP Blocker — Debug", 48
    }
}

; ════════════════════════════════════════════════════════════════
;  CORE LOGIC
; ════════════════════════════════════════════════════════════════

ToggleBlock(*) {
    global isBlocked, targetHwnd, lockedX, lockedY, lockedW, lockedH

    if isBlocked {
        ; ── UNLOCK ──────────────────────────────────────────────
        SetTimer LockPosition, 0
        if targetHwnd && WinExist("ahk_id " targetHwnd) {
            RemoveClickThrough(targetHwnd)
            RestoreResizable(targetHwnd)
        }
        isBlocked    := false
        targetHwnd   := 0
        A_IconTip    := "PiP Blocker — inactive"
        TrayTip("Unlocked — PiP window is interactive again", "PiP Blocker")
        return
    }

    ; ── LOCK ────────────────────────────────────────────────────
    hwnd := FindPipWindow()
    if !hwnd {
        MsgBox "Chrome PiP window not found!`n`n"
             . "Make sure you opened PiP first (music icon -> Picture in Picture).",
               "PiP Blocker", 48
        return
    }

    targetHwnd := hwnd

    ; Snapshot current position & size to lock it
    WinGetPos(&lockedX, &lockedY, &lockedW, &lockedH, "ahk_id " hwnd)

    ; Apply click-through
    ApplyClickThrough(hwnd)

    ; Remove resizable border
    RemoveResizable(hwnd)

    ; Start position guard (runs every 150 ms)
    SetTimer LockPosition, 150

    isBlocked := true
    A_IconTip := "PiP Blocker — ACTIVE"
    TrayTip("PiP locked!  Ctrl+Shift+P to unlock", "PiP Blocker")
}

ToggleBlockActive(*) {
    global isBlocked, targetHwnd, lockedX, lockedY, lockedW, lockedH

    if isBlocked {
        ; UNLOCK
        ToggleBlock()
        return
    }

    hwnd := WinGetID("A")
    if !hwnd {
        MsgBox "No active window found!", "PiP Blocker", 48
        return
    }

    targetHwnd := hwnd

    ; Snapshot current position & size to lock it
    WinGetPos(&lockedX, &lockedY, &lockedW, &lockedH, "ahk_id " hwnd)

    ; Apply click-through
    ApplyClickThrough(hwnd)

    ; Remove resizable border
    RemoveResizable(hwnd)

    ; Start position guard
    SetTimer LockPosition, 150

    isBlocked := true
    A_IconTip := "PiP Blocker — ACTIVE (Forced)"
    TrayTip("Active window locked!  Ctrl+Shift+P/L to unlock", "PiP Blocker")
}

; ════════════════════════════════════════════════════════════════
;  TIMER — keep position fixed
; ════════════════════════════════════════════════════════════════

LockPosition() {
    global targetHwnd, lockedX, lockedY, lockedW, lockedH, isBlocked

    if !isBlocked
        return

    if !WinExist("ahk_id " targetHwnd) {
        SetTimer LockPosition, 0
        isBlocked := false
        A_IconTip := "PiP Blocker — inactive (window closed)"
        return
    }

    WinGetPos(&cx, &cy, &cw, &ch, "ahk_id " targetHwnd)
    if (cx != lockedX || cy != lockedY || cw != lockedW || ch != lockedH) {
        WinMove(lockedX, lockedY, lockedW, lockedH, "ahk_id " targetHwnd)
    }
}

; ════════════════════════════════════════════════════════════════
;  WIN32 HELPERS
; ════════════════════════════════════════════════════════════════

ApplyClickThrough(hwnd) {
    exStyle := DllCall("GetWindowLong", "Ptr", hwnd, "Int", GWL_EXSTYLE, "Int")
    exStyle |= (WS_EX_LAYERED | WS_EX_TRANSPARENT)
    DllCall("SetWindowLong", "Ptr", hwnd, "Int", GWL_EXSTYLE, "Int", exStyle)
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0,
            "Int", 0, "Int", 0, "Int", 0, "Int", 0,
            "UInt", SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED)
}

RemoveClickThrough(hwnd) {
    exStyle := DllCall("GetWindowLong", "Ptr", hwnd, "Int", GWL_EXSTYLE, "Int")
    exStyle &= ~WS_EX_TRANSPARENT
    DllCall("SetWindowLong", "Ptr", hwnd, "Int", GWL_EXSTYLE, "Int", exStyle)
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0,
            "Int", 0, "Int", 0, "Int", 0, "Int", 0,
            "UInt", SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED)
}

RemoveResizable(hwnd) {
    style := DllCall("GetWindowLong", "Ptr", hwnd, "Int", GWL_STYLE, "Int")
    style &= ~WS_THICKFRAME
    DllCall("SetWindowLong", "Ptr", hwnd, "Int", GWL_STYLE, "Int", style)
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0,
            "Int", 0, "Int", 0, "Int", 0, "Int", 0,
            "UInt", SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED)
}

RestoreResizable(hwnd) {
    style := DllCall("GetWindowLong", "Ptr", hwnd, "Int", GWL_STYLE, "Int")
    style |= WS_THICKFRAME
    DllCall("SetWindowLong", "Ptr", hwnd, "Int", GWL_STYLE, "Int", style)
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0,
            "Int", 0, "Int", 0, "Int", 0, "Int", 0,
            "UInt", SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED)
}

; ════════════════════════════════════════════════════════════════
;  PiP WINDOW DETECTION
; ════════════════════════════════════════════════════════════════
;  Chrome native PiP mini-player on Windows:
;    - Class : Chrome_WidgetWin_1
;    - Title : video title or "Picture in Picture"
;    - Size  : small (< 600px wide)
;    - Always on top (WS_EX_TOPMOST)
;
;  We score all Chrome_WidgetWin_1 windows and pick the best match.

FindPipWindow() {
    bestHwnd  := 0
    bestScore := -1

    ids := WinGetList("ahk_class Chrome_WidgetWin_1")
    for hwnd in ids {
        title := WinGetTitle("ahk_id " hwnd)
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)

        if !WinExist("ahk_id " hwnd) || w <= 150 || h <= 100
            continue
        if !DllCall("IsWindowVisible", "Ptr", hwnd)
            continue

        score := 0

        ; Explicit title match (English & Turkish)
        if InStr(title, "Picture in Picture", false) || InStr(title, "Resim içinde Resim", false)
            score += 100

        ; Document PiP can be larger. Give points for being reasonably sized.
        if (w < 600 && h < 450)
            score += 50
        else if (w < 1200 && h < 800)
            score += 20

        ; Always-on-top (WS_EX_TOPMOST = 0x8) is a very strong indicator for PiP
        exStyle := DllCall("GetWindowLong", "Ptr", hwnd, "Int", GWL_EXSTYLE, "Int")
        if (exStyle & 0x8)
            score += 60

        ; Reasonable video aspect ratio
        if (w > 0 && h > 0) {
            ratio := w / h
            if (ratio > 1.0 && ratio < 3.0)
                score += 20
        }

        if score > bestScore {
            bestScore := score
            bestHwnd  := hwnd
        }
    }

    return (bestScore >= 70) ? bestHwnd : 0
}

; ════════════════════════════════════════════════════════════════
;  TRAY MENU HANDLERS
; ════════════════════════════════════════════════════════════════

MenuToggle(*) => ToggleBlock()

MenuStatus(*) {
    global isBlocked, targetHwnd, lockedX, lockedY, lockedW, lockedH
    if isBlocked
        MsgBox "Status: ACTIVE`n`nLocked window HWND: " targetHwnd
             . "`nPosition: x=" lockedX " y=" lockedY
             . "`nSize: " lockedW "x" lockedH
             . "`n`nPress Ctrl+Shift+P to unlock.",
               "PiP Blocker", 64
    else
        MsgBox "Status: INACTIVE`n`nPress Ctrl+Shift+P to lock the PiP window.",
               "PiP Blocker", 64
}
