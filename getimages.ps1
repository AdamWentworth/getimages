<#
.SYNOPSIS
This script processes subdirectories within a specified parent directory by executing the 'extractimage' command,
creating required directories if they do not exist, and finally moving and organizing the output files.

.DESCRIPTION
The script takes one mandatory parameter, $parentDirectory, which represents the parent directory path.
It iterates through each subdirectory inside the specified $parentDirectory, processes it, and organizes the output.

.PARAMETER parentDirectory
The full path of the parent directory containing the subdirectories to be processed.
#>

param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]$parentDirectory
)

if (-not $parentDirectory) {
    Write-Error "Please provide a valid parentDirectory."
    return
}

if (-not (Test-Path -Path $parentDirectory -PathType Container)) {
    Write-Error "The provided parentDirectory does not exist."
    return
}

$subDirectories = Get-ChildItem -Path $parentDirectory -Directory
$scannerOutputsDirectory = "$parentDirectory\scanner_outputs"

if (-not (Test-Path -Path $scannerOutputsDirectory)) {
    New-Item -ItemType Directory -Path $scannerOutputsDirectory | Out-Null
    Write-Verbose "Created directory: $scannerOutputsDirectory"
}

foreach ($subDirectory in $subDirectories) {
    $subDirectoryName = $subDirectory.Name
    $suffix = $subDirectoryName -replace '.*_([0-9]+)$', '$1'
    Write-Verbose "Processing $subDirectoryName"

    & extractimage ($subDirectory.FullName + "\colors") ($subDirectory.FullName + "\raws") $scannerOutputsDirectory

    Get-ChildItem -Path $scannerOutputsDirectory -File | ForEach-Object {
        $file = $_
        $fileName = $file.Name

        if ($fileName -match 'cam_(\d+)_img_(\d+)\.png') {
            $camNumber = $matches[1]
            $imgNumber = $matches[2]
            $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
            $fileExtension = [System.IO.Path]::GetExtension($fileName)
            $fileName = "${fileBaseName}_$suffix$fileExtension"
            $camDirectory = "$scannerOutputsDirectory\cam_$camNumber"
            $imgDirectory = "$camDirectory\img_$imgNumber"
            if (-not (Test-Path -Path $camDirectory)) {
                New-Item -ItemType Directory -Path $camDirectory | Out-Null
            }
            if (-not (Test-Path -Path $imgDirectory)) {
                New-Item -ItemType Directory -Path $imgDirectory | Out-Null
            }
            $destinationFilePath = Join-Path -Path $imgDirectory -ChildPath $fileName
            Move-Item -Path $file.FullName -Destination $destinationFilePath
        }
    }
}

Write-Host "File organization into cam_# and img_# directories complete."
Write-Host "All outputs moved to: $scannerOutputsDirectory"
