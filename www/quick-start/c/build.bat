@echo off
setlocal
cd /D "%~dp0"
call cl /nologo /FC /Z7 /Od /std:c11 main.c forbear\forbear.lib /link /INCREMENTAL:NO /out:main.exe || exit /b 1
copy /y forbear\forbear.dll . >nul
