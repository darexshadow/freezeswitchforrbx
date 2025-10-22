#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir

settingsFile := A_ScriptDir "\settings.ini"

global suspendTime := 250
global targetProcess := "RobloxPlayerBeta.exe"
global currentHotkey := "XButton2"
global paused := false

; === Загружаем настройки ===
if FileExist(settingsFile) {
    suspendTime := IniRead(settingsFile, "Settings", "SuspendTime", suspendTime)
    targetProcess := IniRead(settingsFile, "Settings", "TargetProcess", targetProcess)
    currentHotkey := IniRead(settingsFile, "Settings", "Hotkey", currentHotkey)
}

; === Создаём GUI ===
MyGui := Gui("+AlwaysOnTop", "Process Suspender")
MyGui.SetFont("s10", "Segoe UI")

MyGui.Add("Text", "x20 y20 w130", "Target Process:")
MyGui.Add("Edit", "x160 y20 w180 vTargetProcess", targetProcess)
MyGui.Add("Text", "x20 y60 w130", "Suspend Time (ms):")
MyGui.Add("Edit", "x160 y60 w180 vSuspendTime", suspendTime)
MyGui.Add("Text", "x20 y100 w130", "Hotkey:")
HotkeyEdit := MyGui.Add("Edit", "x160 y100 w120 vHotkey", currentHotkey)
MyGui.Add("Button", "x285 y100 w55", "Set").OnEvent("Click", ChooseHotkey)
MyGui.Add("Text", "x20 y135 w330", "Нажми “Set” и затем любую клавишу (Ctrl, Alt, XButton и т.д.)")

MyGui.Add("Button", "x20 y180 w150 h35", "&Apply Settings").OnEvent("Click", ApplySettings)
MyGui.Add("Button", "x190 y180 w150 h35", "&Show Info").OnEvent("Click", ShowInfo)

ApplyCurrentSettings()
MyGui.Show("w380 h240")

; === ТРЕЙ-МЕНЮ ===
A_TrayMenu.Delete()
A_TrayMenu.Add("🟡 Pause / Resume Hotkey", TogglePause)
A_TrayMenu.Add()
A_TrayMenu.Add("❌ Exit", (*) => ExitApp())
TraySetIcon("shell32.dll", 44)

; === Выбор хоткея ===
ChooseHotkey(*) {
    global currentHotkey, MyGui

    subGui := Gui("+AlwaysOnTop", "Press Hotkey")
    subGui.Add("Text", , "Нажми нужную клавишу или комбинацию...")
    subGui.Show("w260 h100")

    pressedKey := ""
    vkHandler := (wParam, lParam, msg, hwnd) => (pressedKey := GetKeyName(Format("vk{:x}", wParam)))
    xb1Handler := (wParam, lParam, msg, hwnd) => (pressedKey := "XButton1")
    xb2Handler := (wParam, lParam, msg, hwnd) => (pressedKey := "XButton2")

    OnMessage(0x100, vkHandler)
    OnMessage(0x20B, xb1Handler)
    OnMessage(0x20C, xb2Handler)

    Loop {
        Sleep(50)
        if (pressedKey != "") {
            subGui.Destroy()
            MyGui["Hotkey"].Value := pressedKey
            currentHotkey := pressedKey

            OnMessage(0x100, 0)
            OnMessage(0x20B, 0)
            OnMessage(0x20C, 0)
            break
        }
    }
}

; === Применить настройки ===
ApplyCurrentSettings() {
    global currentHotkey
    try Hotkey(currentHotkey, SuspendProcess, "On")
}

ApplySettings(*) {
    global suspendTime, targetProcess, currentHotkey, settingsFile

    TargetProcess := MyGui["TargetProcess"].Value
    SuspendTime := MyGui["SuspendTime"].Value
    NewHotkey := MyGui["Hotkey"].Value

    if !(SuspendTime ~= "^\d+$") {
        MsgBox("❌ Введите корректное число для времени приостановки.", "Ошибка", 48)
        return
    }

    suspendTime := Integer(SuspendTime)
    targetProcess := TargetProcess

    try Hotkey(currentHotkey, SuspendProcess, "Off")
    currentHotkey := NewHotkey

    try {
        Hotkey(currentHotkey, SuspendProcess, "On")
    } catch {
        MsgBox("❌ Не удалось установить хоткей: " currentHotkey "`nПопробуйте другую клавишу.", "Ошибка", 48)
        return
    }

    IniWrite(suspendTime, settingsFile, "Settings", "SuspendTime")
    IniWrite(targetProcess, settingsFile, "Settings", "TargetProcess")
    IniWrite(currentHotkey, settingsFile, "Settings", "Hotkey")

    MsgBox("✅ Настройки сохранены!`n`nПроцесс: " targetProcess "`nВремя: " suspendTime " мс`nХоткей: " currentHotkey, "Успешно", 64)
}

; === Инфо ===
ShowInfo(*) {
    global targetProcess, suspendTime, currentHotkey
    MsgBox("
    (
    🧊 Process Suspender

    Target Process: " targetProcess "
    Suspend Time: " suspendTime " ms
    Hotkey: " currentHotkey "

    🔹 Как использовать:
    1. Введите имя процесса (например RobloxPlayerBeta.exe)
    2. Установите время (мс)
    3. Нажмите Set и выберите клавишу
    4. Apply Settings — применить

    ⌨️ Ctrl + Esc — выйти
    )", "Инфо", 64)
}

; === Приостановка процесса ===
SuspendProcess(*) {
    global targetProcess, suspendTime, paused
    if paused {
        TrayTip("⏸ Hotkey paused", "Нажми Resume в трее, чтобы вернуть работу", 1)
        return
    }

    pid := GetProcessPID(targetProcess)
    if pid {
        Suspend(pid)
        Sleep(suspendTime)
        Resume(pid)
    } else {
        MsgBox("❌ Процесс " targetProcess " не найден!", "Ошибка", 48)
    }
}

GetProcessPID(name) {
    try {
        return WinGetPID("ahk_exe " name)
    } catch {
        return 0
    }
}

Suspend(pid) {
    hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "UInt", pid, "Ptr")
    if !hProcess
        return false
    DllCall("ntdll.dll\NtSuspendProcess", "Ptr", hProcess)
    DllCall("CloseHandle", "Ptr", hProcess)
    return true
}

Resume(pid) {
    hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "UInt", pid, "Ptr")
    if !hProcess
        return false
    DllCall("ntdll.dll\NtResumeProcess", "Ptr", hProcess)
    DllCall("CloseHandle", "Ptr", hProcess)
    return true
}

; === Pause / Resume ===
TogglePause(*) {
    global paused
    paused := !paused
    if paused {
        TraySetIcon("shell32.dll", 110)
        TrayTip("🟡 Hotkey paused", "Процесс временно отключён", 1)
    } else {
        TraySetIcon("shell32.dll", 44)
        TrayTip("🟢 Hotkey active", "Хоткей снова активен", 1)
    }
}

; === Закрытие ===
MyGui.OnEvent("Close", (*) => ExitApp())
Hotkey("^Esc", (*) => ExitApp())
