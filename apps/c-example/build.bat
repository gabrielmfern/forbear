@echo off
pushd %~dp0
clang -std=c11 -g main.c ..\..\c-api\forbear.lib -o main.exe || goto :end
copy /y ..\..\c-api\forbear.dll . >nul
:end
popd