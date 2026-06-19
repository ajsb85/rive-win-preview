<#
.SYNOPSIS
  Register the RivePeek preview handler so Windows Explorer previews .riv files.

.DESCRIPTION
  Runs regsvr32 against RivePeek.dll, which calls DllRegisterServer. Registration
  is written under HKEY_CURRENT_USER\Software\Classes (the same scheme Microsoft's
  RecipePreviewHandler sample uses), so NO administrator rights are required.

.PARAMETER Dll
  Path to RivePeek.dll. Defaults to ..\build\bin\RivePeek.dll relative to this script.
#>
param(
    [string]$Dll = (Join-Path $PSScriptRoot "..\build\bin\RivePeek.dll")
)

$ErrorActionPreference = "Stop"
$Dll = (Resolve-Path $Dll).Path

Write-Host "Registering $Dll (per-user, no elevation needed)..."
$p = Start-Process "$env:WINDIR\System32\regsvr32.exe" -ArgumentList "/s `"$Dll`"" -Wait -PassThru
if ($p.ExitCode -ne 0) {
    Write-Error "regsvr32 failed with exit code $($p.ExitCode)"
    exit $p.ExitCode
}

# Nudge the Shell so it picks up the new association immediately.
Write-Host "Restarting Explorer to refresh associations..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer.exe
}

Write-Host "Done. Select a .riv file in Explorer with the Preview Pane (Alt+P) enabled."
