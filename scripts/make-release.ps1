<#
.SYNOPSIS
  Builds the release zip build\dist\AN76Toilets-<VERSION>.zip: the plugin, scripts, icon and MCM page loose, the
  sounds, voices and meshes in "AN76_Toilets - Main.ba2" (uncompressed: compressed audio in a BA2 does not play),
  the pee stain's textures loose (a general BA2 does not carry textures),
  docs under Docs\AN76Toilets, and the FOMOD (tools\fomod_pack.py). Then nexus-tools' fomod-check and the sha256.
  Refuses uncommitted sources. -Draft builds the FOMOD without the cards (a check run, never a release).
  Never the dev ini: the release is built from build\data, which never holds it.
#>
[CmdletBinding()]
param([switch] $Draft, [switch] $NoBuild)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content (Join-Path $root 'VERSION') -Raw).Trim()
if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') { throw "VERSION must hold a plain x.y.z, not '$version'" }
$archive2 = 'D:\GOGGames\Fallout 4 GOTY\Tools\Archive2\Archive2.exe'
$check = Join-Path $root '..\nexus-tools\scripts\fomod-check.py'

Push-Location $root
try {
    $dirty = @(git status --porcelain -- papyrus tools sounds voice widget scripts VERSION CHANGELOG.md README.md LICENSE 2>$null)
    if ($dirty.Count -gt 0 -and -not $Draft) { throw ("Commit the sources first:`n  " + ($dirty -join "`n  ")) }
    if (-not $NoBuild) {
        foreach ($tool in 'make_esp', 'make_sounds', 'make_mcm', 'make_voice', 'make_meshes', 'make_textures', 'check_esp') {
            python "tools\$tool.py"
            if ($LASTEXITCODE) { throw "tools\$tool.py failed" }
        }
        powershell -NoProfile -File scripts\build-papyrus.ps1
        if ($LASTEXITCODE) { throw 'build-papyrus failed' }
    }
} finally { Pop-Location }

$data = Join-Path $root 'build\data'
$out = Join-Path $root "build\dist\AN76Toilets-$version"
$zip = "$out.zip"
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
New-Item -ItemType Directory -Force $out | Out-Null
foreach ($item in 'AN76_Toilets.esp', 'Scripts', 'Interface', 'MCM', 'Textures') {
    Copy-Item -Recurse (Join-Path $data $item) $out
}
if (Get-ChildItem $out -Recurse -Filter *.ini) { throw 'an .ini reached the release folder' }

# The BA2: named after the plugin so the game loads it by itself; uncompressed.
$ba2 = Join-Path $out 'AN76_Toilets - Main.ba2'
& $archive2 "$(Join-Path $data 'Sound'),$(Join-Path $data 'Meshes')" "-create=$ba2" "-root=$data" -format=General -compression=None -quiet
if ($LASTEXITCODE -or -not (Test-Path $ba2)) { throw 'Archive2 did not write the BA2' }
$loose = (Get-ChildItem (Join-Path $data 'Sound'), (Join-Path $data 'Meshes') -Recurse -File | Measure-Object Length -Sum).Sum
$packed = (Get-Item $ba2).Length
if ($packed -lt $loose) { throw "the BA2 ($packed bytes) is smaller than what went in ($loose): compressed or incomplete" }

$docs = Join-Path $out 'Docs\AN76Toilets'
New-Item -ItemType Directory -Force $docs | Out-Null
Copy-Item (Join-Path $root 'README.md'), (Join-Path $root 'CHANGELOG.md'), (Join-Path $root 'LICENSE') $docs

$packArgs = @((Join-Path $root 'tools\fomod_pack.py'), $out, $version)
if ($Draft) { $packArgs += '--draft' }
python @packArgs
if ($LASTEXITCODE) { throw 'tools\fomod_pack.py refused - nothing was packed' }

if (Test-Path $zip) { Remove-Item -Force $zip }
python -c "import pathlib,sys,zipfile; o=pathlib.Path(sys.argv[1]); z=zipfile.ZipFile(sys.argv[2],'w',zipfile.ZIP_DEFLATED); [z.write(p, p.relative_to(o).as_posix()) for p in sorted(o.rglob('*')) if p.is_file()]; z.close()" $out $zip
if ($LASTEXITCODE) { throw 'zipping failed' }

python $check $zip
if ($LASTEXITCODE -and -not $Draft) { Remove-Item -Force $zip; throw 'fomod-check failed - the zip is removed' }
$hash = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLower()
Write-Host ("{0}  {1:N1} MB  sha256 {2}{3}" -f $zip, ((Get-Item $zip).Length / 1MB), $hash, $(if ($Draft) { '  (DRAFT)' } else { '' }))
