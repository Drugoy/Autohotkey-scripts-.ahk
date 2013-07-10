Menu, Launch_Menu, Add, Assassin's Creed, Launch_Menu_Handler
Menu, Launch_Menu, Add, Grid Racing     , Launch_Menu_Handler
Menu, Launch_Menu, Add, Deadspace       , Launch_Menu_Handler
Menu, Launch_Menu, Add, Silent Hill     , Launch_Menu_Handler

Menu, Launch_Menu, Show

Launch_Menu_Handler:
{
    If ( A_ThisMenuItem = "Assassin's Creed" )
    {
        Run, c:\path\to\assassin's creed\game.exe
    }
    Else If ( A_ThisMenuItem = "Grid Racing" )
    {
        Run, c:\path\to\grid racing\game.exe
    }
    Else If ( A_ThisMenuItem = "Deadspace" )
    {
        Run, c:\path\to\deadspace\game.exe
    }
    Else If ( A_ThisMenuItem = "Silent Hill" )
    {
        Run, c:\path\to\slient hill\game.exe
    }
    ExitApp
}
Return