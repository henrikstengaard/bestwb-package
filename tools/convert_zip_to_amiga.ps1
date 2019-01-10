# Convert Zip To Amiga
# --------------------
#
# Author: Henrik Nørfjand Stengaard
# Date:   2018-02-20
#
# A PowerShell script to convert a zip file to Amiga.
#
# This is done by changing only zip file entries version made by to 279 (Amiga) and 
# external file attributes with protection bits for amiga file system.
# Protection bits are set to '----RWED' using external file attributes, 
# which is 135200784 for directories and 68091904 for files.
#
# The converted zip file now appears as if it was created on an Amiga and
# can successfully be extracted with system files.
#
# For unzip to work properly on Amiga, the zip file must contain directory 
# entries for all directories and not just empty directories to be compatible.
#
# Use either 7-Zip, WinRar, Windows build-in zip compression or create_zip_from_directory.ps1
# script to create a compatible zip file.
#
# http://www.java2s.com/Code/CSharp/File-Stream/Thisclassreadsandwriteszipfiles.htm
# https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html


Param(
	[Parameter(Mandatory=$true)]
	[string]$zipFile,
	[Parameter(Mandatory=$true)]
	[string]$outputZipFile
)


# header signatures
$localFileHeaderSignature = 0x04034b50
$centralDirectoryFileHeaderSignature = 0x02014b50
$endCentralDirectoryFileHeaderSignature = 0x06054b50

# Protection bits are flags that files, links and directories have in the filesystem. To change them one can either use the command Protect, or use the Information entry from the Icons menu in Workbench on selected files. AmigaDOS supports the following set of protection bits (abbreviated as HSPARWED):

# H = Hold (reentrant commands with the P-bit set will automatically become resident on first execution. Requires E, P and R bits set to work. Does not mean "Hide". See below.)
# S = Script (Batch file. Requires E and R bits set to work.) If this protection bit is set on, then AmigaDOS is able to recognize and automatically run a script by simply invoking its name. Without S bit scripts can still be launched using the Execute command.
# P = Pure (indicates reentrant commands that can be made resident in RAM and then no longer need to be loaded any time from flash drives, hard disks or any other media device. Requires E and R bits set to work.)
# A = Archive (Archived bit, used by various backup programs to indicate that a file has been backed up)
# R = Read (Permission to read the file, link or content of directory)
# W = Write (Permission to write the file, link or inside a directory)
# E = Execute (Permission to execute the file or enter the directory. All commands need this bit set, or they won't run. Requires R bit set to work.)
# D = Delete (Permission to delete the file, link or directory)

# # add file attribute enum type
# Add-Type -TypeDefinition @"
# [System.Flags]
# public enum FileAttributeEnum
# {
# 	Read = 1,
# 	Write = 2
# }
# "@

# read local file entry from binary reader
function ReadLocalFileEntry($binaryReader)
{
	$version = $binaryReader.ReadUInt16()
	$flags = $binaryReader.ReadUInt16()
	$method = $binaryReader.ReadUInt16()
	$fileModificationTime = $binaryReader.ReadUInt16()
	$fileModificationDate = $binaryReader.ReadUInt16()
	$crc32 = $binaryReader.ReadUInt32()
	$compressedSize = $binaryReader.ReadUInt32()
	$uncompressedSize = $binaryReader.ReadUInt32()
	$fileNameLength = $binaryReader.ReadUInt16()
	$extraFieldLength = $binaryReader.ReadUInt16()
	$fileNameBytes = $binaryReader.ReadBytes($fileNameLength)
	$extraFieldBytes = $binaryReader.ReadBytes($extraFieldLength)

	return New-Object PSObject -Property @{
		'Version' = $version;
		'Flags' = $flags;
		'Method' = $method;
		'FileModificationTime' = $fileModificationTime;
		'FileModificationDate' = $fileModificationDate;
		'Crc32' = $crc32;
		'CompressedSize' = $compressedSize;
		'UncompressedSize' = $uncompressedSize;
		'FileNameBytes' = $fileNameBytes;
		'ExtraFieldBytes' = $extraFieldBytes
	}
}

