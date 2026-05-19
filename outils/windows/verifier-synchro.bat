@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0verifier-synchro.ps1"

echo.
pause

