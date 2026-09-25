$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'start-local.cmd')
exit $LASTEXITCODE
