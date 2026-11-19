@echo off
pushd %~dp0
clang -std=c23 -g main.c forbear\forbear.lib -o main.exe || goto :end
copy /y forbear\forbear.dll . >nul
:end
popd
