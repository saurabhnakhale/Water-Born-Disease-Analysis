# Script to sync live data directly from published Google Sheets
# Base Sheet URL: https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub

$ErrorActionPreference = "Stop"

$sheets = @{
    Linelist = "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=0&single=true&output=csv"
    WaterSample = "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=246840870&single=true&output=csv"
    HighRiskArea = "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=893083487&single=true&output=csv"
    Event = "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=1177415409&single=true&output=csv"
    Outbreak = "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub?gid=1614269266&single=true&output=csv"
}

Write-Host "Fetching Google Sheets CSV data..."
$tempDir = Join-Path $PSScriptRoot "temp_sync"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }

foreach ($k in $sheets.Keys) {
    $outFile = Join-Path $tempDir "$k.csv"
    curl.exe -s -L $sheets[$k] -o $outFile
    Write-Host "Downloaded $k.csv ($((Get-Item $outFile).Length) bytes)"
}

$zoneNames = @{
    "Zone 1" = "Laxmi Nagar"
    "Zone 2" = "Dharampeth"
    "Zone 3" = "Hanuman Nagar"
    "Zone 4" = "Dhantoli"
    "Zone 5" = "Nehru Nagar"
    "Zone 6" = "Gandhibagh"
    "Zone 7" = "Satranjipura"
    "Zone 8" = "Lakadganj"
    "Zone 9" = "Ashi Nagar"
    "Zone 10" = "Mangalwari"
}

function Standardize-Diagnosis($d) {
    if (-not $d) { return "Other / Non-specific" }
    $s = $d.ToString().Trim()
    if ($s -match 'Gastroentr|Gastronetritis') { return "Acute Gastroenteritis (AGE)" }
    if ($s -match 'Diarrho|Loose motion') { return "Acute Diarrhoeal Disease (ADD)" }
    if ($s -match 'Hepatit') { return "Hepatitis A" }
    if ($s -match 'Cholera') { return "Cholera" }
    if ($s -match 'Typhoid|Tyhoid|Enteric Fever') { return "Typhoid / Enteric Fever" }
    if ($s -match 'Dysentry') { return "Dysentery" }
    return "Other / Non-specific"
}

function Standardize-Zone($z) {
    if (-not $z) { return "Unknown" }
    $s = $z.ToString().Trim()
    if ($s -match 'Zone\s*(\d+)') { return "Zone " + $Matches[1] }
    if ($s -match 'Rural') { return "Rural / Non-NMC" }
    if ($s -match 'Other') { return "Other Districts/States" }
    return $s
}

function Parse-CustomDate($str) {
    if (-not $str) { return $null }
    $s = $str.Trim()
    $dt = [DateTime]::MinValue
    $formats = @(
        "M/d/yyyy", "MM/dd/yyyy", "d/M/yyyy", "dd/MM/yyyy",
        "yyyy-MM-dd", "d/MM/yyyy", "dd/M/yyyy"
    )
    if ([DateTime]::TryParseExact($s, $formats, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dt)) {
        return $dt
    }
    if ([DateTime]::TryParse($s, [ref]$dt)) {
        return $dt
    }
    return $null
}

function Format-MonthKey($dt, $rawMonth) {
    if ($dt) { return $dt.ToString("yyyy-MM") }
    $s = $rawMonth.ToString().Trim().ToLower()
    if ($s -match 'jul.*25') { return "2025-07" }
    if ($s -match 'aug.*25') { return "2025-08" }
    if ($s -match 'sep.*25') { return "2025-09" }
    if ($s -match 'oct.*25') { return "2025-10" }
    if ($s -match 'nov.*25') { return "2025-11" }
    if ($s -match 'dec.*25') { return "2025-12" }
    if ($s -match 'jan.*26') { return "2026-01" }
    if ($s -match 'feb.*26') { return "2026-02" }
    if ($s -match 'mar.*26') { return "2026-03" }
    if ($s -match 'apr.*26') { return "2026-04" }
    if ($s -match 'may.*26') { return "2026-05" }
    if ($s -match 'jun.*26') { return "2026-06" }
    if ($s -match 'jul.*26') { return "2026-07" }
    if ($s -match 'aug.*26') { return "2026-08" }
    if ($s -match 'sep.*26') { return "2026-09" }
    return $rawMonth
}

