# Create Zip From Directory
# -------------------------
#
# Author: Henrik Nørfjand Stengaard
# Date:   2017-05-13
#
# A PowerShell script to create zip file from directory.
# It creates an entry for each directory and files that exists in input directory.


Param(
	[Parameter(Mandatory=$true)]
	[string]$inputDir,
	[Parameter(Mandatory=$true)]
	[string]$outputZipFile
)


Add-Type -Assembly System.IO.Compression
Add-Type -Assembly System.IO.Compression.FileSystem


# create zip from directory
function CreateZipFromDirectory($inputDir, $outputZipFile)
{
    # create zip archive
    $zipFileStream = New-Object System.IO.FileStream $outputZipFile, 'Create', 'Write', 'Write'
    $zipArchive = New-Object System.IO.Compression.ZipArchive $zipFileStream, 'Create'

	$earliestPermittedLastWriteDate = New-Object System.DateTime 1980, 1, 1, 0, 0, 0

	$items = @()
	$items += Get-ChildItem $inputDir -Recurse

	foreach($item in $items)
	{
		$entryName = $item.FullName.Substring($inputDir.Length + 1) -replace '\\', '/'

		# add tailing slash to entry name, if item is a directory
		if ($item.PSIsContainer)
		{
			$entryName += '/'
		}

		$zipArchiveEntry = $zipArchive.CreateEntry($entryName)

		# set last write time to earliest permitted last write date, if last write date is earlier then 1980 January 1
		if ($item.LastWriteTime -lt $earliestPermittedLastWriteDate)
		{
			$zipArchiveEntry.LastWriteTime = $earliestPermittedLastWriteDate
		}
		else
		{
			$zipArchiveEntry.LastWriteTime = $item.LastWriteTime
		}

		# add item content to zip archive entry, if item is a file
		if (!$item.PSIsContainer)
		{
			# open entry stream and item file stream
			$entryStream = $zipArchiveEntry.Open()
			$itemFileStream = New-Object System.IO.FileStream $item.FullName, 'Open', 'Read'

			[byte[]]$buffer = new-object byte[] 4096

			# copy item file stream to entry stream
			do
			{
				$result = $itemFileStream.Read($buffer, 0, $buffer.Count)
				$entryStream.Write($buffer, 0, $result)
			} while ($result -eq $buffer.Count)

			# close and dispose zip archive and zip file stream
			$itemFileStream.Close()
			$itemFileStream.Dispose()
			$entryStream.Close()
		}
	}

	# close and dispose zip archive and zip file stream
    $zipArchive.Dispose()
	$zipFileStream.Close()
	$zipFileStream.Dispose()
}

# create zip from directory
CreateZipFromDirectory $inputDir $outputZipFile