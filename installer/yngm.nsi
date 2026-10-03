Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"
!include "WinVer.nsh"
!include "WinMessages.nsh"

!define APP_NAME "Escape from the Permanent Underclass"
!define APP_VERSION "1.0.1"
!define APP_ID "YNGM-Escape-Permanent-Underclass-1"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\YNGM"
!define COVER_ART_WIDTH 1170
!define COVER_ART_HEIGHT 909
!define PROGRESS_BAR_ID 1004
!define /ifndef SWP_NOSIZE 0x0001
!define /ifndef SWP_NOZORDER 0x0004
!define /ifndef SWP_NOACTIVATE 0x0010
!define /math STATIC_TEXT_STYLE ${WS_CHILD} | ${WS_VISIBLE}
!define /math STATIC_BITMAP_STYLE ${STATIC_TEXT_STYLE} | ${SS_BITMAP}
!define /math STATIC_CLIP_STYLE ${STATIC_TEXT_STYLE} | ${WS_CLIPCHILDREN}
!define /math MOVE_WITHOUT_SIZE ${SWP_NOSIZE} | ${SWP_NOZORDER}
!define /math MOVE_ONLY_FLAGS ${MOVE_WITHOUT_SIZE} | ${SWP_NOACTIVATE}
!define TIP_SLIDE_STEPS 8
!define TIP_SLIDE_PIXELS 4

Name "${APP_NAME}"
OutFile "${OUTPUT_FILE}"
InstallDir "$LOCALAPPDATA\Programs\YNGM"
InstallDirRegKey HKCU "Software\YNGM" "InstallPath"
RequestExecutionLevel user
SetCompressor /SOLID zlib
ShowInstDetails nevershow
ShowUninstDetails show
Icon "${PACKAGE_ROOT}\yngm.ico"
UninstallIcon "${PACKAGE_ROOT}\yngm.ico"
BrandingText "YNGM"
VIProductVersion "1.0.1.0"
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "FileDescription" "YNGM Windows installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "See bundled credits and licence notices."

Var TestMode
Var ArtworkBitmap
Var TipLabel
Var NextTip

ReserveFile /plugin AdvSplash.dll
ReserveFile "${ARTWORK_ROOT}\splash.bmp"
ReserveFile "${ARTWORK_ROOT}\install-art.bmp"

!define MUI_ICON "${PACKAGE_ROOT}\yngm.ico"
!define MUI_UNICON "${PACKAGE_ROOT}\yngm.ico"
!define MUI_ABORTWARNING
!define MUI_LICENSEPAGE_TEXT_TOP "Credits and licence information for the components included with this game."
!define MUI_LICENSEPAGE_BUTTON "Next >"
!define MUI_FINISHPAGE_RUN "$INSTDIR\YNGM.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Play Escape from the Permanent Underclass"
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\CREDITS-AND-LICENSES.txt"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Read credits and licences"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_WELCOMEFINISHPAGE_BITMAP "${ARTWORK_ROOT}\welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${ARTWORK_ROOT}\welcome.bmp"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${PACKAGE_ROOT}\CREDITS-AND-LICENSES.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!define MUI_PAGE_CUSTOMFUNCTION_SHOW ShowInstallArtwork
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH
!insertmacro MUI_LANGUAGE "English"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "This game requires 64-bit Windows."
    Abort
  ${EndIf}
  ${IfNot} ${AtLeastWin10}
    MessageBox MB_OK|MB_ICONSTOP "This game requires Windows 10 or later."
    Abort
  ${EndIf}
  SetShellVarContext current
  StrCpy $TestMode ""
  ${GetParameters} $0
  ${GetOptions} $0 "/TESTMODE" $TestMode
  ${IfNot} ${Errors}
    StrCpy $TestMode "1"
  ${EndIf}
  ${IfNot} ${Silent}
    Call ShowCoverArtSplash
  ${EndIf}
FunctionEnd