function Format-MonthLabel($mKey) {
    $map = @{
        "2025-07" = "Jul 2025"
        "2025-08" = "Aug 2025"
        "2025-09" = "Sep 2025"
        "2025-10" = "Oct 2025"
        "2025-11" = "Nov 2025"
        "2025-12" = "Dec 2025"
        "2026-01" = "Jan 2026"
        "2026-02" = "Feb 2026"
        "2026-03" = "Mar 2026"
        "2026-04" = "Apr 2026"
        "2026-05" = "May 2026"
        "2026-06" = "Jun 2026"
        "2026-07" = "Jul 2026"
        "2026-08" = "Aug 2026"
        "2026-09" = "Sep 2026"
    }
    if ($map.ContainsKey($mKey)) { return $map[$mKey] }
    return $mKey
}

# 1. Parse Linelist
Write-Host "Processing Linelist..."
$linelistRaw = Import-Csv (Join-Path $tempDir "Linelist.csv")
$linelist = @()

foreach ($r in $linelistRaw) {
    $srNo = $r.'Sr No'
    $name = $r.'Name of Patient'
    if (-not $srNo -and -not $name) { continue }

    $admDt = Parse-CustomDate $r.'Date of Admission'
    $mKey = Format-MonthKey $admDt $r.'Month'
    $mLabel = Format-MonthLabel $mKey

    $z = Standardize-Zone $r.'Zone'
    $zName = if ($zoneNames.ContainsKey($z)) { $zoneNames[$z] } else { $z }
    $diagCat = Standardize-Diagnosis $r.'Diagnosis'

    $ageVal = $null
    $ageInt = 0
    if ([int]::TryParse($r.'Age', [ref]$ageInt)) { $ageVal = $ageInt }

    $gender = if ($r.'M/F') { $r.'M/F'.Trim().ToUpper() } else { "U" }
    if ($gender -ne "M" -and $gender -ne "F") { $gender = "Other" }

    $linelist += [PSCustomObject]@{
        id = $srNo
        monthKey = $mKey
        month = $mLabel
        admissionDate = if ($admDt) { $admDt.ToString("yyyy-MM-dd") } else { "" }
        zone = $z
        zoneName = $zName
        name = if ($name) { $name.Trim() } else { "Unknown" }
        age = $ageVal
        gender = $gender
        mobile = if ($r.'Mob No') { $r.'Mob No'.Trim() } else { "" }
        address = if ($r.'Address') { $r.'Address'.Trim() } else { "" }
        rawDiagnosis = if ($r.'Diagnosis') { $r.'Diagnosis'.Trim() } else { "" }
        diagnosisCategory = $diagCat
        hospital = if ($r.'Hospital') { $r.'Hospital'.Trim() } else { "Isolation Hospital" }
    }
}
Write-Host "Processed $($linelist.Count) linelist records."

# 2. Parse High Risk Areas
Write-Host "Processing High Risk Areas..."
$hraRaw = Import-Csv (Join-Path $tempDir "HighRiskArea.csv")
$hra = @()
$currZ = ""
$currZN = ""
$hraIdx = 1

foreach ($r in $hraRaw) {
    $zoneVal = $r.'Zone'
    $zoneNameVal = $r.'Zone Name'
    if ($zoneVal -and $zoneVal.Trim() -ne "") { $currZ = Standardize-Zone $zoneVal }
    if ($zoneNameVal -and $zoneNameVal.Trim() -ne "") { $currZN = $zoneNameVal.Trim() }
    if (-not $currZN -and $zoneNames.ContainsKey($currZ)) { $currZN = $zoneNames[$currZ] }

    $area = if ($r.'Area') { $r.'Area'.Trim() } else { "" }
    $prabhag = if ($r.'Prabhag') { $r.'Prabhag'.Trim() } else { "" }
    $latlong = if ($r.'Latitude and Longitude') { $r.'Latitude and Longitude'.Trim() } else { "" }

    if (-not $area -and -not $latlong) { continue }

    $lat = $null
    $lng = $null
    if ($latlong -match '([0-9\.\-]+)\s*,\s*([0-9\.\-]+)') {
        $lat = [double]$Matches[1]
        $lng = [double]$Matches[2]
    }

    $hra += [PSCustomObject]@{
        id = $hraIdx
        zone = $currZ
        zoneName = $currZN
        area = $area
        prabhag = $prabhag
        lat = $lat
        lng = $lng
        latlong = $latlong
        type = "High Risk Area (HRA)"
    }
    $hraIdx++
}
Write-Host "Processed $($hra.Count) High Risk Areas."

