#### Autohotkey scripts .ahk

My collection of autohotkey scripts. Some scripts are written by me, some are modified by me, some are completely created by others.

AutoHotkey is required to run and/or compile the scripts. The compiled scripts can be executed without autohotkey installed on user's machine.

To download AutoHotkey visit http://www.autohotkey.com/
<hr>
#### Scripts in alphabetical order
 
##### [AltTab FingerTips](AltTab FingerTips)
Adds a hotkey that opens a context menu (at the cursor's current position) with all the opened windows listed as menuitems.
Usage: hit the hotkey (default is F10) to open the context menu.

##### [BBCodes](BBCodes)
Adds hotkeys (that work only in browsers) to quickly put selected text into the corresponding BBCode tags.
Usage: in a browser select any text in a text field and use any hotkey to put the selected text into the corresponding BBCode tags.

##### [DetachVideo](DetachVideo)
Detach a flash container's frame from a browser into a separate window (in Windows). Doesn't play well with Firefox.
Usage: in a browser open a page with flash container, mouse over it and hit the hotkey (default is F12).

##### [DevTools](DevTools)
This is a bunch of scripts that either are developer tools or small code examples (like "best practice") for some specific tasks, like exchanging values of 2 variables without creating a 3rd temporary variable. Some codes are taken directly from the ahk documentation.

##### [DropCommand](DropCommand)
Enable drag and drop of files to a command window (pastes them as paths to the files).

##### [DrugWinManager](DrugWinManager)
Quite a heavy script with lots of functions, all of which are targeted to bring more control over the windows. For example, it lets you scroll inactive windows without activating them, lets you scroll over taskbars in some programs (like some browsers and text editors) to switch tabs, lets you set/remove "always on top" flag for the window under the cursor or the active window, lets you quickly resize&move the active window to a predifined positions (any half or any quarter of the screen's "usable area" [monitor's area excluding taskbar area]), lets you hide/restore titlebars of the windows or lets you move the inactive window without activating it.
The script uses lots of hotkeys, but many of them by default use non-standard buttons of mouse and keyboard, so if your mouse and/or keyboard lack those buttons - you'll have to re-configure those hotkeys.
Also, the script has quite much stuff that you'd probably won't be interested in (that stuff was written to fit my own needs only).

##### [FlashPluginUnpacker.ahk-4FxPE](FlashPluginUnpacker.ahk-4FxPE)
Written for Firefox Portable users who need Flash Player's dll files, but who don't want to install it into the system.
You put this script into your "%firefoxportable%\Data\Plugins" folder, download Flash Plugin from <a href="http://portableappz.blogspot.ru/2011/03/flash-1021531-10318042-plugins.html">here</a> and just drag'n'drop the exe file you downloaded onto the script.
This script requires you to have 7-Zip installed. The script is capable of running from a different place (it will then prompt the user to specify the path to the "%firefoxportable%\Data\Plugins" folder, and it also can backup old dlls. And if plugin-container.exe process is running - the script kills it to unlock the files that are in use but need to be replaced.

##### [GoneIn60s](GoneIn60s)
Recover closed applications. Features:
- Click the X or press Alt-F4 to close an application
- To recover, rightclick the tray icon and choose an application
- Doubleclick the tray icon to recover all applications
- If not restored, it is gone in 60 seconds

##### [Icon Menu Launcher](Icon Menu Launcher)
Very short script that just demonstrates the idea of how to combine multiple shortcuts into a single one that opens a context menu, where each menuitem runs a corresponding shortcut.

##### [Libraries](Libraries)
These are the libs, which may be required by some of the scripts.

##### [MoveOut](MoveOut)
Make rules to move files automatically. Use it to make a rule that moves files from the desktop to a subfolder, based on file type, part of a filename, or whatever. Have it ask to replace existing files, or rename them. It can also ignore files. Features:
- Rightclick the tray icon to configure
- Choose Settings to change rules and options
- Choose Enable to Start or Stop all the rules

##### [Meta Shortcut](Meta Shortcut)
An improved version of "[Icon Menu Launcher](Icon Menu Launcher)" script.
Shows a list of menuitems: if you click any of them - they act as shortcuts to the files previously drag'n'dropped onto it. The script supports drag'n'drop of multiple files at once.

##### [Outdated](Outdated)
This folder contains outdated script, mostly obsolete by the newer realizations. You don't need any of them.

##### [PerApplicationVolumeControl](PerApplicationVolumeControl)
Adds hotkeys to contol the volume level of the active application (not the general volume level in the whole system).
The whole script could be cut down to just a few lines, if you'd use <a href="http://www.nirsoft.net/utils/nircmd.html">NirCmd</a> (read the script's code to learn how).

##### [Remap ALT+F4 to CTRL+W](Remap ALT+F4 to CTRL+W)
Makes "Ctrl+W" hotkey work as "Alt+F4" for lots of different programs and system windows. I like Ctrl+W more than Alt+F4, as it's keys are closer to each other.

##### [SOT2ST](SOT2ST)
SOT2ST stand for "Scroll Over Taskbar To Switch Tasks": move cursor over TaskBar in Windows and scroll the mouse wheel up/down to switch between windows: when you will move the cursor away from TaskBar - the pre-selected window will get activated.
This is a not yet finished script and it is generally quite buggy at the moment, not recommended for use.

##### [ScriptManager.ahk](ScriptManager.ahk)
This folder contains different ahk scripts managers.
One of them is MasterScript, which is an advanced scripts manager for AHK scripts:
- it has a TreeView to let you navigate among your folders to the .ahk files;
- it supports bookmarking the paths of .ahk files;
- it supports bookmarking the paths to any folders (for easier navigation in future);
- it tracks the connection/disconnection of removable drives;
- it is capable of scanning the memory for the running .ahk scripts to display data about their processes and to control by sending commands to them;
- it also has an awesome feature of "Process Assistant" that lets you bind any processes and/or scripts together in a very flexible way, so, for example, you could make running a notepad.exe also run notepadAssistantScript.ahk and depending on the rule type you chose - you can make killing the calc.exe also kill that script too.

##### [SilentScreenshotter](SilentScreenshotter)
A very ascetic yet powerful screenshotter that lets you select the area to make screenshot of, then uses a lossless compression to minimize the file's size, then automatically uploads the screenshot to Imgur and finally copies (and/or opens) the path to the screenshot. Supports drag'n'drop of images to upload them to Imgur.
The script requries some pre-configuration before it can be used, so read the header in the script's code.

##### [TheEnd](TheEnd)
Unselect the file type when renaming files in XP (just like it is by default in Windows 7).

##### [TransliterateText](TransliterateText)
Quite an unstable script yet. It adds ru<>en transliteration of the last word/line/whole text like qwerty<>йцукен.

##### [VDesktops](VDesktops)
Adds pseudo-virtual desktops: first, hit "Win+Shift+0/1/2/3" to bind windows to desktops and then hit "Win+0/1/2/3" to switch to those desktops.

##### [WinTraymin](WinTraymin)
Right click the "minimize" button to minimize a window into a trayicon. Left/Middle/Right click on the trayicon will restore the window. And if the window is activated via other means the corresponding trayicon will be removed too.

##### [hyde](hyde)
Nearly blackhat: hyde.dll hides a process from the task manager on Windows 2000 - Windows 7 x86 & x64 bit OSes. Your process can inject it into other processes however you like. The example uses SetWindowsHookEx with a CBT hook (the dll exports a CBTProc) to inject it into all running processes.
