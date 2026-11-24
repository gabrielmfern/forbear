& {
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$languages = 'jai', 'c'
$default = if (Get-Command jai -ErrorAction SilentlyContinue) { 'jai' } else { 'c' }

$dir = Read-Host 'Project name (untitled-program)'
if (!$dir) { $dir = 'untitled-program' }
$language = Read-Host "Language: $($languages -join ', ') ($default)"
if (!$language) { $language = $default }
if ($language -notin $languages) { throw "Unknown language '$language', expected one of: $($languages -join ', ')" }
if ($language -eq 'c' -and !(Get-Command cl -ErrorAction SilentlyContinue)) {
    throw @'
cl.exe (MSVC) is not in the PATH. Run this from "Developer PowerShell for VS".
If you don't have Visual Studio, install its C compiler with:
winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive"
'@
}

$tag = (Invoke-RestMethod 'https://api.github.com/repos/gabrielmfern/forbear/releases/latest').tag_name
$ref = if ($env:FORBEAR_REF) { $env:FORBEAR_REF } else { $tag }
$base = "https://raw.githubusercontent.com/gabrielmfern/forbear/$ref"
$release = "https://github.com/gabrielmfern/forbear/releases/download/$tag"
$main = if ($language -eq 'jai') { 'main.jai' } else { 'main.c' }
$forbear = if ($language -eq 'jai') { 'modules/forbear' } else { 'forbear' }

$files = [ordered]@{
    $main = "www/quick-start/$language/$main"
    'Inter.ttf' = 'Inter.ttf'
}
if ($language -eq 'c') { $files['build.bat'] = 'www/quick-start/c/build.bat' }

foreach ($file in $files.GetEnumerator()) {
    $out = Join-Path $dir $file.Key
    New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
    Invoke-WebRequest "$base/$($file.Value)" -OutFile $out -UseBasicParsing
}
$archive = "forbear-$language-win32.tar.gz"
$out = Join-Path $dir $forbear
New-Item -ItemType Directory -Force $out | Out-Null
$download = Join-Path ([IO.Path]::GetTempPath()) $archive
Invoke-WebRequest "$release/$archive" -OutFile $download -UseBasicParsing
tar -xzf $download -C $out
if ($LASTEXITCODE) { throw "Could not extract $archive" }
Remove-Item $download

Write-Host "Run: cd $dir"
if ($language -eq 'jai') { Write-Host '     jai main.jai +forbear' } else { Write-Host '     .\build.bat' }
}
