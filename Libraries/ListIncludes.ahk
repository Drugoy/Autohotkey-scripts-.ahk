ListIncludes(script_file, delim="|")
{
    if !(attr := FileExist(script_file)) or InStr(attr,"D")
        return
    
    wd := A_WorkingDir
    SplitPath, script_file,, script_dir
    SetWorkingDir, %script_dir%
    
    ; ListIncludes_Recursive() uses auto-trim.
    atrim := A_AutoTrim
    AutoTrim, On
    
    ; Start the list with this file.
    list := ListIncludes_GetFullPathName(script_file)
    
    ; Recursively read and build a list of script files.
    ListIncludes_Recursive(list, script_file, script_dir, delim)
    
    SetWorkingDir, %script_dir%
    
    ; Resolve automatic includes (from the function library.)
    VarSetCapacity(temp_file, 260, 0)
    DllCall("GetTempFileName", "str", script_dir, "str", "lib", "uint", 0, "str", temp_file)
    RunWait, "%A_AhkPath%" /iLib "%temp_file%" "%script_file%"
    if (FileExist(temp_file)) {
        ListIncludes_Recursive(list, temp_file, script_dir, delim)
        FileDelete, %temp_file%
    }

    ; Restore previous auto-trim setting and working directory.
    AutoTrim, %atrim%
    SetWorkingDir, %wd%
    
    return list
}

ListIncludes_Recursive(ByRef list, script_file, script_dir, delim)
{
    FileRead, script, %script_file%

    ; Remove any text which may contain false #includes.
    script := RegExReplace(script
        , "ms`a)^\s*/\*.*?^\s*\*/\s*"  ; multi-line comments
        . "|\s*(?<!\S);.*?$"           ; single-line comments
        . "|^\s*\(.*?^\s*\)\s*")       ; continuation sections
    
    ; Techinically, continuation sections/lines may be used to split an #include
    ; across multiple lines, but this seems rare enough to ignore.
    
    pos = 1
    Loop
    {
        ; Find the next #Include or #IncludeAgain.
        ; Filename may have optional "*i " (ignore failure) prefix.
        if !(pos := RegExMatch(script
            , "mi`a)^\s*#include(?:again)?(?:\s+|\s*,\s*)(?:\*i[ `t]?)?(.+)"
            , m, pos))
            break
        pos += StrLen(m)
        
        StringReplace, m1, m1, `%A_ScriptDir`%, %script_dir%
        StringReplace, m1, m1, `%A_AppData`%, %A_AppData%
        StringReplace, m1, m1, `%A_AppDataCommon`%, %A_AppDataCommon%
        ; ';' can be escaped in an #include line, but not any other character.
        ; The third '`' is needed in this case because `; sequences are replaced
        ; before any other escape sequence.
        StringReplace, m1, m1,```;,;, All
        
        ; Skip files that don't exist.
        if !(attr := FileExist(m1))
        {
            ;MsgBox File not found:`n%m1%
            continue
        }
        
        if InStr(attr, "D")
        {   ; #include relative to this directory.
            SetWorkingDir, %m1%
            continue
        }
        
        ; Expand relative paths in full. This is important because
        ;   a) the caller doesn't necessarily know the working directory, and
        ;   b) it makes filenames consistent so that two includes of the same
        ;      file will always be recognized as duplicates.
        m1 := ListIncludes_GetFullPathName(m1)
        
        if !InStr(delim . list . delim, delim . m1 . delim) {
            list .= delim . m1
            ListIncludes_Recursive(list, m1, script_dir, delim)
        }
    }
}


ListIncludes_GetFullPathName(relative_path) {
    Loop, %relative_path%, 1
        return A_LoopFileLongPath
    return relative_path
}
