/*
		hyde.dll hides a process from the task manager on Windows 2000 - Windows 7 
		x86 & x64 bit OSes
		
		Your process can inject it into other processes however you like. The example uses
		SetWindowsHookEx with a CBT hook (the dll exports a CBTProc) to inject it into all
		running processes.
		
		Press Esc to exit the script.
		
		Note: if you don't compile the script, AutoHotKey.exe gets hidden. Otherwise
		the name of the .exe gets hidden.
*/

#NoEnv
SetWorkingDir %A_ScriptDir%

OnExit, ExitSub

hMod := DllCall("LoadLibrary", Str, "hyde.dll", Ptr) ;for x86
;hMod := DllCall("LoadLibrary", Str, "hyde64.dll", Ptr) ;for x64
if (hMod)
{
	hHook := DllCall("SetWindowsHookEx", Int, 5, Ptr, DllCall("GetProcAddress", Ptr, hMod, AStr, "CBProc", ptr), Ptr, hMod, Ptr, 0, Ptr)
	if (!hHook)
	{
		MsgBox, SetWindowsHookEx failed
		ExitApp
	}
}
else
{
	MsgBox, LoadLibrary failed
	ExitApp
}

MsgBox, Process hidden
Return

Esc::ExitApp

ExitSub:
	if (hHook)
		DllCall("UnhookWindowsHookEx", Ptr, hHook)
	if (hMod)
		DllCall("FreeLibrary", Ptr, hMod)
ExitApp
