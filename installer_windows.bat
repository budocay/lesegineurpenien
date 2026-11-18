@echo off
rem Le Seigneur des Anneaux Peniens : installation automatique pour Windows.
rem Double-cliquer sur ce fichier. Il telecharge Godot dans tools\godot, prepare le jeu, puis le lance.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\installer_windows.ps1"
if errorlevel 1 (
  echo.
  echo L'installation a echoue. Lire le message ci-dessus.
  pause
  exit /b 1
)
call "%~dp0jouer.bat"