Function ShowCoverArtSplash
  InitPluginsDir
  File "/oname=$PLUGINSDIR\splash.bmp" "${ARTWORK_ROOT}\splash.bmp"
  File "/oname=$PLUGINSDIR\install-art.bmp" "${ARTWORK_ROOT}\install-art.bmp"
  advsplash::show 1800 500 400 -1 "$PLUGINSDIR\splash"
  Pop $0
FunctionEnd

Function ShowInstallArtwork
  FindWindow $0 "#32770" "" $HWNDPARENT
  System::Call "*(i 0, i 0, i 0, i 0) p .r1"
  System::Call "user32::GetClientRect(p r0, p r1)"
  System::Call "*$1(i, i, i .r2, i .r3)"
  GetDlgItem $4 $0 ${PROGRESS_BAR_ID}
  System::Call "user32::GetWindowRect(p r4, p r1)"
  System::Call "user32::MapWindowPoints(p 0, p r0, p r1, i 2)"
  System::Call "*$1(i, i, i, i .r5)"
  System::Free $1
  IntOp $5 $5 + 12
  IntOp $6 $3 - $5
  IntOp $7 $6 * ${COVER_ART_WIDTH}
  IntOp $7 $7 / ${COVER_ART_HEIGHT}
  System::Call 'user32::LoadImage(p 0, t "$PLUGINSDIR\install-art.bmp", i ${IMAGE_BITMAP}, i r7, i r6, i ${LR_LOADFROMFILE}) p .s'
  Pop $ArtworkBitmap
  System::Call 'user32::CreateWindowEx(i 0, t "STATIC", t "", i ${STATIC_BITMAP_STYLE}, i 0, i r5, i r7, i r6, p r0, p 0, p 0, p 0) p .r8'
  SendMessage $8 ${STM_SETIMAGE} ${IMAGE_BITMAP} $ArtworkBitmap
  IntOp $7 $7 + 14
  IntOp $2 $2 - $7
  System::Call 'user32::CreateWindowEx(i 0, t "STATIC", t "TIPS AND TRICKS", i ${STATIC_TEXT_STYLE}, i r7, i r5, i r2, i 20, p r0, p 0, p 0, p 0) p .r8'
  CreateFont $1 "$(^Font)" 10 700
  SendMessage $8 ${WM_SETFONT} $1 1
  SetCtlColors $8 0xB34700 transparent
  IntOp $5 $5 + 28
  IntOp $6 $6 - 28
  System::Call 'user32::CreateWindowEx(i 0, t "STATIC", t "", i ${STATIC_CLIP_STYLE}, i r7, i r5, i r2, i r6, p r0, p 0, p 0, p 0) p .r9'
  System::Call 'user32::CreateWindowEx(i 0, t "STATIC", t "", i ${STATIC_TEXT_STYLE}, i 0, i 0, i r2, i r6, p r9, p 0, p 0, p 0) p .s'
  Pop $TipLabel
  CreateFont $1 "$(^Font)" 10
  SendMessage $TipLabel ${WM_SETFONT} $1 1
  SendMessage $TipLabel ${WM_SETTEXT} 0 "STR:The Foam Dart Blaster never runs dry. Hold the trigger and keep moving."
FunctionEnd

Function SlideInNextTip
  ${If} $TipLabel == ""
    Return
  ${EndIf}
  ${For} $R0 1 ${TIP_SLIDE_STEPS}
    IntOp $R1 $R0 * -${TIP_SLIDE_PIXELS}
    System::Call "user32::SetWindowPos(p $TipLabel, p 0, i 0, i $R1, i 0, i 0, i ${MOVE_ONLY_FLAGS})"
    Sleep 15
  ${Next}
  SendMessage $TipLabel ${WM_SETTEXT} 0 "STR:$NextTip"
  ${ForEach} $R0 ${TIP_SLIDE_STEPS} 0 - 1
    IntOp $R1 $R0 * ${TIP_SLIDE_PIXELS}
    System::Call "user32::SetWindowPos(p $TipLabel, p 0, i 0, i $R1, i 0, i 0, i ${MOVE_ONLY_FLAGS})"
    Sleep 15
  ${Next}
FunctionEnd

