@echo off
title PaisaLand Installer Loader
color 0b
echo ===============================================
echo     Iniciando Instalador de PaisaLand...
echo ===============================================
echo.
echo Cargando interfaz grafica...
type nul > "%temp%\PaisaLand_Log.txt"

:: Ejecutar el script de PowerShell ignorando politicas de restriccion
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0Installer.ps1'"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] No se pudo iniciar el instalador.
    echo Asegurate de que tienes PowerShell instalado.
    pause
)
