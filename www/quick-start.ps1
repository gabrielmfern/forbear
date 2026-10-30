& {
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$dir = Read-Host 'Project name (untitled-program)'
if (!$dir) { $dir = 'untitled-program' }
$ref = if ($env:FORBEAR_REF) { $env:FORBEAR_REF } else { 'main' }
$base = "https://raw.githubusercontent.com/gabrielmfern/forbear/$ref"
$files = [ordered]@{
    'main.jai' = 'apps/quick-start.jai'
    'Inter.ttf' = 'apps/Inter.ttf'
    'modules/forbear/bindings-darwin.jai' = 'bindings-darwin.jai'
    'modules/forbear/bindings-linux.jai' = 'bindings-linux.jai'
    'modules/forbear/bindings-win32.jai' = 'bindings-win32.jai'
    'modules/forbear/vendor/freetype-win32.lib' = 'vendor/freetype-win32.lib'
    'modules/forbear/vendor/kb_text_shape-win32.lib' = 'vendor/kb_text_shape-win32.lib'
    'modules/forbear/module.jai' = 'forbear.jai'
}
foreach ($file in $files.GetEnumerator()) {
    $out = Join-Path $dir $file.Key
    New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
    Invoke-WebRequest "$base/$($file.Value)" -OutFile $out -UseBasicParsing
}
Write-Host "Run: cd $dir; jai main.jai +forbear"
}
