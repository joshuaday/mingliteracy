@echo off
set file=%1%
if "%file%" == "" set file=main.lua
luajit.exe "%file%"
pause
