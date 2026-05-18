param (
    [switch]$Restore
)

$patchesRoot = Join-Path $PSScriptRoot "patches"
$sourceRoot = Join-Path $PSScriptRoot "target\v8\src"

function Restore-PatchedFile {
    param (
        [string]$SourcePath,
        [string]$SourcePathRelative,
        [string]$BackupPath
    )

    if (Test-Path $BackupPath) {
        Copy-Item -Path $BackupPath -Destination $SourcePath -Force
        Remove-Item -Path $BackupPath -Force
        Write-Host "Restored '$SourcePathRelative'."
    }
    else
    {
        Write-Warning "Backup file '$BackupPath' does not exist for source '$SourcePath'."
    }
}

function Out-PatchedFile {
    param (
        [string]$ModulePath,
        [string]$SourcePath,
        [string]$SourcePathRelative,
        [string]$BackupPath
    )

    if (Test-Path $BackupPath)
    {
        Write-Warning "Source file '$SourcePath' has already patched."
    }
    elseif (Test-Path $SourcePath)
    {
        Copy-Item -Path $SourcePath -Destination $BackupPath -Force

        Import-Module $ModulePath -Force
        $content = Get-Content $SourcePath -Raw
        $content = Patch $content
        Set-Content -Path $SourcePath -Value $content

        $diff = git -c core.safecrlf=false --no-pager `
            diff --no-index --ignore-all-space --ignore-blank-lines --color=always `
            "$BackupPath" "$SourcePath" 2>&1
        $diff -split "`n" | Select-Object -Skip 2
        Write-Host -ForegroundColor Yellow "Patched '$SourcePathRelative'."
        Write-Host
    }
    else
    {
        Write-Warning "Source file '$SourcePath' does not exist for patch '$ModulePath'."
    }
}

Get-ChildItem -Path $patchesRoot -Recurse -Filter "*.psm1" |
Where-Object { $_.DirectoryName -ne $patchesRoot } |
ForEach-Object {
    $modulePath = $_.FullName
    $sourcePathRelative = $_.FullName.Substring($patchesRoot.Length + 1)
    $sourcePathRelative = [System.IO.Path]::ChangeExtension($sourcePathRelative, $null)
    $sourcePathRelative = $sourcePathRelative.Substring(0, $sourcePathRelative.Length - 1)
    $sourcePath = Join-Path $sourceRoot $sourcePathRelative
    $backupPath = "$sourcePath.bak"

    if ($Restore)
    {
        Restore-PatchedFile -SourcePath $sourcePath `
            -SourcePathRelative $sourcePathRelative `
            -BackupPath $backupPath
    }
    else
    {
        Out-PatchedFile -ModulePath $modulePath `
            -SourcePath $sourcePath `
            -SourcePathRelative $sourcePathRelative `
            -BackupPath $backupPath
    }
}

exit 0
