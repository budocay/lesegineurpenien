@echo off
rem Lance le jeu et ecrit tout ce qu il dit dans journal.txt (a envoyer en cas de probleme).
cd /d "%~dp0"
start "" "%~dp0SeigneurDesAnneauxPeniens.exe" --log-file "%~dp0journal.txt"
echo Le jeu est lance. Le journal sera dans journal.txt, a cote du jeu.
timeout /t 4 >nul
