$Host.UI.RawUI.WindowTitle = "Windows Powershell " + $Host.Version;

if (-not (Test-Path -Path ".\DupliScan.log")) {
    New-Item -Path ".\DupliScan.log" -ItemType File -Force | Out-Null
}

Add-Content -Path ".\DupliScan.log" -Value "== DupliScan Log =="

Write-Host ""
Write-Host -ForegroundColor White "     ______"
Write-Host -ForegroundColor White -NoNewline "    | __   \	"
Write-Host -ForegroundColor Cyan -NoNewline "DupliScan " 
Write-Host -ForegroundColor DarkCyan "0.1.1"
Write-Host -ForegroundColor White -NoNewline "    | _ __  |	"
Write-Host -ForegroundColor DarkGreen "a duplicate file scanner by simonrenggli1"
Write-Host -ForegroundColor White -NoNewline "    | ____  |	"
Write-Host -ForegroundColor DarkGreen "maintained by simonrenggli1"
Write-Host -ForegroundColor White -NoNewline "    | __ _  |	"
Write-Host -ForegroundColor DarkMagenta "https://github.com/simonrenggli1/dupliscan"
Write-Host -ForegroundColor White "    |_______|"
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
    Write-Host ""
}

Write-Host -ForegroundColor Green "    Mode"
Write-Host -ForegroundColor Green "---------------------------------------------"
Write-Host -ForegroundColor Cyan -NoNewline "    1"
Write-Host -ForegroundColor Green -NoNewline "."
Write-Host -ForegroundColor Cyan " Scan partition"
Write-Host -ForegroundColor Cyan -NoNewline "    2"
Write-Host -ForegroundColor Green -NoNewline "." 
Write-Host -ForegroundColor Cyan " Scan custom directory"
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

    $number = 0
    $partitionInfo = @{}

    foreach ($partition in $partitions) {
        $size = "{0:N2} GB" -f ($partition.Size / 1GB)
        $partitionInfo[$number] = $partition.DriveLetter
        $number = $number + 1
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

    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green " Scanning partition..."
    Write-Host ""

    Add-Content -Path ".\DupliScan.log" -Value ""
    Add-Content -Path ".\DupliScan.log" -Value "Timestamp: [$(Get-Date)]"
    Add-Content -Path ".\DupliScan.log" -Value ""

    $driveLetter = $partitionInfo[$partitionSelected - 1]

    $path = $driveLetter + ":\"
    

    $fileInfo = @{}

    function CheckDuplicate($filePath, $fileName, $fileSize) {
        try {
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
        catch {
            Write-Host -ForegroundColor Red "[!] Error occurred while checking duplicate: $_"
        }
    }

    try {
        $files = Get-ChildItem -LiteralPath $path -File -Recurse

        foreach ($file in $files) {
            try {
                $filePath = $file.FullName
                $fileName = $file.Name
                $fileSize = $file.Length

                CheckDuplicate -filePath $filePath -fileName $fileName -fileSize $fileSize
            }
            catch {
                Write-Host -ForegroundColor Red "[!] Error occurred while processing file: $_"
            }
        }

        Add-Content -Path ".\DupliScan.log" -Value "----------------------------------"
        Add-Content -Path ".\DupliScan.log" -Value "Duplicate Files Found:"
        Add-Content -Path ".\DupliScan.log" -Value "----------------------------------"
        foreach ($key in $fileInfo.Keys) {
            try {
                $duplicatePaths = $fileInfo[$key]
                if ($duplicatePaths.Count -gt 1) {
                    Write-Host ""
                    Write-Host -ForegroundColor Yellow -NoNewline "["
                    Write-Host -ForegroundColor Cyan -NoNewline "+"
                    Write-Host -ForegroundColor Yellow -NoNewline "]"
                    Write-Host -ForegroundColor Yellow " Duplicate file: $key"

                    Add-Content -Path ".\DupliScan.log" -Value ""
                    Add-Content -Path ".\DupliScan.log" -Value "File: $key"
                    Add-Content -Path ".\DupliScan.log" -Value "Duplicates:"

                    foreach ($duplicatePath in $duplicatePaths) {
                        Write-Host -ForegroundColor Red "[!] $duplicatePath"
                        Add-Content -Path ".\DupliScan.log" -Value "    - $duplicatePath"
                    }
                }
            }
            catch {
                Write-Host -ForegroundColor Red "[!] Error occurred while processing duplicate: $_"
            }
        }
    }
    catch {
        Write-Host -ForegroundColor Red "[!] Error occurred while scanning partition: $_"
    }

    
    Write-Host ""
    Write-Host -ForegroundColor Green "[+] Done"
    Write-Host ""
    exit
}

if ($mode -eq 2) {
    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green -NoNewline " Enter custom directory "
    $path = Read-Host " "

    if ($path -eq "") {
        Write-Host ""
        Write-Host -ForegroundColor Red "[!] No input"
        Write-Host ""
        exit
    }

    if (-not (Test-Path $path)) {
        Write-Host ""
        Write-Host -ForegroundColor Red "[!] Path does not exist"
        Write-Host ""
        exit
    }

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

    Add-Content -Path ".\DupliScan.log" -Value ""
    Add-Content -Path ".\DupliScan.log" -Value "Timestamp: [$(Get-Date)]"
    Add-Content -Path ".\DupliScan.log" -Value ""
    Add-Content -Path ".\DupliScan.log" -Value "Directory: $path"
    Add-Content -Path ".\DupliScan.log" -Value ""

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

    $path = "\\?\" + $path
    $files = Get-ChildItem -LiteralPath $path -File -Recurse
    foreach ($file in $files) {
        $filePath = $file.FullName
        $fileName = $file.Name
        $fileSize = $file.Length

        CheckDuplicate -filePath $filePath -fileName $fileName -fileSize $fileSize
    }

    Add-Content -Path ".\DupliScan.log" -Value "----------------------------------"
    Add-Content -Path ".\DupliScan.log" -Value "Duplicate Files Found:"
    Add-Content -Path ".\DupliScan.log" -Value "----------------------------------"
    Add-Content -Path ".\DupliScan.log" -Value ""
    
    foreach ($key in $fileInfo.Keys) {
        $duplicatePaths = $fileInfo[$key]
        if ($duplicatePaths.Count -gt 1) {
            Write-Host ""
            Write-Host -ForegroundColor Yellow -NoNewline "["
            Write-Host -ForegroundColor Cyan -NoNewline "+"
            Write-Host -ForegroundColor Yellow -NoNewline "]"
            Write-Host -ForegroundColor Yellow " Duplicate file: $key"

            Add-Content -Path ".\DupliScan.log" -Value "File: $key"
            Add-Content -Path ".\DupliScan.log" -Value "Duplicates:"

            foreach ($duplicatePath in $duplicatePaths) {
                Write-Host -ForegroundColor Red "[!] $duplicatePath"
                Add-Content -Path ".\DupliScan.log" -Value "    - $duplicatePath"
            }
            Add-Content -Path ".\DupliScan.log" -Value ""
        }
    }
    
    Write-Host ""
    Write-Host -ForegroundColor Green "[+] Done"
    Write-Host ""

    Add-Content -Path ".\DupliScan.log" -Value "----------------------------------"
    Add-Content -Path ".\DupliScan.log" -Value "End of Duplicate Files Log"
    Add-Content -Path ".\DupliScan.log" -Value "----------------------------------"
    Add-Content -Path ".\DupliScan.log" -Value ""
    exit
}
