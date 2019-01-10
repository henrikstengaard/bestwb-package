# Build Package
# -------------
#
# Author: Henrik Nørfjand Stengaard
# Date:   2019-10-01
#
# A PowerShell script to build package for HstWB Installer.


Add-Type -Assembly System.IO.Compression.FileSystem

# paths
$rootDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("..")
$packageDir = Join-Path -Path $rootDir -ChildPath "package"
$screenshotsDir = Join-Path -Path $rootDir -ChildPath "screenshots"
$readmeMarkdownFile = Join-Path -Path $rootDir -ChildPath "README.md"
$createZipFromDirectoryFile = Resolve-Path "create_zip_from_directory.ps1"
$convertZipToAmigaFile = Resolve-Path "convert_zip_to_amiga.ps1"

# get screenshot files
$screenshotFiles = @()

if (Test-Path $screenshotsDir)
{
	$screenshotFiles += Get-ChildItem -Path "$screenshotsDir\*" -Include *.png, *.jpg
}

# copy screenshot files, if any exist
if ($screenshotFiles.Count -gt 0)
{
	Write-Host "Copying screenshots for package..." -ForegroundColor "Yellow"
	$packageScreenshotsDir = Join-Path -Path $packageDir -ChildPath "screenshots"

	if (!(Test-Path $packageScreenshotsDir))
	{
		mkdir $packageScreenshotsDir | Out-Null
	}

	$screenshotFiles | ForEach-Object { Copy-Item -Path $_.FullName -Destination $packageScreenshotsDir -Force }
	Write-Host "Done." -ForegroundColor "Yellow"
}

# read package json file
$hstwbPackageJsonFile = [System.IO.Path]::Combine($packageDir, 'hstwb-package.json')
$hstwbPackage = Get-Content $hstwbPackageJsonFile -Raw | ConvertFrom-Json

# package name
$packageName = "{0} v{1}" -f $hstwbPackage.Name, $hstwbPackage.Version

# build html
Write-Host "Building readme html for package from readme markdown..." -ForegroundColor "Yellow"
& ".\build_html.ps1" -markdownFile $readmeMarkdownFile -htmlFile (Join-Path -Path $packageDir -ChildPath "README.html") -title $packageName
Write-Host "Done." -ForegroundColor "Yellow"

# build guide
Write-Host "Building readme guide for package from readme markdown..." -ForegroundColor "Yellow"
& ".\build_guide.ps1" -markdownFile $readmeMarkdownFile -guideFile (Join-Path -Path $packageDir -ChildPath "README.guide")
Write-Host "Done." -ForegroundColor "Yellow"

# write progress message
Write-Host ("Build package '{0}' v{1}" -f $hstwbPackage.Name, $hstwbPackage.Version) -ForegroundColor "Yellow"

# compress content directories to zip files
$contentDirs = Get-ChildItem -Path $rootDir | Where-Object { $_.PSIsContainer -and $_.Name -notmatch '(package|screenshots|tools|licenses)' }
foreach ($contentDir in $contentDirs)
{
	# write progress message
	Write-Host ("Compressing content '" + $contentDir.Name + "' zip file...")

	# temp file file
	$tempZipFile = Join-Path $packageDir -ChildPath "temp.zip"

	# compress content directory
	& $createZipFromDirectoryFile -inputDir $contentDir.FullName -outputZipFile $tempZipFile

	# content zip file
	$contentZipFile = Join-Path $packageDir -ChildPath ($contentDir.Name + ".zip")

	# delete content zip file, if it exists
	if (test-path -path $contentZipFile)
	{
		remove-item $contentZipFile -force
	}

	# convert zip to amiga
	& $convertZipToAmigaFile -zipFile $tempZipFile -outputZipFile $contentZipFile

	# delete temp zip file, if it exists
	if (test-path -path $tempZipFile)
	{
		remove-item $tempZipFile -force
	}
}

# write progress message
Write-Host "Compressing package zip file..." -ForegroundColor "Yellow"

# package file
$packageFile = Join-Path -Path $rootDir -ChildPath ("{0}.{1}.zip" -f ($hstwbPackage.Name -replace '\s', '.'), $hstwbPackage.Version)

# delete package file, if it exists
if (test-path -path $packageFile)
{
	remove-item $packageFile -force
}

# compress package directory
[System.IO.Compression.ZipFile]::CreateFromDirectory($packageDir, $packageFile, 'Optimal', $false)

# write progress message
Write-Host "Done." -ForegroundColor "Yellow"