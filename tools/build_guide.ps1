# Build Guide
# -----------
#
# Author: Henrik Nørfjand Stengaard
# Date:   2017-04-03
#
# A PowerShell script to build amiga guide from markdown.
#
# Following software is required for running this script.
#
# Image Magick:
# http://www.imagemagick.org/script/binary-releases.php
# http://www.imagemagick.org/download/binaries/ImageMagick-6.9.3-7-Q8-x64-dll.exe
#
# XnView with NConvert
# http://www.xnview.com/en/xnview/#downloads
# http://download3.xnview.com/XnView-win-full.exe


Param(
	[Parameter(Mandatory=$true)]
	[string]$markdownFile,
	[Parameter(Mandatory=$true)]
	[string]$guideFile
)


# calculate md5 hash
function CalculateMd5($text)
{
    $encoding = [system.Text.Encoding]::UTF8
	$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	return [System.BitConverter]::ToString($md5.ComputeHash($encoding.GetBytes($text))).ToLower().Replace('-', '')
}


# write text file encoded for Amiga
function WriteAmigaTextLines($path, $lines)
{
	$iso88591 = [System.Text.Encoding]::GetEncoding("ISO-8859-1");
	$utf8 = [System.Text.Encoding]::UTF8;

	$amigaTextBytes = [System.Text.Encoding]::Convert($utf8, $iso88591, $utf8.GetBytes($lines -join "`n"))
	[System.IO.File]::WriteAllText($path, $iso88591.GetString($amigaTextBytes), $iso88591)
}


# convert images
function ConvertImages($markdownFile, $outputDir)
{
    # read markdown lines
    $markdownLines = @()
    $markdownLines += Get-Content $markdownFile

    # get image references from markdown
    $imageReferences = @()
    $imageReferences += $markdownLines | ForEach-Object { $_ | Select-String -Pattern "!\[[^\[\]]+\]\(([^\(\)]+\.png)[^\)]+\)" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } }

    # image dir
    $imageDir = Split-Path $markdownFile -Parent

    # convert image references
    foreach($imageReference in $imageReferences)
    {
        $imageFile = Join-Path -Path $imageDir -ChildPath $imageReference

        # fail, if image file doesn't exist
        if (!(test-path $imageFile))
        {
            Write-Error ("Image file '" + $imageFile + "' doesn't exist!")
            exit 1
        }

        $imageFile = Resolve-Path $imageFile

        # image magick
	    $imageMagickConvertArgs = """$imageFile"" -resize 610x190! -filter Point -depth 8 -colors 255 ""$tempFile"""
        $imageMagickConvertProcess = Start-Process -FilePath $imageMagickFile -ArgumentList $imageMagickConvertArgs -Wait -NoNewWindow -PassThru
        if ($imageMagickConvertProcess.ExitCode -ne 0)
        {
            Write-Error "Failed to run '$imageMagickFile' with arguments '$imageMagickConvertArgs'"
            exit 1
        }

	    # image iff file
        $imageIffFile = (Join-Path -Path $outputDir -ChildPath $imageReference) -replace '\.[^\.]+$', '.iff'
        $imageIffFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($imageIffFile)
        $imageIffDir = Split-Path -Path $imageIffFile -Parent

        # create image iff directory, if it doesn't exist
        if (!(Test-Path -Path $imageIffDir))
        {
            mkdir $imageIffDir | Out-Null
        }

        # delete image iff file, if it already exist
        if (Test-Path $imageIffFile)
        {
            Remove-Item $imageIffFile -Force
        }

	    # nconvert
	    $nconvertArgs = "-out iff -c 1 -o ""$imageIffFile"" ""$tempFile"""
        $nconvertProcess = Start-Process -FilePath $xnViewNconvertFile -ArgumentList $nconvertArgs -Wait -NoNewWindow -PassThru
        if ($nconvertProcess.ExitCode -ne 0)
        {
            Write-Error "Failed to run '$xnViewNconvertFile' with arguments '$nconvertArgs'"
            exit 1
        }
    }
}


