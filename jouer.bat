@echo off
rem Lance le jeu. Si Godot n'est pas encore installe (ou si son fichier est incomplet), lance d'abord l'installation.
cd /d "%~dp0"
set "GODOT=%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe"
set "TAILLE=0"
if exist "%GODOT%" for %%A in ("%GODOT%") do set "TAILLE=%%~zA"
rem un Godot de moins de 40 Mo est un telechargement coupe (erreur 193) : on reinstalle
if %TAILLE% LSS 40000000 (
  call "%~dp0installer_windows.bat"
  exit /b
)
start "" "%GODOT%" --path "%~dp0."
