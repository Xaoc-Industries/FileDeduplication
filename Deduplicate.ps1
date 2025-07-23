function Deduplicate{
	param([string]$FilePath, [string]$Action, [string]$NewDir)
	$FileTable = @()
	$HashTable = @{}
	$TotalDuplicateSize = 0
	Get-ChildItem $FilePath -Recurse -Force | Sort-Object -Property FullName -Descending | ForEach-Object {
		if ($Action -eq "CD"){
			$StrDir = [string]$_.Directory
			if ($StrDir){
				$FullSource = (Resolve-Path $FilePath).path
				$SubDirs = $StrDir.replace($FullSource,"")
				if (!(Test-PAth -Path $NewDir$SubDirs)){
					$FullPath = "$NewDir$SubDirs"
					$DirectoryArray = $FullPath.split("\")
					$DirectoryBuffer = ""
					$DirectoryArray | ForEach-Object {
						$DirectoryBuffer += "$_\"
						if (!(Test-Path $DirectoryBuffer)){
							New-Item $DirectoryBuffer -ItemType Directory | Out-Null
							Write-Host "Created $DirectoryBuffer"
						}
						else{
							Write-Host "$DirectoryBuffer Exists"
						}
					}
				}
			}
		}
		$CurrentFile = $_.FullName
		$CurrentLength = $_.Length
		$CurrentHash = Get-FileHash $_.FullName -Algorithm MD5 | Select Hash
		$CurrentHashValue = $CurrentHash.Hash
		if ($CurrentHash.Hash){
			if ($CurrentHashValue -ne "D41D8CD98F00B204E9800998ECF8427E"){
				$FilePair = "$CurrentHashValue|$CurrentFile|$CurrentLength"
				$FileTable += "$FilePair"
					Write-Host "Processed File $_"
			}
		}
		else{
		}
	}
	foreach ($HashName in $FileTable){
		$I=1
		$Hash = $HashName.Split("|")[-0]
		$File = $HashName.Split("|")[-2]
		$Size = $HashName.Split("|")[-1]
		if ($HashTable.ContainsKey($Hash)){
			$WriteHash = $HashTable[$Hash]
			$TotalDuplicateSize += $Size
			if ($Action -eq "D"){
				Remove-Item -Path $File -Force -ErrorAction Stop
				Write-Host "$File Deleted."
				Add-Content Dedup_Report.csv "`"$WriteHash`",`"$File`",$Size,$Hash,Deleted"
			}
			elseif ($Action -eq "L"){
				Write-Host "$File Duplicate Logged."
				Add-Content Dedup_Report.csv "`"$WriteHash`",`"$File`",$Size,$Hash,Logged"	
			}
			elseif ($Action -eq "C"){
				Write-Host "$File Duplicate Not Copied."
				Add-Content Dedup_Report.csv "`"$WriteHash`",`"$File`",$Size,$Hash,Not Copied"
			}
			elseif ($Action -eq "CD"){
				Write-Host "$File Duplicate Not Copied."
				Add-Content Dedup_Report.csv "`"$WriteHash`",`"$File`",$Size,$Hash,Not Copied"
			}
			else{
				Write-Host "ERROR: Invalid Action."
			}
		}
		else{
			Write-Host "$File Original File Discovered."
			$HashTable[$Hash] = $File
			$FileDestinationName = Split-Path $File -leaf
			$FileDestinationPath = "$NewDir\$FileDestinationName"
			if ($Action -eq "C"){
				if (Test-Path -Path $FileDestinationPath -PathType Leaf){
					$NewFileDestinationName = "$NewDir\$I-$FileDestinationName"
					while (Test-Path -Path $NewFileDestinationName -PathType Leaf){
						$I++
						$NewFileDestinationName = "$NewDir\$I-$FileDestinationName"
					}
					Copy-Item $File -Destination $NewFileDestinationName
				}
				else{
					Copy-Item $File -Destination $NewDir
				}
			}
			elseif ($Action -eq "CD"){
				$DSTFileName = $File.Replace($FullSource,"")
				Copy-Item $File -Destination $NewDir$DSTFileName
				Write-Host "Copied $File to $NewDir$DSTFileName"
			}
		}
	}
	if ($TotalDuplicateSize -lt 1024){
		Write-Host "*******************************************************"
		Write-Host "Total duplicate size: $TotalDuplicateSize Bytes"
		Write-Host "*******************************************************"
	}
	elseif ($TotalDuplicateSize -lt 1048576){
		$TotalDuplicateSize = [math]::Round($TotalDuplicateSize/1024)
		Write-Host "*******************************************************"
		Write-Host "Total duplicate size: $TotalDuplicateSize KiloBytes"
		Write-Host "*******************************************************"
	}
	elseif ($TotalDuplicateSize -lt 1073741824){
		$TotalDuplicateSize = [math]::Round($TotalDuplicateSize/1048576)
		Write-Host "*******************************************************"
		Write-Host " Total duplicate size: $TotalDuplicateSize MegaBytes"
		Write-Host "*******************************************************"
	}
	elseif ($TotalDuplicateSize -lt 137438953472){
		$TotalDuplicateSize = [math]::Round($TotalDuplicateSize/1073741824)
		Write-Host "*******************************************************"
		Write-Host " Total duplicate size: $TotalDuplicateSize GigaBytes"
		Write-Host "*******************************************************"
	}
	else{
		$TotalDuplicateSize = [math]::Round($TotalDuplicateSize/137438953472)
		Write-Host "*************************************************"
		Write-Host " Total duplicate size: $TotalDuplicateSize TeraBytes"
		Write-Host "*************************************************"
	}
	if ($Action -eq "CD"){
		$EmptyDirs = gci $NewDir -directory -recurse | Where { (gci $_.fullName).count -eq 0 } | select -expandproperty FullName; $EmptyDirs | Foreach-Object { Remove-Item $_ -Recurse}		
	}
}
function HELP{
	Write-Host "USAGE:"
	Write-Host "./THISPROGRAM FILE_PATH ACTION *DESTINATION_DIRECTORY*"
	Write-Host "-----------------------------------------------------------------------------------"
	Write-Host "|--                                  ACTIONS                                    --|"
	Write-Host "|---------------------------------------------------------------------------------|"
	Write-Host "|                                                                                 |"
	Write-Host "| Copy Originals to *DESTINATION_DIRECTORY*.....................................C |"
	Write-Host "| Copy Originals to *DESTINATION_DIRECTORY* with Directory Structure...........CD |"
	Write-Host "| Delete doubles................................................................D |"
	Write-Host "| Log doubles...................................................................L |"
	Write-Host "|                                                                                 |"
	Write-Host "-----------------------------------------------------------------------------------"
}
$UserInput_FilePath=$args[0]
$UserInput_Action=$args[1]
$UserInput_NewDir=$args[2]
Remove-Item Dedup_Report.csv -ErrorAction SilentlyContinue
if ($UserInput_FilePath){
	if ($UserInput_Action){
		if (Test-Path -Path $UserInput_FilePath) {
			if ($UserInput_Action -eq "D"){
				Add-Content Dedup_Report.csv 'Original File,Duplicate File,Size,File Hash,Action'
				Deduplicate $UserInput_FilePath $UserInput_Action
			}
			elseif ($UserInput_Action -eq "L"){
				Add-Content Dedup_Report.csv 'Original File,Duplicate File,Size,File Hash,Action'
				Deduplicate $UserInput_FilePath $UserInput_Action
			}
			elseif ($UserInput_Action -eq "C"){
				if ($UserInput_NewDir){
					if (Test-Path -Path $UserInput_NewDir) {
						Add-Content Dedup_Report.csv 'Original File,Duplicate File,Size,File Hash,Action'
						Deduplicate $UserInput_FilePath $UserInput_Action $UserInput_NewDir
					}
					else{
						New-Item "$UserInput_NewDir" -ItemType Directory | Out-Null
						Add-Content Dedup_Report.csv 'Original File,Duplicate File,Size,File Hash,Action'
						Deduplicate $UserInput_FilePath $UserInput_Action $UserInput_NewDir
					}
				}
				else{
					Write-Host "No destination folder specified."
				}
			}
			elseif ($UserInput_Action -eq "CD"){
				if ($UserInput_NewDir){
					if (Test-Path -Path $UserInput_NewDir) {
						Add-Content Dedup_Report.csv 'Original File,Duplicate File,Size,File Hash,Action'
						Deduplicate $UserInput_FilePath $UserInput_Action $UserInput_NewDir
					}
					else{
						New-Item "$UserInput_NewDir" -ItemType Directory | Out-Null
						Add-Content Dedup_Report.csv 'Original File,Duplicate File,Size,File Hash,Action'
						Deduplicate $UserInput_FilePath $UserInput_Action $UserInput_NewDir
					}
				}
				else{
					Write-Host "No destination folder specified."
				}
			}
			else{
				HELP
			}
		}
		else {
			Write-Host "Specified path does not exist."
		}
	}
	else{
		HELP
	}
}
else{
	HELP
}
