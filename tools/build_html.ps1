# Build Html
# ----------
#
# Author: Henrik Nørfjand Stengaard
# Date:   2019-01-10
#
# A PowerShell script to build html from markdown and embeds github styling.
#
# Following software is required for running this script.
#
# PanDoc:
# https://github.com/jgm/pandoc/releases
# https://github.com/jgm/pandoc/releases/download/2.5/pandoc-2.5-windows-x86_64.msi
# 
# Note: Pandoc is installed in local appdata and might be caught to AntiVirus as malware

Param(
	[Parameter(Mandatory=$true)]
	[string]$markdownFile,
	[Parameter(Mandatory=$true)]
	[string]$htmlFile,
	[Parameter(Mandatory=$true)]
	[string]$title
)

# paths
$pandocFile = Join-Path $env:LOCALAPPDATA -ChildPath 'Pandoc\pandoc.exe'

# fail, if pandoc file doesn't exist
if (!(Test-Path -path $pandocFile))
{
	Write-Error "Error: Pandoc file '$pandocFile' doesn't exist!"
	exit 1
}

# pandoc
$pandocArgs = "-s --metadata pagetitle=""$title"" -f gfm --css=""github-pandoc.css"" -t html5 ""$markdownFile"" -o ""$htmlFile"""
$pandocProcess = Start-Process -FilePath $pandocFile -ArgumentList $pandocArgs -Wait -NoNewWindow -PassThru

# exit, if pandoc fails
if ($pandocProcess.ExitCode -ne 0)
{
	Write-Error "Failed to run '$pandocFile' with arguments '$pandocArgs'"
	exit 1
}

# read github pandoc css and html
$githubPandocFile = Resolve-Path 'github-pandoc.css'
$githubPandocCss = [System.IO.File]::ReadAllText($githubPandocFile)
$html = [System.IO.File]::ReadAllText($htmlFile)

# embed github pandoc css and remove stylesheet link
$html = $html -replace '</head>', "<style type=""text/css"">$githubPandocCss</style>`r`n</head>" -replace '<link\s+rel="stylesheet"\s+href="github-pandoc.css"\s*/>', ''
[System.IO.File]::WriteAllText($htmlFile, $html)