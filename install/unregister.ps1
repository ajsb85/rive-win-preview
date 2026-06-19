<#
.SYNOPSIS
  Unregister the RivePeek preview handler (regsvr32 /u, calls DllUnregisterServer).
  Per-user (HKCU) registration, so no administrator rights are required.
#>
param(
    [string]$Dll = (Join-Path $PSScriptRoot "..\build\bin\RivePeek.dll")
)

$ErrorActionPreference = "Stop"
$Dll = (Resolve-Path $Dll).Path

Write-Host "Unregistering $Dll ..."
$p = Start-Process "$env:WINDIR\System32\regsvr32.exe" -ArgumentList "/u /s `"$Dll`"" -Wait -PassThru
if ($p.ExitCode -ne 0) { Write-Error "regsvr32 /u failed: $($p.ExitCode)"; exit $p.ExitCode }

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
Write-Host "Done."
