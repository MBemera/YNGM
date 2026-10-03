Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"
!include "WinVer.nsh"

!define APP_NAME "Escape from the Permanent Underclass"
!define APP_VERSION "1.0.0"
!define APP_ID "YNGM-Escape-Permanent-Underclass-1"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\YNGM"

Name "${APP_NAME}"
OutFile "${OUTPUT_FILE}"
InstallDir "$LOCALAPPDATA\Programs\YNGM"
InstallDirRegKey HKCU "Software\YNGM" "InstallPath"
RequestExecutionLevel user
SetCompressor /SOLID zlib
ShowInstDetails show
ShowUninstDetails show
Icon "${PACKAGE_ROOT}\yngm.ico"
UninstallIcon "${PACKAGE_ROOT}\yngm.ico"
BrandingText "YNGM"
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "FileDescription" "YNGM Windows installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "See bundled credits and licence notices."

Var TestMode

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

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${PACKAGE_ROOT}\CREDITS-AND-LICENSES.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
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
FunctionEnd

Section "Game and licences" GameSection
  SectionIn RO
  SetOutPath "$INSTDIR"
  File /r "${PACKAGE_ROOT}\*"
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