# write local file entry to binary writer
function WriteLocalFileEntry($binaryWriter, $localFileEntry)
{
	$binaryWriter.Write([UInt32]$localFileHeaderSignature)
	$binaryWriter.Write([UInt16]$localFileEntry.Version)
	$binaryWriter.Write([UInt16]$localFileEntry.Flags)
	$binaryWriter.Write([UInt16]$localFileEntry.Method)
	$binaryWriter.Write([UInt16]$localFileEntry.FileModificationTime)
	$binaryWriter.Write([UInt16]$localFileEntry.FileModificationDate)
	$binaryWriter.Write([UInt32]$localFileEntry.Crc32)
	$binaryWriter.Write([UInt32]$localFileEntry.CompressedSize)
	$binaryWriter.Write([UInt32]$localFileEntry.UncompressedSize)
	$binaryWriter.Write([UInt16]$localFileEntry.FileNameBytes.Count)
	$binaryWriter.Write([UInt16]$localFileEntry.ExtraFieldBytes.Count)

	if ($localFileEntry.FileNameBytes.Count -gt 0)
	{
		$binaryWriter.Write($localFileEntry.FileNameBytes)
	}

	if ($localFileEntry.ExtraFieldBytes.Count -gt 0)
	{
		$binaryWriter.Write($localFileEntry.ExtraFieldBytes)
	}
}

# copy bytes from binary reader to binary writer
function CopyBytes($binaryReader, $binaryWriter, $count)
{
	[byte[]]$buffer = new-object byte[] 4096
	$offset = 0
	do{
		if ($offset + $buffer.Count -gt $count)
		{
			$length = $count - $offset
		}
		else
		{
			$length = $buffer.Count
		}
		$result = $binaryReader.BaseStream.Read($buffer, 0, $length)
		$binaryWriter.BaseStream.Write($buffer, 0, $result)
		$offset += $result
	} while($result -eq $length -and $offset -lt $count)
}

# read central directory file entry from binary reader
function ReadCentralDirectoryFileEntry($binaryReader)
{
	$versionMadeBy = $binaryReader.ReadUInt16()
	$version = $binaryReader.ReadUInt16()
	$flags = $binaryReader.ReadUInt16()
	$method = $binaryReader.ReadUInt16()
	$fileModificationTime = $binaryReader.ReadUInt16()
	$fileModificationDate = $binaryReader.ReadUInt16()
	$crc32 = $binaryReader.ReadUInt32()
	$compressedSize = $binaryReader.ReadUInt32()
	$uncompressedSize = $binaryReader.ReadUInt32()
	$fileNameLength = $binaryReader.ReadUInt16()
	$extraFieldLength = $binaryReader.ReadUInt16()
	$fileCommentLength = $binaryReader.ReadUInt16()
	$diskNumber = $binaryReader.ReadUInt16()
	$internalFileAttributes = $binaryReader.ReadUInt16()
	$externalFileAttributes = $binaryReader.ReadUInt32()
	$dataOffset = $binaryReader.ReadUInt32()
	$fileNameBytes = $binaryReader.ReadBytes($fileNameLength)
	$extraFieldBytes = $binaryReader.ReadBytes($extraFieldLength)
	$fileCommentBytes = $binaryReader.ReadBytes($fileCommentLength)

	return New-Object PSObject -Property @{
		'VersionMadeBy' = $versionMadeBy;
		'Version' = $version;
		'Flags' = $flags;
		'Method' = $method;
		'FileModificationTime' = $fileModificationTime;
		'FileModificationDate' = $fileModificationDate;
		'Crc32' = $crc32;
		'CompressedSize' = $compressedSize;
		'UncompressedSize' = $uncompressedSize;
		'FileNameBytes' = $fileNameBytes;
		'ExtraFieldBytes' = $extraFieldBytes;
		'FileCommentBytes' = $fileCommentBytes;
		'DiskNumber' = $diskNumber;
		'InternalFileAttributes' = $internalFileAttributes;
		'ExternalFileAttributes' = $externalFileAttributes;
		'DataOffset' = $dataOffset
	}
}

