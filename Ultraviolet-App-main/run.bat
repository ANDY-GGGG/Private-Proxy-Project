@echo off
title Ultraviolet App Runner
echo ==========================================
echo   Ultraviolet App - Instalar e Iniciar
echo ==========================================
echo.

:: Detect package manager
set PKG_MGR=npm
where pnpm >nul 2>nul
if %errorlevel% equ 0 (
    set PKG_MGR=pnpm
)

echo Gerenciador de pacotes detectado: %PKG_MGR%
echo.

:: Install dependencies
if not exist "node_modules\" (
    echo [INFO] Instalando as dependencias da aplicacao...
    call %PKG_MGR% install
) else (
    echo [INFO] Dependencias ja instaladas.
)

echo.
echo ==================================================
echo   Iniciando o servidor do Ultraviolet-App!
echo   Acesse no seu navegador: http://localhost:8080
echo ==================================================
echo.

call %PKG_MGR% start

pause
