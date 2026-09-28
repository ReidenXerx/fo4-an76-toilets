<#
.SYNOPSIS
  Compiles papyrus\ into build\data\Scripts against the reconstructed base game sources.
  AN76 is reached by form id and CallFunction at run time, so it is not an import.
  ASCII only (Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI).
#>
[CmdletBinding()]
param(
    [string] $Base     = 'D:\F4CustomMods\PapyrusBase\Source\Base',
    [string] $Compiler = 'D:\GOGGames\Fallout 4 GOTY\Papyrus Compiler\PapyrusCompiler.exe'
)
$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$sources = Join-Path $root 'papyrus'
$out     = Join-Path $root 'build\data\Scripts'
if (-not (Test-Path $Compiler)) { throw "No Papyrus compiler at $Compiler." }
if (-not (Test-Path (Join-Path $Base 'Institute_Papyrus_Flags.flg'))) { throw "No Institute_Papyrus_Flags.flg in $Base." }
New-Item -ItemType Directory -Force $out | Out-Null
$imports = @($Base, $sources, (Join-Path $root 'papyrus-stubs')) -join ';'
& $Compiler $sources -import="$imports" -output="$out" -flags='Institute_Papyrus_Flags.flg' -all -optimize
if ($LASTEXITCODE -ne 0) { throw "Papyrus compile failed with exit code $LASTEXITCODE." }
$pex = Get-ChildItem -Path $out -Recurse -Filter *.pex
Write-Host ("{0} .pex in {1}" -f $pex.Count, $out)
