param([Parameter(Mandatory=$true)][string]$ZipPath,[Parameter(Mandatory=$true)][string]$InstallRoot,[string]$Version='unknown',[int]$Port=8787)
$ErrorActionPreference='Stop'
$parent=Split-Path -Parent $InstallRoot
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup=Join-Path $parent ("LANCSMDT-backup-"+$stamp)
$stage=Join-Path $parent ("LANCSMDT-stage-"+$stamp)
$log=Join-Path $InstallRoot 'backend\data\update.log'
function Log($m){Add-Content -Path $log -Value ((Get-Date -Format o)+' '+$m)}
try {
  Log "Updater starting for $Version"; Start-Sleep -Seconds 3
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath,$stage)
  $dirs=Get-ChildItem $stage -Directory
  $source=if($dirs.Count -eq 1){$dirs[0].FullName}else{$stage}
  New-Item -ItemType Directory -Force -Path $backup | Out-Null
  foreach($item in Get-ChildItem $InstallRoot){if($item.Name -ne 'backend'){Copy-Item $item.FullName $backup -Recurse -Force}}
  New-Item -ItemType Directory -Force -Path (Join-Path $backup 'backend') | Out-Null
  foreach($item in Get-ChildItem (Join-Path $InstallRoot 'backend')){if($item.Name -ne 'data' -and $item.Name -ne '.env'){Copy-Item $item.FullName (Join-Path $backup 'backend') -Recurse -Force}}
  foreach($item in Get-ChildItem $source){if($item.Name -eq 'backend'){foreach($b in Get-ChildItem $item.FullName){if($b.Name -ne 'data' -and $b.Name -ne '.env'){Copy-Item $b.FullName (Join-Path $InstallRoot 'backend') -Recurse -Force}}}else{Copy-Item $item.FullName $InstallRoot -Recurse -Force}}
  Log "Files installed; backup at $backup"
  Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','START-HTTP-SERVER.bat' -WorkingDirectory $InstallRoot -WindowStyle Minimized
  Start-Sleep -Seconds 8
  try {$h=Invoke-WebRequest -UseBasicParsing -Uri ("http://127.0.0.1:"+$Port+"/api/health") -TimeoutSec 8;if($h.StatusCode -ne 200){throw 'health check failed'};Log 'Update successful'} catch {Log ('Health check failed, rollback starting: '+$_.Exception.Message);foreach($item in Get-ChildItem $backup){if($item.Name -eq 'backend'){foreach($b in Get-ChildItem $item.FullName){Copy-Item $b.FullName (Join-Path $InstallRoot 'backend') -Recurse -Force}}else{Copy-Item $item.FullName $InstallRoot -Recurse -Force}};Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','START-HTTP-SERVER.bat' -WorkingDirectory $InstallRoot -WindowStyle Minimized;Log 'Rollback completed'}
} catch {Log ('Updater fatal error: '+$_.Exception.Message);exit 1}
