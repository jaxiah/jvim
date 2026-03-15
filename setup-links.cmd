@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-links.ps1" -RepoPath "%~dp0."
pause
