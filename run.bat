@echo off
cd /d "%~dp0"

where python >nul 2>&1
if %errorlevel%==0 (
    set "PYTHON=python"
) else (
    where py >nul 2>&1
    if %errorlevel%==0 (
        set "PYTHON=py"
    ) else (
        echo Python non trovato.
        echo Installa Python e riprova.
        pause
        exit /b 1
    )
)

start "" %PYTHON% -m http.server 8000 --directory dist
timeout /t 1 /nobreak >nul
start "" "http://localhost:8000/simulatorvue/v0/"
