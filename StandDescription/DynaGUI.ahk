/* Stand Description
Summary: a script that demonstrates the idea of dynamic GUI and saving/restoring data into/from JSON format.
Description: this script has GUI with text areas and buttons to add more text fields and delete added text fields. The data written into those text fields may get saved into an external *.json file in JSON format (via Cocobelgica's library, that's injected right into the body of this script), which later may be imported into the script's window via drag'n'drop (or as plain text in JSON format via menu toolbar button).
I wrote this script for myself, yet someone might like and reuse the idea of dynamic GUI, used to update an object that can be exported (and later imported) into text form.
Requirements: AutoHotkey v1.1.17+
Version: 1
Last time modified: 2015.04.14 19:43
Script author: Drugoy, a.k.a. Drugmix
Contacts: idrugoy@gmail.com, drug0y@ya.ru
https://github.com/Drugoy/Autohotkey-scripts-.ahk/tree/master/StandDescription
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Off
#NoTrayIcon

OnExit, GuiClose

If %0%	; The script was called with at least 1 argument, expectedly the user drag'n'dropped something onto the script.
	Loop, %0%
		input := %A_Index%	; Actually, only the last dropped file will get parsed.
If FileExist(input)	; Not sure if this needed, since user can't drag'n'drop an unexisting file.
	FileRead, input, %input%

If input
{
	Try
		GUIAsObject := JSON.parse(input)
	Catch E
		MsgBox, % e
}
Else
	GUIAsObject := [{"Name": "", "DefRoute": "0.0.0.0", "ifaces":[ {"Name": "em0", "Descr": "external", "Net": "vnet1", "Addrs":[ {"IP": "0.0.0.0", "Mask": "24"} ] }] }]

DrawGUI:
	Menu, menuToolbar, Add, Open, Open
	Menu, menuToolbar, Add, Save, Save
	Menu, menuToolbar, Add, Parse JSON, ParseTextJSON
	Gui, Menu, menuToolbar
	GoSub, ParseJSON
	Gui, Show
Return

GuiClose:
	ExitApp

ParseJSON:
; OutputDebug, % "ParseJSON: GUIAsObject.MaxIndex(): '" GUIAsObject.MaxIndex() "'"
	For itemIndex In GUIAsObject
	{
		margin := 10 + (itemIndex-1) * 190
		Gui, Add, Text, x%margin% y0, Name:
		Gui, Add, Edit, x+0 w120 r1 vn%itemIndex%Name, % GUIAsObject[itemIndex].Name
		If !(itemIndex = 1 && GUIAsObject.MaxIndex() = 1)	; Forbid to remove the last existing itemIndex.
			Gui, Add, Button, x+0 w16 vdelN%itemIndex% gDeleteitemIndex, -
		Gui, Add, Button, x+0 w16 vaddN%itemIndex% gAdditemIndex, +
		Gui, Add, Text, x%margin% y+0, Default route:
		Gui, Add, Edit, x+0 w87 r1 vn%itemIndex%DefRoute, % GUIAsObject[itemIndex].defRoute
		For iface In GUIAsObject[itemIndex].ifaces
		{
			Gui, Add, Text, x%margin% y+0, If %iface%:
			Gui, Add, Edit, x+0 w29 r1 vn%itemIndex%If%iface%Name, % (GUIAsObject[itemIndex].ifaces[iface].Name ? GUIAsObject[itemIndex].ifaces[iface].Name : "em" iface-1 )
			Gui, Add, Text, x+0, Type:
			Gui, Add, Edit, x+0 w77 r1 vn%itemIndex%If%iface%Descr, % GUIAsObject[itemIndex].ifaces[iface].Descr
			If !(iface = 1 && GUIAsObject[itemIndex].ifaces.MaxIndex() = 1)	; Forbid to remove the last existing iface.
				Gui, Add, Button, x+0 w16 vn%itemIndex%DelIf%iface% gDeleteIf, -
			Gui, Add, Button, x+0 w16 vn%itemIndex%AddIf%iface% gAddIf, +
			Gui, Add, Text, x%margin% y+0, Net:
			Gui, Add, Edit, x+0 w131 r1 vn%itemIndex%If%iface%Net, % GUIAsObject[itemIndex].ifaces[iface].Net
			For addr In GUIAsObject[itemIndex].ifaces[iface].addrs
			{
				Gui, Add, Text, x%margin% y+0, Addr%addr%:
				Gui, Add, Edit, x+5 w90 r1 vn%itemIndex%If%iface%a%addr%addr, % GUIAsObject[itemIndex].ifaces[iface].addrs[addr].IP
				Gui, Add, Text, x+0, /
				Gui, Add, Edit, x+0 w21 r1 vn%itemIndex%if%iface%a%addr%mask, % GUIAsObject[itemIndex].ifaces[iface].addrs[addr].mask
				If !(addr = 1 && GUIAsObject[itemIndex].ifaces[iface].addrs.MaxIndex() = 1)	; Forbid to remove the last existing addr.
					Gui, Add, Button, x+0 w16 vn%itemIndex%If%iface%DelA%addr% gDeleteAddr, -
				Gui, Add, Button, x+0 w16 vn%itemIndex%If%iface%AddA%addr% gAddAddr, +
			}
		}
	}
Return

Open:
	FileSelectFile, input,,, Select a file with your saved stand, Stand (*.json)
	If (!ErrorLevel && input)
	{
		FileRead, input, %input%
		If input
		{
			Try
				GUIAsObject := JSON.parse(input)
			Catch, E
				MsgBox, % "Error: '" E "'" 
		}
		GoSub, Repaint
	}
Return

Save:
	FileSelectFile, output, S, % (output ? output : A_WorkingDir) "\" A_Now ".json", Where to save this stand to?
	If (!ErrorLevel && output)
	{
		GoSub, UpdateGUIAsObjectObj
		jsoned := JSON.stringify(GUIAsObject)
OutputDebug, % "jsoned: '" jsoned "'"
OutputDebug, % "GUIAsObject.MaxIndex(): '" GUIAsObject.MaxIndex() "'"
		If FileExist(output)
			FileDelete, %output%
		FileAppend, %jsoned%, %output%, UTF-8
		GoSub, Repaint
	}
Return

ParseTextJSON:
	Gui, InputJSON: New
	Gui, Add, Text,, Paste your JSON'ified stand:
	Gui, Add, Edit, w300 h250 vinputJSON
	Gui, Add, Button, x250, Parse
	Gui, InputJSON: Show
	Gui, 1: Default
Return

Repaint:
	Gui, Destroy
	GoSub, DrawGUI
Return

DeleteitemIndex:
	GUIAsObject.Remove(SubStr(A_GuiControl, 5))	; SubStr(A_GuiControl, 5)
	GoSub, Repaint
	GoSub, UpdateGUIAsObjectObj
Return

AdditemIndex:
	RegExMatch(A_GuiControl, "Si)^addN(\d+)$", this)
	GoSub, UpdateGUIAsObjectObj
	; GUIAsObject.Insert(this1+1, GUIAsObject[GUIAsObject.MaxIndex()])	; Duplicate
	GUIAsObject.Insert(this1+1, {"name": "", "defroute": "", "ifaces":[ {"name":"","descr":"","addrs":[ {"IP": "", "mask": ""} ] } ] })
	GoSub, Repaint
Return

DeleteIf:
	RegExMatch(A_GuiControl, "Si)^n(\d+)DelIf(\d+)$", this)	; User deleted iface #%this2% from itemIndex #%this1%.
	GUIAsObject[this1].ifaces.Remove(this2)
	GoSub, Repaint
	GoSub, UpdateGUIAsObjectObj
Return

AddIf:
	RegExMatch(A_GuiControl, "Si)^n(\d+)AddIf(\d+)$", this)
	GoSub, UpdateGUIAsObjectObj
	; GUIAsObject[this1].ifaces.Insert(this2+1, GUIAsObject[this1].ifaces[GUIAsObject[this1].ifaces.MaxIndex()])	; Duplicate
	GUIAsObject[this1].ifaces.Insert(this2+1, {"name":"","descr":"","addrs":[ {"IP": "", "mask": ""} ] })
	GoSub, Repaint
Return

DeleteAddr:
	RegExMatch(A_GuiControl, "Si)^n(\d+)If(\d+)DelA(\d+)$", this)
	GUIAsObject[this1].ifaces[this2].addrs.Remove(this3)
	GoSub, Repaint
	GoSub, UpdateGUIAsObjectObj
Return

AddAddr:
	RegExMatch(A_GuiControl, "Si)^n(\d+)If(\d+)AddA(\d+)$", this)
	GoSub, UpdateGUIAsObjectObj
	; GUIAsObject[this1].ifaces[this2].addrs.Insert(this3+1, GUIAsObject[this1].ifaces[this2].addrs[GUIAsObject[this1].ifaces[this2].addrs.MaxIndex()])	; Duplicate
	GUIAsObject[this1].ifaces[this2].addrs.Insert(this3+1, {"IP": "", "mask": ""})
	GoSub, UpdateGUIAsObjectObj
	GoSub, Repaint
Return

UpdateGUIAsObjectObj:
	Gui, 1: Submit, NoHide
	For itemIndex in GUIAsObject
	{
		GUIAsObject[itemIndex].Name := n%itemIndex%Name
		GUIAsObject[itemIndex].defRoute := n%itemIndex%DefRoute
		For iface In GUIAsObject[itemIndex].ifaces
		{
			GUIAsObject[itemIndex].ifaces[iface].Name := n%itemIndex%If%iface%Name
			GUIAsObject[itemIndex].ifaces[iface].Descr := n%itemIndex%If%iface%Descr
			GUIAsObject[itemIndex].ifaces[iface].Net := n%itemIndex%If%iface%Net
			For addr In GUIAsObject[itemIndex].ifaces[iface].addrs
			{
				GUIAsObject[itemIndex].ifaces[iface].addrs[addr].IP := n%itemIndex%If%iface%a%addr%addr
				GUIAsObject[itemIndex].ifaces[iface].addrs[addr].mask := n%itemIndex%if%iface%a%addr%mask
			}
		}
	}
Return

;{ JSON lib
/* Class: JSON
 *     JSON lib for AutoHotkey
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     AutoHotkey v1.1.17+
 * Others:
 *     Github URL:  https://github.com/cocobelgica/AutoHotkey-JSON
 *     Email:       cocobelgica@gmail.com
 *     Last Update: 02/15/2015 (MM/DD/YYYY)
 */
