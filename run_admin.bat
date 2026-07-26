@echo off
title Watheqa Web Admin & DevOps Portal
echo ===================================================
echo   Watheqa | وثيقة Web Admin Portal Launcher 🚀
echo ===================================================
echo.
echo Opening Admin Dashboard in your browser...
start http://localhost:8080
echo.
cd /d "%~dp0admin_dashboard"
python -m http.server 8080
pause
