# 파일명: extract-TerminalServices-RDPClient%4Operational.ps1
# 경로 예시: G:\Autopsy Projects\…\Export\winevt\extract-TerminalServices-RDPClient%4Operational.ps1

<#
.SYNOPSIS
    Microsoft-Windows-TerminalServices-RDPClient%4Operational.evtx에서 RDPClient 이벤트 추출

.DESCRIPTION
    - 기본 이벤트 ID: 1024(시도), 1102(IP 포함 연결 시작)
    - -DBG 옵션: [DBG] 디버그 메시지 출력
    - -WARN 옵션: [WARN] 경고 메시지 출력
    - -o 옵션이 있으면 화면에 출력하지 않고, 지정된 파일에 UTF8 BOM 형식으로 저장
    - -o 옵션이 없으면 화면에 표 형식으로 컬럼 너비를 자동 조정하여 출력

.PARAMETER i
    분석할 evtx 파일 경로 (필수)

.PARAMETER o
    저장할 CSV 파일 경로 (없으면 화면 출력)

.PARAMETER DBG
    디버그 메시지([DBG]) 출력

.PARAMETER WARN
    경고 메시지([WARN]) 출력

.EXAMPLE
    # 화면에 표 형식으로 출력
    .\extract-TerminalServices-RDPClient%4Operational.ps1 -i "Microsoft-Windows-TerminalServices-RDPClient%4Operational.evtx"

.EXAMPLE
    # 파일로 저장
    .\extract-TerminalServices-RDPClient%4Operational.ps1 -i "RDPClient.evtx" -o "out.csv" -DBG -WARN
#>

param(
    [Alias("i")][Parameter(Mandatory=$true, Position=0)]
    [string]$EvtxFile,

    [Alias("o")][Parameter(Mandatory=$false, Position=1)]
    [string]$OutFile,

    [switch]$DBG,
    [switch]$WARN
)

try {
    if (-not (Test-Path $EvtxFile)) {
        throw "EVTX 파일을 찾을 수 없습니다: $EvtxFile"
    }
    if ($DBG) { Write-Host "[DBG] EVTX 파싱 시작: $EvtxFile" }

    # RDPClient 운영 로그의 주요 이벤트 ID
    $eventIds = 1024,1102
    if ($DBG) { Write-Host "[DBG] 조회할 이벤트 ID: $($eventIds -join ',')" }

    $events = Get-WinEvent -FilterHashtable @{ Path = $EvtxFile; Id = $eventIds } -ErrorAction Stop

    if ($events.Count -eq 0) {
        if ($WARN) { Write-Warning "[WARN] 지정된 이벤트(ID=$($eventIds -join ',')) 로그가 없습니다." }
        return
    }

    $records = foreach ($evt in $events) {
        if ($DBG) { Write-Host "[DBG] 처리 중: EventID=$($evt.Id), TimeCreated=$($evt.TimeCreated)" }

        $xml = [xml]$evt.ToXml()

        # EventData 내 Data 노드에서 값 추출
        $user      = ($xml.Event.EventData.Data | Where-Object Name -eq 'UserName').'#text'
        $sessionID = ($xml.Event.EventData.Data | Where-Object Name -eq 'SessionID').'#text'
        $ipAddr    = ($xml.Event.EventData.Data | Where-Object Name -eq 'TargetName').'#text'
        $message   = $evt.FormatDescription()

        [pscustomobject]@{
            TimeCreated = $evt.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
            EventID     = $evt.Id
            User        = $user
            SessionID   = $sessionID
            IPAddress   = $ipAddr
            Message     = $message
        }
    }

    if ($PSBoundParameters.ContainsKey('OutFile')) {
        # -o 옵션이 있으면 화면 출력 없이 파일로만 저장
        if ($DBG) { Write-Host "[DBG] CSV 파일로 저장 (UTF8 BOM): $OutFile" }
        $records | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8BOM
        return
    }
    else {
        # -o 옵션이 없으면 화면에 표 형식으로 출력
        if ($DBG) { Write-Host "[DBG] 화면에 표 형식으로 출력합니다." }
        $records |
            Format-Table TimeCreated, EventID, User, SessionID, IPAddress, Message -AutoSize
    }
}
catch {
    if ($WARN) { Write-Warning "[WARN] $_" }
    else        { Write-Error   $_ }
    exit 1
}
