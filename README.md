# Mephisto's Windows File Deduplication Script

## Overview

**Deduplicate.ps1** is a PowerShell utility for identifying and handling duplicate files based on their MD5 hash. It supports actions like deletion, logging, and copying originals to a destination directory (optionally preserving folder structure).

This tool is particularly helpful for cleaning up storage, auditing redundant data, and organizing large datasets.

---

## Features

- Scans directories recursively for duplicate files.
- Uses MD5 hash to ensure content-based deduplication.
- Supports multiple actions:
  - **D**: Delete duplicates
  - **L**: Log duplicates to `Dedup_Report.csv`
  - **C**: Copy originals to flat destination folder
  - **CD**: Copy originals to destination folder with original structure
- Skips empty files (`D41D8CD98F00B204E9800998ECF8427E`)
- Generates a detailed deduplication report

---

## Usage

```powershell
.\Deduplicate.ps1 <SOURCE_PATH> <ACTION> <DESTINATION_PATH>
```

- `<SOURCE_PATH>`: Root directory to scan
- `<ACTION>`: One of `D`, `L`, `C`, `CD`
- `<DESTINATION_PATH>`: Required for actions `C` and `CD`

### Examples

Delete all duplicates:
```powershell
.\Deduplicate.ps1 "C:\MyData" D
```

Log duplicates:
```powershell
.\Deduplicate.ps1 "C:\MyData" L
```

Copy unique files to flat folder:
```powershell
.\Deduplicate.ps1 "C:\MyData" C "C:\Cleaned"
```

Copy unique files with directory structure preserved:
```powershell
.\Deduplicate.ps1 "C:\MyData" CD "C:\CleanedStructured"
```

---

## Report Output

A file named `Dedup_Report.csv` is generated in the current working directory. It includes:

- Original File
- Duplicate File
- Size
- Hash
- Action Taken

---

## Output Messages

- Duplicate detection progress
- File operation results (deleted, copied, logged)
- Summary of total duplicate file size (in B, KB, MB, GB, or TB)

---

## Notes

- Empty files are excluded from processing.
- Files with the same name but different content will be treated as unique.
- For `C` or `CD`, destination folder will be created if it does not exist.
- On name conflict, numerical prefixes are added to avoid overwrites.

---

## Requirements

- PowerShell 5.1+
- NTFS file system recommended for file operations
