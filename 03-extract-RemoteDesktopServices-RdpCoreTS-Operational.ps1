# 파일명: extract-RemoteDesktopServices-RdpCoreTS-Operational.ps1
<#
.SYNOPSIS
    Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.evtx 에서 RdpCoreTS 이벤트 추출

.DESCRIPTION
    - 기본 이벤트 ID: 131(클라이언트 연결 시도), 140(인증 실패)
    - -DBG 옵션: [DBG] 디버그 메시지 출력
    - -WARN 옵션: [WARN] 경고 메시지 출력
    - -o 옵션: 화면 출력 생략, 지정된 파일에 UTF8 BOM CSV 저장
    - -o 옵션이 없으면 Format-Table 로 화면 출력

.PARAMETER i
    분석할 EVTX 파일 경로 (필수, -EvtxFile 별칭)

.PARAMETER o
    결과를 저장할 CSV 파일 경로 (선택, -OutFile 별칭)

.PARAMETER DBG
    디버그 메시지 출력

.PARAMETER WARN
    경고 메시지 출력
#>

param(
    [Alias("i")]
    [Parameter(Position=0,Mandatory=$true)]
    [string]$EvtxFile,

    [Alias("o")]
    [Parameter(Position=1)]
    [string]$OutFile,

    [switch]$DBG,
    [switch]$WARN
)

try {
    if (-not (Test-Path $EvtxFile)) {
        throw "EVTX 파일을 찾을 수 없습니다: $EvtxFile"
    }
    if ($DBG) { Write-Host "[DBG] EVTX 파싱 시작: $EvtxFile" }

    # 추출할 이벤트 ID 정의
    $eventIds = 131,140
    if ($DBG) { Write-Host "[DBG] 조회할 이벤트 ID: $($eventIds -join ',')" }

    $events = Get-WinEvent -FilterHashtable @{ Path = $EvtxFile; Id = $eventIds } -ErrorAction Stop

    if ($events.Count -eq 0) {
        if ($WARN) { Write-Warning "[WARN] 지정된 이벤트(ID=$($eventIds -join ',')) 로그가 없습니다." }
        return
    }

    $records = foreach ($evt in $events) {
        if ($DBG) { Write-Host "[DBG] 처리 중: EventID=$($evt.Id), TimeCreated=$($evt.TimeCreated)" }

        $xml = [xml]$evt.ToXml()
        $time = $evt.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
        $id   = $evt.Id

        switch ($id) {
            131 { $ip = ($xml.Event.EventData.Data | Where-Object Name -eq 'ClientIP').'#text' }
            140 { $ip = ($xml.Event.EventData.Data | Where-Object Name -eq 'IPString').'#text' }
            Default { $ip = '' }
        }

        $msg = $evt.FormatDescription()

        [PSCustomObject]@{
            TimeCreated = $time
            EventID     = $id
            IPAddress   = $ip
            Message     = $msg
        }
    }

    if ($PSBoundParameters.ContainsKey('OutFile')) {
        if ($DBG) { Write-Host "[DBG] CSV 파일로 저장 (UTF8 BOM): $OutFile" }
        $records | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8BOM
        Write-Host "`n[+] 저장 완료: $OutFile (UTF-8 BOM)"
    }
    else {
        if ($DBG) { Write-Host "[DBG] 화면에 표 형식으로 출력합니다." }
        $records | Format-Table TimeCreated, EventID, IPAddress, Message -AutoSize
    }
}
catch {
    if ($WARN) { Write-Warning "[WARN] $_" }
    else        { Write-Error   $_ }
    exit 1
}
