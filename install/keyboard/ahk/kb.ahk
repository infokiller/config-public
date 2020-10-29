#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#f::Send, {Blind}{Up}
;#f::WinMaximize, A

#p::Send, {Blind}^{Left}

#n::Send, {Blind}^{Right}

#+j::Send, {Blind}{Shift up}{Left}{Shift down}

#+l::Send, {Blind}{Shift up}{Right}{Shift down}

#c::Run, copyq.exe, 

#IfWinActive ahk_class Chrome_WidgetWin_1
!SC027::Send, {Blind}!+.
Return
