~LButton & RButton:: Send, {AltDown}{Right}{AltUp} ; вперед
RButton & LButton:: Send, {AltDown}{Left}{AltUp} ; назад
$RButton:: Send, {RButton}
; ========== ПЕРЕМЕЩЕНИЕ ОКНА МЫШЬЮ (EWD) ==================
; Это - чуть-чуть переделанных скрипт из справки к AutoHotkey - Easy Window Dragging (EWD)
#LButton:: ; WIN+Левая мышь - перемещение окон за любое место внутри окна
;-----------------------------------------------------------------------------
    ; Вы можете отпустить клавишу WIN после нажатия левой кнопки, вместо того, чтобы удерживать ее
    ; И вы можете во время перемещения нажать Escape, чтобы отменить перемещение
    CoordMode, Mouse ; переключиться на абсолютные координаты экрана
    MouseGetPos, EWD_MouseStartX, EWD_MouseStartY, EWD_MouseWin ; получить начальную позицию мыши и ID окна под мышью
    WinGetClass, EWD_Win_Class, ahk_id %EWD_MouseWin% ; получаем класс окна под мышью
    If EWD_Win_Class = ProgMan ; если это рабочий стол, то...
        Return ; закончить обработку горячей клавиши
    WinGet, State, MinMax, ahk_id %EWD_MouseWin% ; проверяем не максимизировано ли окно
    If State = 1 ; если максимизировано, то...
    {
        SplashImage,, W160 H48 B1 FM10 CT000080,, Окно максимизировано,, Arial ; показать сообщение (чтоб не думалось)
        SetTimer, Remove_Splash, 600 ; переходить к указанной подпрограмме через каждые 0.6 секунды
        Return ; закончить обработку горячей клавиши

        Remove_Splash: ; подпрограмма удаления SplashImage
            SetTimer, Remove_Splash, Off ; выключить таймер
            SplashImage, Off ; удалить сплэш
        Return ; конец подпрограммы
    }
    WinGetPos, EWD_OriginalPosX, EWD_OriginalPosY,,, ahk_id %EWD_MouseWin% ; запоминаем исходные координаты окна
    SetTimer, EWD_WatchMouse, 10 ; переходить к указанной подпрограмме через каждые 10 мс
Return ; закончить обработку горячей клавиши

EWD_WatchMouse: ; подпрограмма обработки событий в таймере
    EWD_Work = 1 ; флаг, что подпрограмма выполняется (он нужен для корректной работы закрытия окон по Escape)
    GetKeyState, EWD_LButtonState, LButton, P ; проверить нажата ли левая кнопка мыши
    If EWD_LButtonState = U ; если кнопка отпущена, то закончить перемещение окна...
    {
        SetTimer, EWD_WatchMouse, off ; отключить таймер
        EWD_Work = ; сбрасываем флаг, что подпрограмма выполняется
        Return ; конец подпрограммы, закончить обработку горячей клавиши
    }
    GetKeyState, EWD_EscapeState, Escape, P ; проверить нажата ли клавиша Escape
    If EWD_EscapeState = D ; если нажата, то отменить перемещение окна (вернуть его в начальные координаты)
    {
        SetTimer, EWD_WatchMouse, off ; отключить таймер
        EWD_Work = ; сбрасываем флаг, что подпрограмма выполняется
        WinMove, ahk_id %EWD_MouseWin%,, %EWD_OriginalPosX%, %EWD_OriginalPosY% ; вернуть окно в начальные координаты
        Return ; конец подпрограммы, закончить обработку горячей клавиши
    }
    ; ...если кнопка нажата, то перемешать окно вслед за перемещением указателя мыши
    CoordMode, Mouse ; переключиться на абсолютные координаты экрана
    MouseGetPos, EWD_MouseX, EWD_MouseY ; получить текущие координаты мыши
    WinGetPos, EWD_WinX, EWD_WinY,,, ahk_id %EWD_MouseWin% ; получить позицию окна под мышкой
    SetWinDelay, -1 ; перемещать окно немедленно
    ; переместить окно под мышью вслед за мышью
    WinMove, ahk_id %EWD_MouseWin%,, EWD_WinX + EWD_MouseX - EWD_MouseStartX, EWD_WinY + EWD_MouseY - EWD_MouseStartY
    EWD_MouseStartX := EWD_MouseX ; обновить X координату для следующего вызова этой подпрограммы по таймеру
    EWD_MouseStartY := EWD_MouseY ; обновить Y координату для следующего вызова этой подпрограммы по таймеру
Return ; закончить подпрограмму и обработку горячей клавиши