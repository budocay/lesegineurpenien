@echo off
rem Construit le jeu pour Windows, macOS et Linux dans le dossier build.
rem   build.bat            les trois
rem   build.bat windows    une seule (windows, macos, linux)
cd /d "%~dp0"
if "%~1"=="" (powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build_windows.ps1") else (powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build_windows.ps1" -Quoi %1)
pause