# write central directory file entry
function WriteCentralDirectoryFileEntry($binaryWriter, $centralDirectoryFileEntry)
{
	$binaryWriter.Write([UInt32]$centralDirectoryFileHeaderSignature)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.VersionMadeBy)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.Version)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.Flags)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.Method)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.FileModificationTime)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.FileModificationDate)
	$binaryWriter.Write([UInt32]$centralDirectoryFileEntry.Crc32)
	$binaryWriter.Write([UInt32]$centralDirectoryFileEntry.CompressedSize)
	$binaryWriter.Write([UInt32]$centralDirectoryFileEntry.UncompressedSize)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.FileNameBytes.Count)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.ExtraFieldBytes.Count)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.FileCommentBytes.Count)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.DiskNumber)
	$binaryWriter.Write([UInt16]$centralDirectoryFileEntry.InternalFileAttributes)
	$binaryWriter.Write([UInt32]$centralDirectoryFileEntry.ExternalFileAttributes)
	$binaryWriter.Write([UInt32]$centralDirectoryFileEntry.DataOffset)

	if ($centralDirectoryFileEntry.FileNameBytes.Count -gt 0)
	{
		$binaryWriter.Write($centralDirectoryFileEntry.FileNameBytes)
	}

	if ($centralDirectoryFileEntry.ExtraFieldBytes.Count -gt 0)
	{
		$binaryWriter.Write($centralDirectoryFileEntry.ExtraFieldBytes)
	}

	if ($centralDirectoryFileEntry.FileCommentBytes.Count -gt 0)
	{
		$binaryWriter.Write($centralDirectoryFileEntry.FileCommentBytes)
	}
}

# read central directory end entry from binary reader
function ReadCentralDirectoryEndEntry($binaryReader)
{
	$diskNumber = $binaryReader.ReadUInt16()
	$diskCentralStart = $binaryReader.ReadUInt16()
	$numberOfCentralsStored = $binaryReader.ReadUInt16()
	$totalNumberOfCentralDirectories = $binaryReader.ReadUInt16()
	$sizeOfCentralDirectory = $binaryReader.ReadUInt32()
	$offsetCentralDirectoryStart = $binaryReader.ReadUInt32()
	$commentLength = $binaryReader.ReadUInt16()
	$commentBytes = $binaryReader.ReadBytes($commentLength)

	return New-Object PSObject -Property @{
		'DiskNumber' = $diskNumber;
		'DiskCentralStart' = $diskCentralStart;
		'NumberOfCentralsStored' = $numberOfCentralsStored;
		'TotalNumberOfCentralDirectories' = $totalNumberOfCentralDirectories;
		'SizeOfCentralDirectory' = $sizeOfCentralDirectory;
		'OffsetCentralDirectoryStart' = $offsetCentralDirectoryStart;
		'CommentBytes' = $commentBytes;
	}
}

# write central directory end entry to binary writer
function WriteCentralDirectoryEndEntry($binaryWriter, $centralDirectoryEndEntry)
{
	$binaryWriter.Write([UInt32]$endCentralDirectoryFileHeaderSignature)
	$binaryWriter.Write([UInt16]$centralDirectoryEndEntry.DiskNumber)
	$binaryWriter.Write([UInt16]$centralDirectoryEndEntry.DiskCentralStart)
	$binaryWriter.Write([UInt16]$centralDirectoryEndEntry.NumberOfCentralsStored)
	$binaryWriter.Write([UInt16]$centralDirectoryEndEntry.TotalNumberOfCentralDirectories)
	$binaryWriter.Write([UInt32]$centralDirectoryEndEntry.SizeOfCentralDirectory)
	$binaryWriter.Write([UInt32]$centralDirectoryEndEntry.OffsetCentralDirectoryStart)
	$binaryWriter.Write([UInt16]$centralDirectoryEndEntry.CommentBytes.Count)

	if ($centralDirectoryEndEntry.CommentBytes.Count -gt 0)
	{
		$binaryWriter.Write($centralDirectoryEndEntry.CommentBytes)
	}
}

