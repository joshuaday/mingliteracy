@echo off
set file=%1%
if "%file%" == "" set file=main.lua
C:\src\luajit\bin\luajit.exe "%file%"
pause
