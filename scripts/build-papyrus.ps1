<#
.SYNOPSIS
  Compiles papyrus\ into build\data\Scripts against the reconstructed base game sources.
  AN76 is reached by form id and CallFunction at run time, so it is not an import.
  ASCII only (Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI).
#>
[CmdletBinding()]
param(
    [string] $Base     = 'D:\F4CustomMods\PapyrusBase\Source\Base',
    [string] $Compiler = 'D:\GOGGames\Fallout 4 GOTY\Papyrus Compiler\PapyrusCompiler.exe',
    # F4SE's script sources (its Actor.psc declares GetWornItem); searched before the base sources.
    [string] $F4SE     = 'D:\GOGGames\Fallout 4 GOTY\Data\Scripts\Source'
)
$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$sources = Join-Path $root 'papyrus'
$out     = Join-Path $root 'build\data\Scripts'
if (-not (Test-Path $Compiler)) { throw "No Papyrus compiler at $Compiler." }
if (-not (Test-Path (Join-Path $Base 'Institute_Papyrus_Flags.flg'))) { throw "No Institute_Papyrus_Flags.flg in $Base." }
New-Item -ItemType Directory -Force $out | Out-Null
if (-not (Test-Path (Join-Path $F4SE 'Actor.psc'))) { throw "No F4SE script sources at $F4SE." }
$imports = @($F4SE, $Base, $sources, (Join-Path $root 'papyrus-stubs')) -join ';'
& $Compiler $sources -import="$imports" -output="$out" -flags='Institute_Papyrus_Flags.flg' -all -optimize
if ($LASTEXITCODE -ne 0) { throw "Papyrus compile failed with exit code $LASTEXITCODE." }
$pex = Get-ChildItem -Path $out -Recurse -Filter *.pex
Write-Host ("{0} .pex in {1}" -f $pex.Count, $out)