# 3. Parse Events
Write-Host "Processing Events..."
$eventLines = Get-Content (Join-Path $tempDir "Event.csv")
# Remove possible title header line before CSV header
$eventHeaderIdx = 0
for ($i=0; $i -lt $eventLines.Count; $i++) {
    if ($eventLines[$i] -match '^Sr No,') { $eventHeaderIdx = $i; break }
}
$eventCsvText = ($eventLines[$eventHeaderIdx..($eventLines.Count-1)]) -join "`r`n"
$eventsRaw = ConvertFrom-Csv $eventCsvText

$events = @()
foreach ($r in $eventsRaw) {
    $srNo = $r.'Sr No'
    if (-not $srNo -or $srNo.Trim() -eq "") { continue }

    $rawM = $r.'Month'
    $mKey = Format-MonthKey $null $rawM
    $mLabel = Format-MonthLabel $mKey

    $z = Standardize-Zone $r.'Zone No'
    $zName = if ($r.'Zone Name') { $r.'Zone Name'.Trim() } else { $zoneNames[$z] }
    $latlong = if ($r.'Map/Location') { $r.'Map/Location'.Trim() } else { "" }
    $lat = $null
    $lng = $null
    if ($latlong -match '([0-9\.\-]+)\s*,\s*([0-9\.\-]+)') {
        $lat = [double]$Matches[1]
        $lng = [double]$Matches[2]
    }

    $events += [PSCustomObject]@{
        id = $srNo.Trim()
        monthKey = $mKey
        month = $mLabel
        zone = $z
        zoneName = $zName
        prabhag = if ($r.'Prabhag') { $r.'Prabhag'.Trim() } else { "" }
        area = if ($r.'Area') { $r.'Area'.Trim() } else { "" }
        disease = if ($r.'Disease') { $r.'Disease'.Trim() } else { "Water-borne Event" }
        lat = $lat
        lng = $lng
        latlong = $latlong
        type = "Water-borne Event"
    }
}
Write-Host "Processed $($events.Count) events."

# 4. Parse Outbreaks
Write-Host "Processing Outbreaks..."
$outbreakLines = Get-Content (Join-Path $tempDir "Outbreak.csv")
$outbreakHeaderIdx = 0
for ($i=0; $i -lt $outbreakLines.Count; $i++) {
    if ($outbreakLines[$i] -match '^Sr No,') { $outbreakHeaderIdx = $i; break }
}
$outbreakCsvText = ($outbreakLines[$outbreakHeaderIdx..($outbreakLines.Count-1)]) -join "`r`n"
$outbreaksRaw = ConvertFrom-Csv $outbreakCsvText

$outbreaks = @()
foreach ($r in $outbreaksRaw) {
    $srNo = $r.'Sr No'
    if (-not $srNo -or $srNo.Trim() -eq "") { continue }

    $rawM = $r.'Month'
    $mKey = Format-MonthKey $null $rawM
    $mLabel = Format-MonthLabel $mKey

    $z = Standardize-Zone $r.'Zone No'
    $zName = if ($r.'Zone Name') { $r.'Zone Name'.Trim() } else { $zoneNames[$z] }
    $latlong = if ($r.'Map/Location') { $r.'Map/Location'.Trim() } else { "" }
    $lat = $null
    $lng = $null
    if ($latlong -match '([0-9\.\-]+)\s*,\s*([0-9\.\-]+)') {
        $lat = [double]$Matches[1]
        $lng = [double]$Matches[2]
    }

    $outbreaks += [PSCustomObject]@{
        id = $srNo.Trim()
        monthKey = $mKey
        month = $mLabel
        zone = $z
        zoneName = $zName
        area = if ($r.'Area') { $r.'Area'.Trim() } else { "" }
        disease = if ($r.'Disease') { $r.'Disease'.Trim() } else { "Water-borne Outbreak" }
        lat = $lat
        lng = $lng
        latlong = $latlong
        type = "Water-borne Outbreak"
    }
}
Write-Host "Processed $($outbreaks.Count) outbreaks."

# 5. Parse Water Sample Stats from WaterSample.csv
Write-Host "Processing Water Sample Data..."
$waterLines = Get-Content (Join-Path $tempDir "WaterSample.csv")

# Find monthly statistics row
$statsHeaderIdx = -1
for ($i=0; $i -lt $waterLines.Count; $i++) {
    if ($waterLines[$i] -match 'Water sample Statistics') {
        $statsHeaderIdx = $i + 1
        break
    }
}

