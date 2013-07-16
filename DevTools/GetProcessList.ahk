ProcList := []	; Creating an array "ProcList".
For Process In (ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process"))	; Parsing through a list of running processes.
; A list of available params to create an array:
; http://msdn.microsoft.com/en-us/library/windows/desktop/aa394372%28v=vs.85%29.aspx
{
	((Process.CommandLine) ? (ProcList.Insert(Process.CommandLine)) : (""))	; Using "CommandLine" param to fulfill our array.
}

Loop, % ProcList.MaxIndex()
	Msgbox % ProcList[A_Index]