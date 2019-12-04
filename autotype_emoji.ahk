#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#singleinstance, force

; -----------------------------------------------------------------
; dependencies
; -----------------------------------------------------------------
#Include lib\Class_SQLiteDB.ahk ; loads emojis from external database

; -----------------------------------------------------------------
; tray icon
; -----------------------------------------------------------------
Menu, Tray, Icon, %A_ScriptDir%\icons\icons8-twitch-64.png

; -----------------------------------------------------------------
; Hotstring parameters
; -----------------------------------------------------------------
hotstring_hotkey = ?
    ; prefix to type before the emoji name
ahk_hotstring_option = :*X: 
    ; * immediately replace hotstring
    ; X use function to paste string
hotstring_prefix = %ahk_hotstring_option%%hotstring_hotkey%

;--------------------------------------------------
;---- load emoji hotstrings from external database ---------------
;--------------------------------------------------
emoji_dictionary := {}
twitch_dictionary := {}
userdefined_dictionary := {}

emoji_loadDB("\storage\emoji.db", "emote_storage", "hotstring", "emoji", emoji_dictionary)
emoji_loadDB("\storage\emoji.db", "twitch_storage", "hotstring", "emoji", twitch_dictionary)
emoji_loadDB("\storage\emoji.db", "userdefined_storage", "hotstring", "emoji", userdefined_dictionary)

; -----------------------------------------------------------------
; ----- add context buttons to the tray menu 
; -----------------------------------------------------------------
Menu, tray, nostandard 
Menu, Tray, Add, Emoji List, show_description ; list all available emojis
Menu, Tray, Add, Add/Remove/Edit emojis, open_dbfile
Menu, tray, add ; divider
Menu, tray, Standard ; put the standard buttons back
Menu, tray, default, emoji list ; set the default double click menu entry

; -----------------------------------------------------------------
; ----- run hotstrings only in these apps 
; -----------------------------------------------------------------
GroupAdd, TwitchApps, ahk_exe TwitchUI.exe
GroupAdd, TwitchApps, ahk_exe Twitch Sings.exe
GroupAdd, TwitchApps, ahk_exe Firefox.exe
GroupAdd, TwitchApps, ahk_exe notepad.exe ; for testing purposes

; -----------------------------------------------------------------
; ----- create the replacement hotstrings 
; -----------------------------------------------------------------
#IfWinActive ahk_group TwitchApps
For emoji_name, emoji_string in emoji_dictionary
    Hotstring(hotstring_prefix emoji_name, (Func("paste_string").Bind(emoji_string)))
For emoji_name, emoji_string in twitch_dictionary
    Hotstring(hotstring_prefix emoji_name, (Func("paste_string").Bind(emoji_string)))
For emoji_name, emoji_string in userdefined_dictionary
    Hotstring(hotstring_prefix emoji_name, (Func("paste_string").Bind(emoji_string)))
#IfWinActive

; -----------------------------------------------------------------
; ------ inserts unicode emojis from clipboard
; -----------------------------------------------------------------
paste_string(string){ ; unicode strings don't always type properly in app, but work if copy pasted from clipboard
    clipSave := ClipboardAll
    Clipboard := string
    Send, ^v
    Sleep 500
    Clipboard := clipSave ; old clipboard contents are restored
    clipSave := ""
}

; -----------------------------------------------------------------
; ------ loads emojis from a SQL database into an asociative array
; -----------------------------------------------------------------
emoji_loadDB(db_file, table, field1, field2, associative_array)
{
    DBFileName := A_ScriptDir . db_file ; <<< insert your DB file name 
    DB := New SQLiteDB
    If !DB.OpenDB(DBFileName) {
       MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
       ExitApp
    }

    SQL = SELECT %field1%, %field2% FROM %table%; ; <<< check the table and column name
    Result := ""
    If !DB.GetTable(SQL, Result)
       MsgBox, 16, SQLite Error: GetTable, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
    Else
    {
       For Each, Row In Result.Rows
            associative_array[Row[1]] := Row[2]
    }
    DB.CloseDB()
}

; -----------------------------------------------------------------
; ------ creates a GUI window to display emoji list
; -----------------------------------------------------------------
show_description()
{
    global ; allows access to variables emoji_dictionary and twitch_dictionary
    static Description_textbox, OKbutton ; local variabes are not allowed. use caution if creating multiple gui windows!
    gui, new
    gui, Default
    description_string := ""
    description_string = %description_string%User defined emotes`n`n
    for key, value in userdefined_dictionary
        description_string = %description_string%%hotstring_hotkey%%key%         %value%`n
    description_string = %description_string%`nASCII emojis`n`n
    for key, value in emoji_dictionary
        description_string = %description_string%%hotstring_hotkey%%key%         %value%`n
    description_string = %description_string%`nTwitch emotes`n`n
    for key, value in twitch_dictionary
        description_string = %description_string%%hotstring_hotkey%%key%         %value%`n    
    gui, add, edit, readonly vDescription_textbox , %description_string%
    gui, add, button, gmyguiclose vOKbutton, OK
    gui, show, , Emoji descriptions
    GuiControl, focus, OKbutton ; deselect the text in the edit box
    return winexist()

    myguiclose:
      {
      gui,destroy
      return
      }
}
; -----------------------------------------------------------------
; ------ opens databse file to add/remove/edit emojis
; ----------------------------------------------------------------- 
open_dbfile()
{
    run, "%A_ScriptDir%\storage\emoji.db"
}