@echo off
pushd %~dp0
call npm run build || goto :end
clang -std=c23 -g main.c forbear\forbear-javascript.lib -o main.exe || goto :end
copy /y forbear\forbear-javascript.dll . >nul
:end
popd
