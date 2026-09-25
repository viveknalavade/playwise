@echo off
setlocal
cd /d "%~dp0"
if not exist "node_modules\mysql2\package.json" (
  call npm.cmd ci
  if errorlevel 1 exit /b 1
)
node --env-file-if-exists=.env start-local.js
exit /b %errorlevel%
