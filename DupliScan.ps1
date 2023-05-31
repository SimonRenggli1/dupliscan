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

$partitions = Get-Partition | Where-Object {$_.Size -gt 1000000000}
Write-Host ""
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
if ($number -eq 1)
{
    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green -NoNewline " Select partition "
    Write-Host -ForegroundColor Green -NoNewline "("
    Write-Host -ForegroundColor Cyan -NoNewline "1"
    Write-Host -ForegroundColor Green -NoNewline ")"
    $partitionSelected = Read-Host " "
} else {
    Write-Host -ForegroundColor Green -NoNewline "["
    Write-Host -ForegroundColor Cyan -NoNewline "+"
    Write-Host -ForegroundColor Green -NoNewline "]"
    Write-Host -ForegroundColor Green -NoNewline " Select partition "
    Write-Host -ForegroundColor Green -NoNewline "("
    Write-Host -ForegroundColor Cyan -NoNewline "1-$number"
    Write-Host -ForegroundColor Green -NoNewline ")"
    $partitionSelected = Read-Host " "
}

if ($partitionSelected -eq "")
{
    Write-Host ""
    Write-Host -ForegroundColor Red "[!] No input"
    Write-Host ""
    exit
}

if ($partitionSelected -lt 1 -or $partitionSelected -gt $number)
{
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
        } catch {
            Write-Host ""
            Write-Host -ForegroundColor Red "[!] Error accessing file: $_"
            Write-Host ""
        }
    }
} catch {
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
