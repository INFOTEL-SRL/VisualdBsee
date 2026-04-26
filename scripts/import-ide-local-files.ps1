param(
   [Parameter(Mandatory = $true, Position = 0)]
   [string]$VisualDbseeRoot
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceBin = Join-Path $VisualDbseeRoot "BIN"
$destBin = Join-Path $repoRoot "ide\BIN"

$filesToImport = @(
   "dbsee.ini",
   "dbseeusr.dbf",
   "VDBSEE.qos",
   "dbsee.bak"
)

if (-not (Test-Path -LiteralPath $sourceBin)) {
   throw "Cartella sorgente non trovata: $sourceBin"
}

if (-not (Test-Path -LiteralPath $destBin)) {
   throw "Cartella destinazione non trovata: $destBin"
}

Write-Host "Import file locali IDE"
Write-Host "Sorgente     : $sourceBin"
Write-Host "Destinazione : $destBin"

$copied = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]

foreach ($name in $filesToImport) {
   $sourceFile = Join-Path $sourceBin $name
   $destFile = Join-Path $destBin $name

   if (-not (Test-Path -LiteralPath $sourceFile)) {
      $missing.Add($name)
      continue
   }

   if (Test-Path -LiteralPath $destFile) {
      $backupFile = "$destFile.bak"
      Copy-Item -LiteralPath $destFile -Destination $backupFile -Force
      Write-Host "Backup creato : $backupFile"
   }

   Copy-Item -LiteralPath $sourceFile -Destination $destFile -Force
   $copied.Add($name)
   Write-Host "Copiato       : $name"
}

Write-Host ""
Write-Host "Riepilogo"

if ($copied.Count -gt 0) {
   Write-Host "File copiati  : $($copied -join ', ')"
} else {
   Write-Host "File copiati  : nessuno"
}

if ($missing.Count -gt 0) {
   Write-Host "File mancanti : $($missing -join ', ')"
}