$waterMonthly = @()
if ($statsHeaderIdx -gt 0 -and $statsHeaderIdx + 3 -lt $waterLines.Count) {
    $monthCols = $waterLines[$statsHeaderIdx] -split ','
    $sentCols = $waterLines[$statsHeaderIdx + 1] -split ','
    $notPotCols = $waterLines[$statsHeaderIdx + 2] -split ','
    $potCols = $waterLines[$statsHeaderIdx + 3] -split ','

    for ($c=1; $c -lt $monthCols.Count; $c++) {
        $mName = $monthCols[$c].Trim()
        if (-not $mName) { continue }

        $sent = [int]($sentCols[$c].Trim() -replace '\D','')
        $notPot = [int]($notPotCols[$c].Trim() -replace '\D','')
        $pot = [int]($potCols[$c].Trim() -replace '\D','')

        $mKey = Format-MonthKey $null $mName
        $mLabel = Format-MonthLabel $mKey

        $rate = if ($sent -gt 0) { [Math]::Round(($notPot / $sent) * 100, 1) } else { 0.0 }

        $waterMonthly += [PSCustomObject]@{
            monthKey = $mKey
            month = $mLabel
            sent = $sent
            potable = $pot
            notPotable = $notPot
            contaminationRate = $rate
        }
    }
}
Write-Host "Processed $($waterMonthly.Count) water monthly stats."

# 6. Parse Zonewise Water Samples
Write-Host "Processing Zonewise Water Sample Data..."
$wsZonewise = @()
$currMonthKey = ""

for ($i=6; $i -lt $waterLines.Count; $i++) {
    $line = $waterLines[$i]
    $cols = $line -split ','
    if ($cols.Count -lt 1) { continue }
    $col0 = $cols[0].Trim()
    
    if ($col0 -match '^(Aug|Sep|Oct|Nov|Dec|Jan|Feb|Mar|Apr|May|Jun|Jul)-[0-9]{2}') {
        $currMonthKey = Format-MonthKey $null $col0
        continue
    }

    if ($col0 -match '^Zone\s*(\d+)') {
        $z = Standardize-Zone $col0
        $zn = if ($cols.Count -gt 1 -and $cols[1].Trim() -ne "") { $cols[1].Trim() } else { $zoneNames[$z] }
        $sentVal = if ($cols.Count -gt 2 -and $cols[2].Trim() -match '^\d+') { [int]$cols[2].Trim() } else { 0 }
        $potVal = if ($cols.Count -gt 3 -and $cols[3].Trim() -match '^\d+') { [int]$cols[3].Trim() } else { 0 }
        $notPotVal = if ($cols.Count -gt 4 -and $cols[4].Trim() -match '^\d+') { [int]$cols[4].Trim() } else { 0 }
        
        $rate = if ($sentVal -gt 0) { [Math]::Round(($notPotVal / $sentVal) * 100, 1) } else { 0.0 }

        $wsZonewise += [PSCustomObject]@{
            monthKey = $currMonthKey
            month = Format-MonthLabel $currMonthKey
            zone = $z
            zoneName = $zn
            sent = $sentVal
            potable = $potVal
            notPotable = $notPotVal
            contaminationRate = $rate
        }
    }
}
Write-Host "Processed $($wsZonewise.Count) zonewise water sample entries."

# Clean up temp folder
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Combine into master data object
$data = [PSCustomObject]@{
    metadata = [PSCustomObject]@{
        title = "NMC Water-Borne Disease & ADD Surveillance Intelligence Data"
        generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        source = "Google Sheets (Live Connected)"
        sheetUrl = "https://docs.google.com/spreadsheets/d/e/2PACX-1vQjC8StN7a2den66UIrHOhljHBeF8mASD_j6Fmu5C5xNEp2tWbkV_YDgTMzKujFjPni4u-T4GWj1Thn/pub"
        totalLinelist = $linelist.Count
        totalHighRiskAreas = $hra.Count
        totalEvents = $events.Count
        totalOutbreaks = $outbreaks.Count
        totalWaterSamples = ($waterMonthly | Measure-Object -Property sent -Sum).Sum
        totalNotPotableWater = ($waterMonthly | Measure-Object -Property notPotable -Sum).Sum
    }
    linelist = $linelist
    highRiskAreas = $hra
    events = $events
    outbreaks = $outbreaks
    waterSampleMonthly = $waterMonthly
    waterSampleZonewise = $wsZonewise
}

$jsonPath = Join-Path $PSScriptRoot "clean_data.json"
$data | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding UTF8
Write-Host "Updated $jsonPath successfully."

$jsPath = Join-Path $PSScriptRoot "data.js"
$jsContent = "window.SURVEILLANCE_DATA = " + ($data | ConvertTo-Json -Depth 6) + ";"
$jsContent | Set-Content -Path $jsPath -Encoding UTF8
Write-Host "Updated $jsPath successfully."
