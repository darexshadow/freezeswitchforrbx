#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; Глобальные переменные
global suspendTime := 1000
global targetProcess := "RobloxPlayerBeta.exe"
global hotkey := "XButton2"  ; Кнопка назад на мышке

; Создаем GUI для настроек
CreateGUI()

; Применяем начальные настройки
ApplyCurrentSettings()

; Показываем GUI
Gui, Show, w350 h220, Process Suspender

Return

; Функция создания GUI
CreateGUI()
{
    Gui, Font, s10, Segoe UI
    
    ; Название процесса
    Gui, Add, Text, x20 y20 w120 h25, Target Process:
    Gui, Add, Edit, x150 y20 w180 h25 vTargetProcess, % targetProcess
    
    ; Время приостановки
    Gui, Add, Text, x20 y60 w120 h25, Suspend Time (ms):
    Gui, Add, Edit, x150 y60 w180 h25 vSuspendTime, % suspendTime
    
    ; Выбор кнопки мыши
    Gui, Add, Text, x20 y100 w120 h25, Mouse Button:
    Gui, Add, DropDownList, x150 y100 w180 h25 vMouseButton Choose1, XButton1||XButton2|MButton|RButton|LButton
    
    ; Информация
    Gui, Add, Text, x20 y130 w310 h40, XButton1 = Кнопка вперед`nXButton2 = Кнопка назад`nMButton = Колесо мыши
    
    ; Кнопка применения
    Gui, Add, Button, x20 y180 w150 h35 gApplySettings, &Apply Settings
    Gui, Add, Button, x180 y180 w150 h35 gShowInfo, &Show Info
}

ApplyCurrentSettings()
{
    ; Регистрируем начальную горячую клавишу
    Hotkey, %hotkey%, SuspendProcess, On
}

ApplySettings:
    Gui, Submit, NoHide
    
    ; Валидация времени
    if SuspendTime is not integer
    {
        MsgBox, Error: Please enter a valid number for suspend time
        return
    }
    
    if (SuspendTime < 1)
    {
        MsgBox, Error: Suspend time must be positive
        return
    }
    
    ; Обновляем глобальные переменные
    suspendTime := SuspendTime
    targetProcess := TargetProcess
    
    ; Перерегистрируем горячую клавишу
    try
    {
        Hotkey, %hotkey%, Off
        hotkey := MouseButton
        Hotkey, %hotkey%, SuspendProcess, On
    }
    catch e
    {
        MsgBox, Error: Cannot set hotkey "%hotkey%"`nPlease try another button
        return
    }
    
    MsgBox, 64, Settings Applied, Settings updated!`n`nProcess: %targetProcess%`nSuspend Time: %suspendTime% ms`nHotkey: %hotkey%
Return

ShowInfo:
    MsgBox, 64, Script Info, 
    (
    Process Suspender Script
    
    Target Process: %targetProcess%
    Suspend Time: %suspendTime% ms
    Hotkey: %hotkey%
    
    Mouse Buttons:
    - XButton1 = Кнопка вперед (боковая)
    - XButton2 = Кнопка назад (боковая) 
    - MButton = Колесо мыши (нажатие)
    - RButton = Правая кнопка
    - LButton = Левая кнопка
    
    Instructions:
    - Configure settings in the window
    - Click "Apply Settings"
    - Press the mouse button to suspend/resume the process
    
    Press Ctrl+Esc to exit
    )
Return

SuspendProcess:
    Process, Exist, %targetProcess%
    If (ErrorLevel) 
    {
        PID := ErrorLevel
        SuspendProcess(PID)
        Sleep, %suspendTime%
        ResumeProcess(PID)
    }
    Else
    {
        MsgBox, Error: %targetProcess% process not found!
    }
Return

SuspendProcess(PID) {
    hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", PID)
    If !hProcess
        Return False
    DllCall("ntdll.dll\NtSuspendProcess", "Ptr", hProcess)
    DllCall("CloseHandle", "Ptr", hProcess)
    Return True
}

ResumeProcess(PID) {
    hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", PID)
    If !hProcess
        Return False
    DllCall("ntdll.dll\NtResumeProcess", "Ptr", hProcess)
    DllCall("CloseHandle", "Ptr", hProcess)
    Return True
}

GuiClose:
^Esc::ExitApp