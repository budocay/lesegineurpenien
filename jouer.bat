@echo off
rem Lance le jeu. Si Godot n'est pas encore installe, lance d'abord l'installation.
cd /d "%~dp0"
set "GODOT=%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
  call "%~dp0installer_windows.bat"
  exit /b
)
start "" "%GODOT%" --path "%~dp0."
