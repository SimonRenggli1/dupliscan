$Host.UI.RawUI.WindowTitle = "Windows Powershell " + $Host.Version;

Write-Host ""
Write-Host -ForegroundColor White " ______"
Write-Host -ForegroundColor White -NoNewline "| __   \	"
Write-Host -ForegroundColor Cyan -NoNewline "DupliScan " 
Write-Host -ForegroundColor DarkCyan "0.1.1"
Write-Host -ForegroundColor White -NoNewline "| _ __  |	"
Write-Host -ForegroundColor DarkGreen "a duplicate file scanner by simonrenggli1"
Write-Host -ForegroundColor White -NoNewline "| ____  |	"
Write-Host -ForegroundColor DarkGreen "maintained by simonrenggli1"
Write-Host -ForegroundColor White -NoNewline "| __ _  |	"
Write-Host -ForegroundColor DarkMagenta "https://github.com/simonrenggli1/dupliscan"
Write-Host -ForegroundColor White "|_______|"
Write-Host ""

if ([System.Environment]::OSVersion.Version.Major -lt 6) {
    Write-Host -ForegroundColor Red "[!] Unsupported operating system"
    Write-Host ""
    exit
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host -ForegroundColor Yellow -NoNewline "["
    Write-Host -ForegroundColor Red -NoNewline "!"
    Write-Host -ForegroundColor Yellow -NoNewline "]"
    Write-Host -ForegroundColor Yellow -NoNewline " Warning: Recomended to run as"
    Write-Host -ForegroundColor Red " administrator"
}

Write-Host "    Mode"
Write-Host "---------------------------------------------"
Write-Host "    1. Scan partition"
Write-Host "    2. Scan custom directory"
Write-Host ""
Write-Host -ForegroundColor Green -NoNewline "["
Write-Host -ForegroundColor Cyan -NoNewline "+"
Write-Host -ForegroundColor Green -NoNewline "]"
Write-Host -ForegroundColor Green -NoNewline " Select partition "
Write-Host -ForegroundColor Green -NoNewline "("
Write-Host -ForegroundColor Cyan -NoNewline "1-2"
Write-Host -ForegroundColor Green -NoNewline ")"
$mode = Read-Host " "

if ($mode -eq "") {
    Write-Host ""
    Write-Host -ForegroundColor Red "[!] No input"
    Write-Host ""
    exit
}

if ($mode -lt 1 -or $mode -gt 2) {
    Write-Host ""
    Write-Host -ForegroundColor Red "[!] Out of range"
    Write-Host ""
    exit
}