# convert zip to amiga
function ConvertZipToAmiga($zipFile, $outputZipFile)
{
    $zipFileStream = New-Object System.IO.FileStream $zipFile, 'Open', 'Read', 'Read'
    $zipFileBinaryReader = New-Object System.IO.BinaryReader($zipFileStream)

    $outputZipFileStream = New-Object System.IO.FileStream $outputZipFile, 'Create', 'Write', 'Write'
    $outputZipFileBinaryWriter = New-Object System.IO.BinaryWriter($outputZipFileStream)

	$invalidSignature = $false
	$encoding = [system.Text.Encoding]::UTF8

	do
	{
		$signature = $zipFileBinaryReader.ReadInt32()

		if ($signature -eq $localFileHeaderSignature)
		{
			$localFileEntry = ReadLocalFileEntry $zipFileBinaryReader

			WriteLocalFileEntry $outputZipFileBinaryWriter $localFileEntry

			if ($localFileEntry.CompressedSize -gt 0)
			{
				CopyBytes $zipFileBinaryReader $outputZipFileBinaryWriter $localFileEntry.CompressedSize
			}
		}
		elseif ($signature -eq $centralDirectoryFileHeaderSignature)
		{
			$centralDirectoryFileEntry = ReadCentralDirectoryFileEntry $zipFileBinaryReader

			$fileName = $encoding.GetString($centralDirectoryFileEntry.FileNameBytes)

			# External File Attribute, Hex Value, Example files:
			# 136249360, 81F0010, 'Utilities/'
			# 135200784, 80F0010, 'WBStartup/'
			# 76480512, 48F0000, 'Programs/Configuration/guigfx_render_fpu/guigfx.library' (hidden), 'Programs/ProTracker/ProTracker-3.15.info', 'Programs/Visage/Catalogs/+e�tina/visage.catalog'
			# 70189056, 42F0000, 'Programs/DPaintIV/Dpaint','Programs/DirOpus4/c/Date'
			# 68091904, 40F0000, 'WBStartup/AtLast', 'Storage/DOSDrivers/BootRamDrive', 'MyFiles/LargeHD/128GB_Support/SCSI_v43_45_ChrisToni/A4000TSCSI.scsi.device.43.45'
			# 67960832, 40D0000, 'Devs/Printers.info'

			# Devs/Monitors/ = 135200784 = --------

			# 136249360 = directory?
			# 135200784 = directory?
			# 76480512 = H---RWED
			# 70189056 = --P-RWED
			# 68091904 = ----RWED
			# 67960832 = ----RW-D

			$centralDirectoryFileEntry.VersionMadeBy = 279

			if ($fileName -match '/$')
			{
				$centralDirectoryFileEntry.ExternalFileAttributes = 135200784
			}
			else
			{
				$centralDirectoryFileEntry.ExternalFileAttributes = 68091904
			}

			WriteCentralDirectoryFileEntry $outputZipFileBinaryWriter $centralDirectoryFileEntry
		}
		elseif ($signature -eq $endCentralDirectoryFileHeaderSignature)
		{
			$centralDirectoryEndEntry = ReadCentralDirectoryEndEntry $zipFileBinaryReader
			WriteCentralDirectoryEndEntry $outputZipFileBinaryWriter $centralDirectoryEndEntry
		}
		else
		{
			Write-Error ("Unknown signature '{0}' at position '{1}' in file '{2}'" -f $signature, $zipFileBinaryReader.BaseStream.Position - 4, $zipFile)
			$invalidSignature = $true
			break
		}
	}
	while ($signature -eq $localFileHeaderSignature -or $signature -eq $centralDirectoryFileHeaderSignature)

	# close and dispose binary reader and writer
	$outputZipFileBinaryWriter.Close()
	$outputZipFileBinaryWriter.Dispose()
	$zipFileBinaryReader.Close()
	$zipFileBinaryReader.Dispose()

	# close and dispose streams
	$outputZipFileStream.Close()
	$outputZipFileStream.Dispose()
	$zipFileStream.Close()
	$zipFileStream.Dispose()

	if ($invalidSignature)
	{
		exit 1
	}
}

ConvertZipToAmiga $zipFile $outputZipFile