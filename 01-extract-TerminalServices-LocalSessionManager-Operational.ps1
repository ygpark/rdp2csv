param (
    [string]$i,
    [string]$o,
    [string]$e,
    [switch]$h
)

# 도움말 출력
if ($h -or !$i) {
    Write-Host @"
extract-rdp_events.ps1 - RDP 관련 이벤트 로그 추출 스크립트

사용법:
  .\extract-rdp_events.ps1 -i <evtx파일> [-o <csv파일>] [-e <EventID목록>] [-h]

옵션:
  -i <파일.evtx>       분석할 EVTX 파일 경로 (필수)
  -o <파일.csv>        결과를 저장할 CSV 파일 경로 (선택)
  -e <ID,ID,...>       필터링할 EventID 목록 (기본: 21,24,25,39,40)
  -h                   도움말 표시

예시:
  .\extract-rdp_events.ps1 -i "log.evtx"
  .\extract-rdp_events.ps1 -i "log.evtx" -o "output.csv"
  .\extract-rdp_events.ps1 -i "log.evtx" -e "24,25"
  .\extract-rdp_events.ps1 -i "log.evtx" -o "filtered.csv" -e "21,40"

추출되는 필드:
  TimeCreated, EventID, User, SessionID, IPAddress, Message
"@
    exit 0
}

# EventID 파싱
if ($e) {
    $eventIds = $e -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
    if (-not $eventIds) {
        Write-Error "올바른 EventID를 입력해주세요 (예: -e '21,24,25')"
        exit 1
    }
} else {
    $eventIds = 21, 24, 25, 39, 40
}

if (!(Test-Path $i)) {
    Write-Error "입력 파일이 존재하지 않습니다: $i"
    exit 1
}

try {
    $events = Get-WinEvent -FilterHashtable @{Path=$i; Id=$eventIds} -ErrorAction Stop
} catch {
    Write-Error "EVTX 로드 실패: $($_.Exception.Message)"
    exit 1
}

$results = @()

foreach ($event in $events) {
    $props = $event.Properties | ForEach-Object { $_.Value }
    $formattedTime = $event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")

    $result = [PSCustomObject]@{
        TimeCreated = $formattedTime
        EventID     = $event.Id
        User        = $props[0]
        SessionID   = $props[1]
        IPAddress   = $props[2]
        Message     = $event.Message.Split("`n")[0]
    }

    $results += $result
}

if ($o) {
    $utf8BomEncoding = New-Object System.Text.UTF8Encoding $true
    $csvContent = $results | ConvertTo-Csv -NoTypeInformation
    [System.IO.File]::WriteAllLines($o, $csvContent, $utf8BomEncoding)
    Write-Host "`n[+] 저장 완료: $o (UTF-8 BOM)"
} else {
    $results | Format-Table -AutoSize
}
