# .evtx 파일 경로
$filePath = "Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx"  # 실제 파일 경로로 변경 필요

# CSV 파일 경로
$csvFilePath = "$filePath.csv" # 원하는 CSV 파일 경로 및 이름으로 변경

# Get-WinEvent cmdlet을 사용하여 모든 이벤트 가져오기
try {
    $events = Get-WinEvent -Path $filePath -ErrorAction Stop
    $events = Get-WinEvent -FilterHashtable @{Path = $filePath; Id = 24, 25 } -ErrorAction Stop
}
catch {
    Write-Error "Error reading events from '$filePath': $($_.Exception.Message)"
    exit
}

# 필요한 정보만 선택하여 CSV로 저장
$events | Select-Object TimeCreated, Id, Message, @{Name = "User"; Expression = { $_.Properties[0].Value } }, @{Name = "SessionID"; Expression = { $_.Properties[1].Value } }, @{Name = "SourceNetworkAddress"; Expression = { $_.Properties[2].Value } } | Export-CSV -Path $csvFilePath -NoTypeInformation -Encoding UTF8

Write-Host "이벤트 정보가 '$csvFilePath'에 저장되었습니다."