class JSON
{
	/* Method: parse
	 *     Deserialize a string containing a JSON document to an AHK object.
	 * Syntax:
	 *     json_obj := JSON.parse( ByRef src [ , jsonize := false ] )
	 * Parameter(s):
	 *     src  [in, ByRef] - String containing a JSON document
	 *     jsonize     [in] - If true, objects {} and arrays [] are wrapped as
	 *                        JSON.object and JSON.array instances respectively.
	 */
	parse(ByRef src, jsonize:=false)
	{
		args := jsonize ? [ JSON.object, JSON.array ] : []
		key := "", is_key := false
		stack := [ tree := [] ]
		is_arr := { (tree): 1 }
		next := """{[01234567890-tfn"
		pos := 0
		while ( (ch := SubStr(src, ++pos, 1)) != "" )
		{
			if InStr(" `t`n`r", ch)
				continue
			if !InStr(next, ch)
			{
				ln  := ObjMaxIndex(StrSplit(SubStr(src, 1, pos), "`n"))
				col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

				msg := Format("{}: line {} col {} (char {})"
				,   (next == "")    ? ["Extra data", ch := SubStr(src, pos)][1]
				  : (next == "'")   ? "Unterminated string starting at"
				  : (next == "\")   ? "Invalid \escape"
				  : (next == ":")   ? "Expecting ':' delimiter"
				  : (next == """")  ? "Expecting object key enclosed in double quotes"
				  : (next == """}") ? "Expecting object key enclosed in double quotes or object closing '}'"
				  : (next == ",}")  ? "Expecting ',' delimiter or object closing '}'"
				  : (next == ",]")  ? "Expecting ',' delimiter or array closing ']'"
				  : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
				    , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
				, ln, col, pos)

				throw Exception(msg, -1, ch)
			}
			
			is_array := is_arr[obj := stack[1]]
			
			if i := InStr("{[", ch)
			{
				val := (proto := args[i]) ? new proto : {}
				is_array? ObjInsert(obj, val) : obj[key] := val
				ObjInsert(stack, 1, val)
				
				is_arr[val] := !(is_key := ch == "{")
				next := is_key ? """}" : """{[]0123456789-tfn"
			}

			else if InStr("}]", ch)
			{
				ObjRemove(stack, 1)
				next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
			}

			else if InStr(",:", ch)
			{
				is_key := (!is_array && ch == ",")
				next := is_key ? """" : """{[0123456789-tfn"
			}

			else
			{
				if (ch == """")
				{
					i := pos
					while (i := InStr(src, """",, i+1))
					{
						val := SubStr(src, pos+1, i-pos-1)
						StringReplace, val, val, \\, \u005C, A
						if (SubStr(val, 0) != "\")
							break
					}
					if !i ? (pos--, next := "'") : 0
						continue
					
					pos := i

					StringReplace, val, val, \/,  /, A
					StringReplace, val, val, \",  ", A
					StringReplace, val, val, \b, `b, A
					StringReplace, val, val, \f, `f, A
					StringReplace, val, val, \n, `n, A
					StringReplace, val, val, \r, `r, A
					StringReplace, val, val, \t, `t, A

					i := 0
					while (i := InStr(val, "\",, i+1))
					{
						if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
							continue 2

						; \uXXXX - JSON unicode escape sequence
						xxxx := Abs("0x" . SubStr(val, i+2, 4))
						if (A_IsUnicode || xxxx < 0x100)
							val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
					}

					if is_key
					{
						key := val, next := ":"
						continue
					}
				}
				
				else
				{
					val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
					
					static null := "" ; for #Warn
					if InStr(",true,false,null,", "," . val . ",", true) ; if var in
						val := %val%
					else if (Abs(val) == "") ? (pos--, next := "#") : 0
						continue
					
					val := val + 0, pos += i-1
				}
				
				is_array? ObjInsert(obj, val) : obj[key] := val
				next := obj==tree ? "" : is_array ? ",]" : ",}"
			}
		}
		
		return tree[1]
	}
	/* Method: stringify
	 *     Serialize an object to a JSON formatted string.
	 * Syntax:
	 *     json_str := JSON.stringify( obj [ , indent := "" ] )
	 * Parameter(s):
	 *     obj      [in] - The object to stringify.
	 *     indent   [in] - Specify string(s) to use as indentation per level.
 	 */
	stringify(obj:="", indent:="", lvl:=1)
	{
		if IsObject(obj)
		{
			if (ObjGetCapacity(obj) == "") ; COM,Func,RegExMatch,File,Property object
				throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))
			
			is_array := 0
			for k in obj
				is_array := (k == A_Index)
			until !is_array

			if indent is integer
			{
				if (indent < 0)
					throw Exception("Indent parameter must be a postive integer.", -1, indent)
				spaces := indent, indent := ""
				Loop % spaces
					indent .= " "
			}
			indt := ""
			Loop, % indent ? lvl : 0
				indt .= indent

			lvl += 1, out := "" ; make #Warn happy
			for k, v in obj
			{
				if IsObject(k) || (k == "")
					throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
				
				if !is_array
					out .= ( ObjGetCapacity([k], 1) ? JSON.stringify(k) : """" . k . """" ) ; key
					    .  ( indent ? ": " : ":" ) ; token + padding
				out .= JSON.stringify(v, indent, lvl) ; value
				    .  ( indent ? ",`n" . indt : "," ) ; token + indent
			}
			
			if (out != "")
			{
				out := Trim(out, ",`n" indent)
				if (indent != "")
					out := Format("`n{}{}`n{}", indt, out, SubStr(indt, StrLen(indent)+1))
			}
			
			return is_array ? "[" . out . "]" : "{" . out . "}"
		}
		
		; Number
		if (ObjGetCapacity([obj], 1) == "") ; returns an integer if 'obj' is string
			return obj
		
		; String (null -> not supported by AHK)
		if (obj != "")
		{
			StringReplace, obj, obj,  \, \\, A
			StringReplace, obj, obj,  /, \/, A
			StringReplace, obj, obj,  ", \", A
			StringReplace, obj, obj, `b, \b, A
			StringReplace, obj, obj, `f, \f, A
			StringReplace, obj, obj, `n, \n, A
			StringReplace, obj, obj, `r, \r, A
			StringReplace, obj, obj, `t, \t, A

			while RegExMatch(obj, "[^\x20-\x7e]", m)
				StringReplace, obj, obj, %m%, % Format("\u{:04X}", Asc(m)), A
		}
		
		return """" . obj . """"
	}
	
	class object
	{
		
		__New(args*)
		{
			ObjInsert(this, "_", [])
			if ((count := NumGet(&args+4*A_PtrSize)) & 1)
				throw "Invalid number of parameters"
			Loop % count//2
				this[args[A_Index*2-1]] := args[A_Index*2]
		}

		__Set(key, val, args*)
		{
			ObjInsert(this._, key)
		}

		Insert(key, val)
		{
			return this[key] := val
		}
		/* Buggy - remaining integer keys are not adjusted
		Remove(args*) { 
			ret := ObjRemove(this, args*), i := -1
			for index, key in ObjClone(this._) {
				if ObjHasKey(this, key)
					continue
				ObjRemove(this._, index-(i+=1))
			}
			return ret
		}
		*/
		Count()
		{
			return NumGet(&(this._) + 4*A_PtrSize) ; Round(this._.MaxIndex())
		}

		stringify(indent:="")
		{
			return JSON.stringify(this, indent)
		}

		_NewEnum()
		{
			static proto := { "Next": JSON.object.Next }
			return { base: proto, enum: this._._NewEnum(), obj: this }
		}

		Next(ByRef key, ByRef val:="")
		{
			if (ret := this.enum.Next(i, key))
				val := this.obj[key]
			return ret
		}
	}
		
	class array
	{
			
		__New(args*)
		{
			args.base := this.base
			return args
		}

		stringify(indent:="")
		{
			return JSON.stringify(this, indent)
		}
	}
}
;}