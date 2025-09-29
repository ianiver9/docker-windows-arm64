; Docker for Windows ARM64 Installer Script
; This script creates an installer for Docker CLI and Engine compiled for Windows ARM64

; Basic installer information
!define PRODUCT_NAME "Docker for Windows ARM64"
!define PRODUCT_VERSION "28.3.3-custom"
!define PRODUCT_PUBLISHER "Custom Build"
!define PRODUCT_WEB_SITE "https://github.com/docker/cli"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\docker.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

SetCompressor lzma

; MUI 2 includes
!include "MUI2.nsh"
!include "ServiceLib.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Language Selection Dialog Settings
!define MUI_LANGDLL_REGISTRY_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define MUI_LANGDLL_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "NSIS:Language"

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; License page (we'll use Docker's license)
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
; Components page
!insertmacro MUI_PAGE_COMPONENTS
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_RUN "$INSTDIR\docker.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "version"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; Reserve files
!insertmacro MUI_RESERVEFILE_LANGDLL

; MUI end ------

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "Docker-ARM64-Installer.exe"
InstallDir "$PROGRAMFILES\Docker"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

; Version Information
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "Comments" "Docker Engine and CLI compiled for Windows ARM64"
VIAddVersionKey "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey "LegalTrademarks" "Docker is a trademark of Docker, Inc."
VIAddVersionKey "LegalCopyright" "© Docker, Inc."
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} Installer"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}"

Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY

  ; Check if running on ARM64
  ${IfNot} ${IsNativeARM64}
    MessageBox MB_ICONSTOP|MB_OK "This installer is designed for Windows ARM64 systems only.$\r$\nPlease use the appropriate Docker version for your architecture."
    Abort
  ${EndIf}

  ; Check Windows version (Windows 10 version 1803 or later required)
  ${If} ${AtMostWin10}
    ${AndIfNot} ${AtLeastBuild} 17134
      MessageBox MB_ICONSTOP|MB_OK "Windows 10 version 1803 (build 17134) or later is required for Docker."
      Abort
    ${EndIf}
  ${EndIf}
FunctionEnd

Section "Docker Engine and CLI" SEC01
  SectionIn RO
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer

  ; Copy Docker binaries
  File "..\docker-cli\build\docker-windows-arm64.exe"
  File "..\docker-engine\build\dockerd-windows-arm64.exe"

  ; Rename files to standard names
  Rename "$INSTDIR\docker-windows-arm64.exe" "$INSTDIR\docker.exe"
  Rename "$INSTDIR\dockerd-windows-arm64.exe" "$INSTDIR\dockerd.exe"

  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\Docker"
  CreateShortCut "$SMPROGRAMS\Docker\Docker CLI.lnk" "$INSTDIR\docker.exe" "version"
  CreateShortCut "$DESKTOP\Docker CLI.lnk" "$INSTDIR\docker.exe" "version"
SectionEnd

Section "Register Docker Service" SEC02
  ; Create the Docker service
  DetailPrint "Registering Docker service..."

  ; Stop service if it exists
  !insertmacro SERVICE "stop" "docker" ""
  !insertmacro SERVICE "delete" "docker" ""

  ; Create new service
  !insertmacro SERVICE "create" "docker" "path=$INSTDIR\dockerd.exe;autostart=1;depend=;display=Docker Engine;description=Docker Engine for container management;"

  Pop $0 ; return value/error/timeout
  ${If} $0 != "success"
    DetailPrint "Warning: Failed to create Docker service. You may need to run as Administrator."
  ${Else}
    DetailPrint "Docker service registered successfully."

    ; Ask user if they want to start the service
    MessageBox MB_YESNO|MB_ICONQUESTION "Would you like to start the Docker service now?" IDNO skip_start

    !insertmacro SERVICE "start" "docker" ""
    Pop $0
    ${If} $0 != "success"
      DetailPrint "Warning: Failed to start Docker service. You may need to start it manually."
    ${Else}
      DetailPrint "Docker service started successfully."
    ${EndIf}

    skip_start:
  ${EndIf}
SectionEnd

Section "Add to System PATH" SEC03
  ; Add Docker directory to system PATH
  DetailPrint "Adding Docker to system PATH..."

  ; Read current PATH
  ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"

  ; Check if Docker path is already in PATH
  ${StrContains} $1 "$INSTDIR" "$0"
  ${If} $1 == ""
    ; Add to PATH
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$0;$INSTDIR"

    ; Broadcast WM_SETTINGCHANGE message
    SendMessage HWND_BROADCAST 0x1A 0 "STR:Environment" /TIMEOUT=5000

    DetailPrint "Docker added to system PATH."
  ${Else}
    DetailPrint "Docker path already exists in system PATH."
  ${EndIf}
SectionEnd

Section "Docker Data Directory" SEC04
  ; Create Docker data directory
  CreateDirectory "$APPDATA\Docker"
  CreateDirectory "$PROGRAMDATA\Docker"

  ; Set permissions (this would require additional tools in a real scenario)
  DetailPrint "Docker data directories created."
SectionEnd

Section -AdditionalIcons
  WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
  CreateShortCut "$SMPROGRAMS\Docker\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\Docker\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\docker.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\docker.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

; Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} "Docker Engine (dockerd.exe) and CLI (docker.exe) - Required components"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} "Register Docker as a Windows service and optionally start it"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} "Add Docker to the system PATH so it can be used from any command prompt"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} "Create Docker data directories for container storage"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  ; Stop and remove Docker service
  !insertmacro SERVICE "stop" "docker" ""
  !insertmacro SERVICE "delete" "docker" ""

  ; Remove from PATH
  ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
  ${StrRep} $1 "$0" ";$INSTDIR" ""
  ${StrRep} $0 "$1" "$INSTDIR;" ""
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$0"

  ; Remove files
  Delete "$INSTDIR\${PRODUCT_NAME}.url"
  Delete "$INSTDIR\uninst.exe"
  Delete "$INSTDIR\docker.exe"
  Delete "$INSTDIR\dockerd.exe"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\Docker\Uninstall.lnk"
  Delete "$SMPROGRAMS\Docker\Website.lnk"
  Delete "$SMPROGRAMS\Docker\Docker CLI.lnk"
  Delete "$DESKTOP\Docker CLI.lnk"

  RMDir "$SMPROGRAMS\Docker"
  RMDir "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd