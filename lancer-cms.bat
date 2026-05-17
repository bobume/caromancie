@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\scripts\cms-server.ps1"
pause