# build guide lines
function BuildGuideLines($markdownFile, $guideFileName)
{
    # read markdown lines
    $markdownLines = @()
    $markdownLines += Get-Content $markdownFile

    # get title and headers from markdown lines
    $title = $markdownLines | ForEach-Object { $_ | Select-String -Pattern "#\s+(.+)" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } } | Select-Object -First 1
    $headers = @()
    $headers += $markdownLines | ForEach-Object { $_ | Select-String -Pattern "^(#+)\s+(.+)" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { @{ "Id" = (CalculateMd5 $_.Groups[2].Value.Trim()); "Level" = $_.Groups[1].Value.Trim().Length; "Name" = $_.Groups[2].Value.Trim() } } }

    $headerNamesIndex = @{}
    $subHeaderIndex = @{}
    $headerIdPath = @()

    # build sub header index
    foreach ($header in $headers)
    {
        # add header to header names index
        $headerNamesIndex.Set_Item($header.Id, $header.Name)

        if ($header.Level -gt $headerIdPath.Count)
        {
            $headerIdPath += $header.Id
        }
        elseif ($header.Level -le $headerIdPath.Count)
        {
            if ($header.Level -lt $headerIdPath.Count)
            {
                $headerIdPath = $headerIdPath[0..($headerIdPath.Count - $header.Level)]
            }

            $headerIdPath[$headerIdPath.Count - 1] = $header.Id
        }

        if ($headerIdPath.Count -gt 1)
        {
            $headerParentId = $headerIdPath[$headerIdPath.Count - 2]

            if ($subHeaderIndex.ContainsKey($headerParentId))
            {
                $subHeaders = $subHeaderIndex.Get_Item($headerParentId)
            }
            else
            {
                $subHeaders = @()
            }

            $subHeaders += $header.Id
            $subHeaderIndex.Set_Item($headerParentId, $subHeaders)
        }
    }

    # build guide lines 
    $date = Get-Date -format "yyyy.MM.dd"
    $guideLines = @("@database ""$guideFileName""", "@`$VER: $guideFileName ($date)", "@wordwrap", "@title ""$title""", "")
    $guideLines += $markdownLines
    $guideLines += @("", "@endnode", "")

    # convert markdown syntax to guide syntax
    for($i = 0; $i -lt $guideLines.Count; $i++)
    {
        # code formatting
        if ($guideLines[$i] -match '^###$')
        {
            $guideLines[$i] = ''
        }

        # bold formatting
        if ($guideLines[$i] -match '\*\*')
        {
            $guideLines[$i] = $guideLines[$i] -replace "\*\*(.*)?\*\*", "@{b}`$1@{ub}"
        }

        # header formatting
        if ($guideLines[$i] -match '^[#]+\s+(.+)')
        {
            $headerName = $guideLines[$i] | Select-String -Pattern "^#+\s+(.+)" -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 1
            $headerId = CalculateMd5 $headerName

            if ($headerName -eq $title)
            {
                $guideLines[$i] = $guideLines[$i] -replace "^#+\s+(.+)", "@node Main ""`$1"""
            }
            else
            {
                $guideLines[$i] = $guideLines[$i] -replace "^#+\s+(.+)", "@endnode`n@node $headerId ""`$1"""
            }

            # add sub node index, if present
            if ($subNodeIndex)
            {
                $guideLines[$i] = "$subNodeIndex`n`n" + $guideLines[$i]
            }

            # build sub node index, if header name is equal to title or has sub headers
            if ($headerName -eq $title)
            {
                $subNodeIndex = ($headers | Where-Object { $_.Name -ne $title }| ForEach-Object { "{0}@{{""{1}"" link {2}}}" -f ((1..$_.Level | Where-Object { $_ -gt 2 } | ForEach-Object { "  " }) -Join ''), $_.Name, $_.Id }) -join "`n"
            }
            elseif ($subHeaderIndex.ContainsKey($headerId))
            {
                $subNodeIndex = ($subHeaderIndex[$headerId] | ForEach-Object { "@{{""{0}"" link {1}}}" -f $headerNamesIndex[$_], $_ }) -join "`n"
            }
            else 
            {
                $subNodeIndex = $null
            }
        }

        # convert image references
        if ($guideLines[$i] -match '!\[[^\[\]]+\]\([^\(\)]+\.png[^\)]+\)')
        {
            $guideLines[$i] = $guideLines[$i] -replace '!\[([^\[\]]+)\]\(([^\(\)]+)\.png[^\)]+\)', '@{"$1" SYSTEM "multiview $2.iff"}'
        }
    }

    return $guideLines
}

# get image magick directory from program files
$imageMagickDirectory = Get-ChildItem $env:ProgramFiles | Where-Object { $_.Name -match 'ImageMagick' } | Select-Object -First 1

# fail, if image magick directory doesn't exist
if (!$imageMagickDirectory)
{
	Write-Error "Error: Image Magick doesn't exist in program files '$env:ProgramFiles'!"
	exit 1
}

# image magick v7 file 
$imageMagickFile = Join-Path -Path $imageMagickDirectory.FullName -ChildPath 'magick.exe'

# check if image magick v6 file exist, if image magick v7 doesn't exist
if (!(Test-Path -path $imageMagickFile))
{
    $imageMagickFile = Join-Path -Path $imageMagickDirectory.FullName -ChildPath 'convert.exe'

    if (!(Test-Path -path $imageMagickFile))
    {
        Write-Error "Error: Image Magick 'magick.exe' or 'convert.exe' file doesn't exist!"
        exit 1
    }
}


# get xnview directory from program files x86
$xnViewDirectory = Get-ChildItem ${Env:ProgramFiles(x86)} | Where-Object { $_.Name -match 'XnView' } | Select-Object -First 1

# fail, if xnview directory doesn't exist
if (!$xnViewDirectory)
{
	Write-Error "Error: XnView doesn't exist in program files '${Env:ProgramFiles(x86)}'!"
	exit 1
}

# xnview nconvert file
$xnViewNconvertFile = Join-Path -Path $xnViewDirectory.FullName -ChildPath 'nconvert.exe'

# fail, if xnview nconvert file doesn't exist
if (!(Test-Path -path $xnViewNconvertFile))
{
	Write-Error "Error: XnView nconvert file '$xnViewNconvertFile' doesn't exist!"
	exit 1
}


# paths
$tempFile = [System.IO.Path]::Combine($env:TEMP, "build_guide_" + [System.IO.Path]::GetRandomFileName())
$guideDir = Split-Path $guideFile -Parent
$guideFileName = Split-Path $guideFile -Leaf


# convert images
ConvertImages $markdownFile $guideDir


# build guide lines from markdown file
$guideLines = BuildGuideLines $markdownFile $guideFileName


# write guide lines to guide file
WriteAmigaTextLines $guideFile $guideLines


# delete temp file, if it exists
if (test-path -path $tempFile)
{
    Remove-Item $tempFile -Force
}