@echo off
title Kaisen - Mantener conexion con el servidor
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe

echo Vigilando la conexion USB del telefono...
echo Deja esta ventana abierta mientras uses la app.
echo (Puedes minimizarla, pero no la cierres)
echo.

:loop
"%ADB%" reverse tcp:80 tcp:80 >nul 2>&1
timeout /t 3 /nobreak >nul
goto loop