if ($mode -eq 1) {
    Write-Host ""
    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green " Scanning partitions..."
    Write-Host ""

    $partitions = Get-Partition | Where-Object { $_.Size -gt 1000000000 }
    Write-Host ""
    Write-Host -ForegroundColor Green "    Drive    Size"
    Write-Host -ForegroundColor Green "---------------------------------------------"

    foreach ($partition in $partitions) {
        $size = "{0:N2} GB" -f ($partition.Size / 1GB)
        $number = $partition.DiskNumber + 1
        $partitionName = $partition.DriveLetter
        Write-Host -ForegroundColor Cyan -NoNewline "$number"
        Write-Host -ForegroundColor Green -NoNewline ".  "
        Write-Host -ForegroundColor Green -NoNewline "$partitionName        "
        Write-Host -ForegroundColor Cyan "$size"
    }

    Write-Host ""
    if ($number -eq 1) {
        Write-Host -ForegroundColor Green -NoNewline "["
        Write-Host -ForegroundColor Cyan -NoNewline "+"
        Write-Host -ForegroundColor Green -NoNewline "]"
        Write-Host -ForegroundColor Green -NoNewline " Select partition "
        Write-Host -ForegroundColor Green -NoNewline "("
        Write-Host -ForegroundColor Cyan -NoNewline "1"
        Write-Host -ForegroundColor Green -NoNewline ")"
        $partitionSelected = Read-Host " "
    }
    else {
        Write-Host -ForegroundColor Green -NoNewline "["
        Write-Host -ForegroundColor Cyan -NoNewline "+"
        Write-Host -ForegroundColor Green -NoNewline "]"
        Write-Host -ForegroundColor Green -NoNewline " Select partition "
        Write-Host -ForegroundColor Green -NoNewline "("
        Write-Host -ForegroundColor Cyan -NoNewline "1-$number"
        Write-Host -ForegroundColor Green -NoNewline ")"
        $partitionSelected = Read-Host " "
    }

    if ($partitionSelected -eq "") {
        Write-Host ""
        Write-Host -ForegroundColor Red "[!] No input"
        Write-Host ""
        exit
    }

    if ($partitionSelected -lt 1 -or $partitionSelected -gt $number) {
        Write-Host ""
        Write-Host -ForegroundColor Red "[!] Out of range"
        Write-Host ""
        exit
    }

    $partitionSelected = $partitionSelected - 1

    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green " Scanning partition..."
    Write-Host ""

    $driveLetter = $partitions[$partitionSelected].DriveLetter + ":"
    $files = try {
        [System.IO.Directory]::EnumerateFiles($driveLetter, "*", [System.IO.SearchOption]::AllDirectories) | ForEach-Object {
            try {
                $_ -replace "^$([regex]::Escape($driveLetter))", ''
            }
            catch {
                Write-Host ""
                Write-Host -ForegroundColor Red "[!] Error accessing file: $_"
                Write-Host ""
            }
        }
    }
    catch {
        Write-Host ""
        Write-Host -ForegroundColor Red "[!] Error accessing directory: $driveLetter"
        Write-Host ""
    }

    Write-Host ""
    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green -NoNewline " Found "
    Write-Host -ForegroundColor Cyan -NoNewline $files.Count
    Write-Host -ForegroundColor Green " files"
    Write-Host ""

    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green " Scanning for duplicates..."
    Write-Host ""

    $files | Group-Object -Property { $_ } | Where-Object { $_.Count -gt 1 } | ForEach-Object {
        Write-Host -ForegroundColor Red "[!] Duplicate file: $($_.Name)"
    }

    Write-Host ""
    Write-Host -ForegroundColor Green "[+] Done"
    Write-Host ""
}

if ($mode -eq 2) {
    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green -NoNewline " Enter custom directory "
    $path = Read-Host " "

    # Check if path is empty
    if ($path -eq "") {
        Write-Host ""
        Write-Host -ForegroundColor Red "[!] No input"
        Write-Host ""
        exit
    }

    # Check if path exists
    if (-not (Test-Path $path)) {
        Write-Host ""
        Write-Host -ForegroundColor Red "[!] Path does not exist"
        Write-Host ""
        exit
    }

    # Check if path is a directory
    if (-not (Test-Path $path -PathType Container)) {
        Write-Host ""
        Write-Host -ForegroundColor Red "[!] Path is not a directory"
        Write-Host ""
        exit
    }

    Write-Host ""
    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green " Scanning directory..."

    $fileInfo = @{}

    function CheckDuplicate($filePath, $fileName, $fileSize) {
        $key = "$fileName-$fileSize"
        if ($fileInfo.ContainsKey($key)) {
            $duplicatePaths = $fileInfo[$key]
            $duplicatePaths += $filePath
            $fileInfo[$key] = $duplicatePaths
        }
        else {
            $fileInfo[$key] = @($filePath)
        }
    }

    $files = Get-ChildItem -Path $path -File -Recurse
    foreach ($file in $files) {
        $filePath = $file.FullName
        $fileName = $file.Name
        $fileSize = $file.Length

        CheckDuplicate -filePath $filePath -fileName $fileName -fileSize $fileSize
    }

    foreach ($key in $fileInfo.Keys) {
        $duplicatePaths = $fileInfo[$key]
        if ($duplicatePaths.Count -gt 1) {
            Write-Host ""
            Write-Host -ForegroundColor Yellow -NoNewline "["
            Write-Host -ForegroundColor Cyan -NoNewline "+"
            Write-Host -ForegroundColor Yellow -NoNewline "]"
            Write-Host -ForegroundColor Yellow " Duplicate file: $key"

            foreach ($duplicatePath in $duplicatePaths) {
                Write-Host -ForegroundColor Red "[!] $duplicatePath"
            }
        }
    }
    
    Write-Host ""
    Write-Host -ForegroundColor Green "[+] Done"
    Write-Host ""
    exit
}
