& {
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$languages = 'jai', 'c'
$adapters = 'none', 'javascript'

$dir = Read-Host 'Project name (untitled-program)'
if (!$dir) { $dir = 'untitled-program' }
$language = Read-Host "Language: $($languages -join ', ') (jai)"
if (!$language) { $language = 'jai' }
if ($language -notin $languages) { throw "Unknown language '$language', expected one of: $($languages -join ', ')" }
$adapter = Read-Host "Adapter: $($adapters -join ', ') (none)"
if (!$adapter) { $adapter = 'none' }
if ($adapter -notin $adapters) { throw "Unknown adapter '$adapter', expected one of: $($adapters -join ', ')" }

$ref = if ($env:FORBEAR_REF) { $env:FORBEAR_REF } else { 'main' }
$base = "https://raw.githubusercontent.com/gabrielmfern/forbear/$ref"
$release = 'https://github.com/gabrielmfern/forbear/releases/download/snapshot'
$template = if ($adapter -eq 'none') { $language } else { "$language-$adapter" }
$main = if ($language -eq 'jai') { 'main.jai' } else { 'main.c' }
$forbear = if ($language -eq 'jai') { 'modules/forbear' } else { 'forbear' }

$files = [ordered]@{
    $main = "quick-start/$template/$main"
    'Inter.ttf' = 'Inter.ttf'
}
$archives = [ordered]@{ "forbear-$language-win32" = $forbear }
if ($adapter -eq 'javascript') {
    $files['package.json'] = "quick-start/$template/package.json"
    $files['tsconfig.json'] = "quick-start/$template/tsconfig.json"
    $files['src/index.tsx'] = 'quick-start/javascript/src/index.tsx'
    $archives['libnode-win32'] = if ($language -eq 'jai') { 'modules/forbear/vendor/node/out/Release' } else { '.' }
}

foreach ($file in $files.GetEnumerator()) {
    $out = Join-Path $dir $file.Key
    New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
    Invoke-WebRequest "$base/$($file.Value)" -OutFile $out -UseBasicParsing
}
foreach ($archive in $archives.GetEnumerator()) {
    $out = Join-Path $dir $archive.Value
    New-Item -ItemType Directory -Force $out | Out-Null
    $download = Join-Path ([IO.Path]::GetTempPath()) "$($archive.Key).tar.gz"
    Invoke-WebRequest "$release/$($archive.Key).tar.gz" -OutFile $download -UseBasicParsing
    tar -xzf $download -C $out
    if ($LASTEXITCODE) { throw "Could not extract $($archive.Key).tar.gz" }
    Remove-Item $download
}

$library = if ($adapter -eq 'javascript') { 'forbear-javascript' } else { 'forbear' }
Write-Host "Run: cd $dir"
if ($adapter -eq 'javascript') { Write-Host '     npm install' }
if ($language -eq 'jai') {
    Write-Host '     jai main.jai +forbear'
} else {
    if ($adapter -eq 'javascript') { Write-Host '     npm run build' }
    Write-Host "     clang -std=c23 main.c forbear/$library.lib -o main.exe"
    Write-Host "     copy forbear\$library.dll ."
}
}
