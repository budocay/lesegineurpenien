@echo off
rem Construit le jeu pour Windows, macOS et Linux dans le dossier build, avec les archives a envoyer.
rem   build.bat                 les trois plateformes
rem   build.bat windows         une seule (windows, macos, linux)
rem   build.bat tout --test     lance d'abord le test rapide : rien n'est construit s'il echoue
cd /d "%~dp0"
set "QUOI=tout"
set "TEST="
for %%A in (%*) do (
  if /i "%%~A"=="--test" (set "TEST=-Test") else (set "QUOI=%%~A")
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build_windows.ps1" -Quoi %QUOI% %TEST%
set "CODE=%ERRORLEVEL%"
if not "%CODE%"=="0" echo. & echo La construction a echoue : lire le message ci-dessus (journal : build\journal_build.txt).
pause
exit /b %CODE%
