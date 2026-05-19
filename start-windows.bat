@echo off
setlocal

cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
    echo Node.js was not found. Install Node.js 20 or newer, then run this file again.
    exit /b 1
)

where npm >nul 2>nul
if errorlevel 1 (
    echo npm was not found. Install Node.js with npm, then run this file again.
    exit /b 1
)

if not exist "node_modules\" (
    echo Installing npm dependencies...
    call npm install
    if errorlevel 1 exit /b 1
)

echo Starting Prompt Library Admin...
echo Open http://127.0.0.1:5177
call npm run admin