!macro SHOW_TIP TEXT
  StrCpy $NextTip "${TEXT}"
  Call SlideInNextTip
!macroend

Function .onGUIEnd
  ${If} $ArtworkBitmap != ""
    System::Call "gdi32::DeleteObject(p $ArtworkBitmap)"
  ${EndIf}
FunctionEnd

Section "Game and licences" GameSection
  SectionIn RO
  SetOutPath "$INSTDIR"
  File /r /x YNGM.exe /x YNGM.pck "${PACKAGE_ROOT}\*"
  !insertmacro SHOW_TIP "Green BRIDGE ROUND crates restore runway. Your difficulty decides how much."
  File "${PACKAGE_ROOT}\YNGM.exe"
  !insertmacro SHOW_TIP "Frame rate low? Pick GRAPHICS: MEDIUM or LOW on the main menu. SHOW FPS adds a counter."
  File "${PACKAGE_ROOT}\YNGM.pck"
  !insertmacro SHOW_TIP "Too hard? EASY - TRUST FUND gives you more runway and longer timers."
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  FileOpen $0 "$INSTDIR\YNGM-install.marker" w
  FileWrite $0 "${APP_ID}"
  FileClose $0
  ${If} $TestMode != "1"
    WriteRegStr HKCU "Software\YNGM" "InstallPath" "$INSTDIR"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "YNGM"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\YNGM.exe"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
    WriteRegStr HKCU "${UNINSTALL_KEY}" "QuietUninstallString" '$\"$INSTDIR\Uninstall.exe$\" /S'
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
    WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
  ${EndIf}
SectionEnd

Section "Start-menu shortcuts" StartMenuSection
  SectionIn RO
  !insertmacro SHOW_TIP "Press R to restart a level instantly. LEVEL SELECT replays any level you have reached."
  ${If} $TestMode != "1"
    CreateDirectory "$SMPROGRAMS\YNGM"
    CreateShortcut "$SMPROGRAMS\YNGM\${APP_NAME}.lnk" "$INSTDIR\YNGM.exe" "" "$INSTDIR\YNGM.exe"
    CreateShortcut "$SMPROGRAMS\YNGM\Credits and licences.lnk" "$INSTDIR\CREDITS-AND-LICENSES.txt" "" "$INSTDIR\YNGM.exe"
    CreateShortcut "$SMPROGRAMS\YNGM\Uninstall.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\YNGM.exe"
  ${EndIf}
SectionEnd

Section /o "Desktop shortcut" DesktopSection
  ${If} $TestMode != "1"
    CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\YNGM.exe" "" "$INSTDIR\YNGM.exe"
  ${EndIf}
SectionEnd

Function un.onInit
  SetShellVarContext current
  IfFileExists "$INSTDIR\YNGM-install.marker" 0 invalid_install
  FileOpen $0 "$INSTDIR\YNGM-install.marker" r
  FileRead $0 $1
  FileClose $0
  StrCmp $1 "${APP_ID}" valid_install invalid_install
invalid_install:
  MessageBox MB_OK|MB_ICONSTOP "The game installation marker is missing or invalid. No files were removed."
  Abort
valid_install:
FunctionEnd

Section "Uninstall"
  !include "uninstall-files.nsh"
  Delete "$INSTDIR\YNGM-install.marker"
  Delete "$INSTDIR\Uninstall.exe"
  ReadRegStr $0 HKCU "Software\YNGM" "InstallPath"
  ${If} $0 == $INSTDIR
    Delete "$SMPROGRAMS\YNGM\${APP_NAME}.lnk"
    Delete "$SMPROGRAMS\YNGM\Credits and licences.lnk"
    Delete "$SMPROGRAMS\YNGM\Uninstall.lnk"
    RMDir "$SMPROGRAMS\YNGM"
    Delete "$DESKTOP\${APP_NAME}.lnk"
    DeleteRegKey HKCU "${UNINSTALL_KEY}"
    DeleteRegKey HKCU "Software\YNGM"
  ${EndIf}
  RMDir "$INSTDIR"
SectionEnd