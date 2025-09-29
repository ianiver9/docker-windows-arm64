; Docker for Windows ARM64 - Simple Installer
; Compatible installer script for Docker CLI and Engine

!define PRODUCT_NAME "Docker for Windows ARM64"
!define PRODUCT_VERSION "28.3.3-custom"
!define PRODUCT_PUBLISHER "Custom Build"

SetCompressor /SOLID lzma
Target amd64-unicode

; MUI includes
!include "MUI2.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

; Finish page with option to start Docker
!define MUI_FINISHPAGE_TEXT "Docker has been installed successfully!$\r$\n$\r$\nClick Finish to complete the installation."
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Open Command Prompt to test Docker"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchCommandPrompt"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language
!insertmacro MUI_LANGUAGE "English"

; Installer details
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "Docker-ARM64-Installer.exe"
InstallDir "$PROGRAMFILES\Docker"
ShowInstDetails show
ShowUnInstDetails show

; Version info
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "FileDescription" "Docker ARM64 Installer"
VIAddVersionKey "FileVersion" "1.0.0.0"
VIAddVersionKey "CompanyName" "${PRODUCT_PUBLISHER}"

; Installation sections
Section "Docker Engine and CLI" SEC01
  SectionIn RO  ; Required section

  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer

  ; Install Docker binaries
  File "..\docker-cli\build\docker-windows-arm64.exe"
  File "..\docker-engine\build\dockerd-windows-arm64.exe"

  ; Rename to standard names
  Rename "$INSTDIR\docker-windows-arm64.exe" "$INSTDIR\docker.exe"
  Rename "$INSTDIR\dockerd-windows-arm64.exe" "$INSTDIR\dockerd.exe"

  ; Create program folder and shortcuts
  CreateDirectory "$SMPROGRAMS\Docker"
  CreateShortCut "$SMPROGRAMS\Docker\Docker CLI.lnk" "$INSTDIR\docker.exe" "version"
  CreateShortCut "$SMPROGRAMS\Docker\Uninstall Docker.lnk" "$INSTDIR\uninst.exe"

  ; Create desktop shortcut
  CreateShortCut "$DESKTOP\Docker CLI.lnk" "$INSTDIR\docker.exe" "version"

  ; Create data directories
  CreateDirectory "$PROGRAMDATA\Docker"
  CreateDirectory "$LOCALAPPDATA\Docker"

SectionEnd

Section "Add to System PATH" SEC02
  ; Add Docker to PATH
  Push "$INSTDIR"
  Call AddToPath
SectionEnd

Section "Register Docker Service" SEC03
  DetailPrint "Setting up Docker service..."

  ; Create a batch file to register the service
  FileOpen $0 "$INSTDIR\install-service.bat" w
  FileWrite $0 "@echo off$\r$\n"
  FileWrite $0 "echo Registering Docker service...$\r$\n"
  FileWrite $0 "sc create docker binPath= $\"$INSTDIR\dockerd.exe$\" DisplayName= $\"Docker Engine$\" start= auto$\r$\n"
  FileWrite $0 "if %errorlevel% equ 0 ($\r$\n"
  FileWrite $0 "    echo Docker service created successfully.$\r$\n"
  FileWrite $0 "    echo.$\r$\n"
  FileWrite $0 "    choice /C YN /M $\"Would you like to start the Docker service now$\"$\r$\n"
  FileWrite $0 "    if !errorlevel! equ 1 ($\r$\n"
  FileWrite $0 "        echo Starting Docker service...$\r$\n"
  FileWrite $0 "        sc start docker$\r$\n"
  FileWrite $0 "        if !errorlevel! equ 0 ($\r$\n"
  FileWrite $0 "            echo Docker service started successfully.$\r$\n"
  FileWrite $0 "        ) else ($\r$\n"
  FileWrite $0 "            echo Failed to start Docker service. You may need to start it manually.$\r$\n"
  FileWrite $0 "        )$\r$\n"
  FileWrite $0 "    )$\r$\n"
  FileWrite $0 ") else ($\r$\n"
  FileWrite $0 "    echo Failed to create Docker service. You may need to run as Administrator.$\r$\n"
  FileWrite $0 ")$\r$\n"
  FileWrite $0 "pause$\r$\n"
  FileClose $0

  ; Create shortcut to service installation
  CreateShortCut "$SMPROGRAMS\Docker\Install Docker Service.lnk" "$INSTDIR\install-service.bat"

  ; Ask user if they want to install service now
  MessageBox MB_YESNO|MB_ICONQUESTION "Would you like to register Docker as a Windows service now?$\r$\n$\r$\nNote: This requires Administrator privileges." IDNO skip_service

  ; Try to register service
  ExecWait 'sc create docker binPath= "$INSTDIR\dockerd.exe" DisplayName= "Docker Engine" start= auto' $0
  ${If} $0 == 0
    DetailPrint "Docker service registered successfully."

    MessageBox MB_YESNO|MB_ICONQUESTION "Docker service created. Would you like to start it now?" IDNO skip_start

    ExecWait 'sc start docker' $1
    ${If} $1 == 0
      DetailPrint "Docker service started successfully."
    ${Else}
      DetailPrint "Failed to start Docker service. You can start it manually."
    ${EndIf}

    skip_start:
  ${Else}
    DetailPrint "Failed to register Docker service. You may need Administrator privileges."
    DetailPrint "Use the 'Install Docker Service' shortcut to try again."
  ${EndIf}

  skip_service:
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"

  ; Registry entries
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "InstallLocation" "$INSTDIR"
SectionEnd

; Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} "Docker Engine and CLI binaries (Required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} "Add Docker to system PATH for command-line access"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} "Register Docker as a Windows service"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Functions
Function LaunchCommandPrompt
  ExecShell "open" "cmd" "/k echo Docker installed! Try: docker version"
FunctionEnd

Function AddToPath
  Exch $0
  Push $1
  Push $2
  Push $3

  ReadRegStr $1 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
  Push "$1;"
  Push "$0;"
  Call StrStr
  Pop $2
  StrCmp $2 "" 0 done
  StrCmp $1 "" AddToPath_NTCurrent
    StrCpy $2 $1 1 -1
    StrCmp $2 ";" 0 +2
      StrCpy $1 $1 -1
    StrCpy $1 "$1;$0"
    Goto AddToPath_NTdoIt
  AddToPath_NTCurrent:
    StrCpy $1 $0
  AddToPath_NTdoIt:
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" $1
    SendMessage HWND_BROADCAST 0x1A 0 "STR:Environment" /TIMEOUT=5000
  done:
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

Function StrStr
  Exch $1
  Exch
  Exch $2
  Push $3
  Push $4
  Push $5
  StrLen $3 $1
  StrCpy $4 0
  loop:
    StrCpy $5 $2 $3 $4
    StrCmp $5 $1 done
    StrCmp $5 "" done
    IntOp $4 $4 + 1
    Goto loop
  done:
    StrCpy $1 $2 "" $4
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Exch $1
FunctionEnd

; Uninstaller
Section Uninstall
  ; Stop and remove service
  ExecWait 'sc stop docker'
  ExecWait 'sc delete docker'

  ; Remove from PATH
  Push "$INSTDIR"
  Call un.RemoveFromPath

  ; Remove files
  Delete "$INSTDIR\docker.exe"
  Delete "$INSTDIR\dockerd.exe"
  Delete "$INSTDIR\install-service.bat"
  Delete "$INSTDIR\uninst.exe"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\Docker\Docker CLI.lnk"
  Delete "$SMPROGRAMS\Docker\Install Docker Service.lnk"
  Delete "$SMPROGRAMS\Docker\Uninstall Docker.lnk"
  Delete "$DESKTOP\Docker CLI.lnk"
  RMDir "$SMPROGRAMS\Docker"

  ; Remove directory
  RMDir "$INSTDIR"

  ; Remove registry entries
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

  MessageBox MB_OK "Docker has been uninstalled successfully."
SectionEnd

Function un.RemoveFromPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6

  ReadRegStr $1 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
  StrCpy $5 $1 1 -1
  StrCmp $5 ";" +2
    StrCpy $1 "$1;"
  Push $1
  Push "$0;"
  Call un.StrStr
  Pop $2
  StrCmp $2 "" unRemoveFromPath_done
    StrLen $3 "$0;"
    StrLen $4 $2
    StrCpy $5 $1 -$4
    StrCpy $6 $2 "" $3
    StrCpy $3 $5$6
    StrCpy $5 $3 1 -1
    StrCmp $5 ";" 0 +2
      StrCpy $3 $3 -1
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" $3
    SendMessage HWND_BROADCAST 0x1A 0 "STR:Environment" /TIMEOUT=5000
  unRemoveFromPath_done:
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function un.StrStr
  Exch $1
  Exch
  Exch $2
  Push $3
  Push $4
  Push $5
  StrLen $3 $1
  StrCpy $4 0
  loop:
    StrCpy $5 $2 $3 $4
    StrCmp $5 $1 done
    StrCmp $5 "" done
    IntOp $4 $4 + 1
    Goto loop
  done:
    StrCpy $1 $2 "" $4
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Exch $1
FunctionEnd