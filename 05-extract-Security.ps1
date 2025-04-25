# 파일명: extract-Security-Operational.ps1
<#
.SYNOPSIS
    Security.evtx 에서 주요 보안 이벤트 추출

.DESCRIPTION
    - 이벤트 ID:
        4624 (로그온 성공),
        4625 (로그온 실패),
        4688 (프로세스 생성),
        7045 (서비스 설치),
        1102 (감사 로그 삭제)
    - -DBG 옵션: 디버그 메시지([DBG]) 출력
    - -WARN 옵션: 경고 메시지([WARN]) 출력
    - -o 옵션: 화면 출력 생략, 지정된 CSV 파일로 저장 (UTF-8 BOM)
    - -o 옵션 미지정 시 Format-Table 로 화면 출력

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
    if ($DBG) { Write-Host "[DBG] 파싱 시작: $EvtxFile" }

    # 분석할 이벤트 ID 목록
    $eventIds = 4624,4625,4688,7045,1102
    if ($DBG) { Write-Host "[DBG] 조회할 이벤트 ID: $($eventIds -join ',')" }

    # 로그 로드
    $events = Get-WinEvent -FilterHashtable @{ Path = $EvtxFile; Id = $eventIds } -ErrorAction Stop

    if ($events.Count -eq 0) {
        if ($WARN) { Write-Warning "[WARN] 지정된 이벤트 로그가 없습니다 (ID=$($eventIds -join ','))" }
        return
    }

    $records = foreach ($evt in $events) {
        if ($DBG) { Write-Host "[DBG] 처리 중: EventID=$($evt.Id), Time=$($evt.TimeCreated)" }

        $xml = [xml]$evt.ToXml()
        $time      = $evt.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
        $id        = $evt.Id
        $account   = ''
        $ip        = ''
        $process   = ''
        $service   = ''

        switch ($id) {
            4624 {
                $account = ($xml.Event.EventData.Data | Where-Object Name -eq 'TargetUserName').'#text'
                $ip      = ($xml.Event.EventData.Data | Where-Object Name -eq 'IpAddress').'#text'
            }
            4625 {
                $account = ($xml.Event.EventData.Data | Where-Object Name -eq 'TargetUserName').'#text'
                $ip      = ($xml.Event.EventData.Data | Where-Object Name -eq 'IpAddress').'#text'
            }
            4688 {
                $process = ($xml.Event.EventData.Data | Where-Object Name -eq 'NewProcessName').'#text'
            }
            7045 {
                $service = ($xml.Event.EventData.Data | Where-Object Name -eq 'ServiceName').'#text'
            }
            1102 {
                # 감사 로그 삭제 이벤트, 추가 필드 없음
            }
        }

        $message = $evt.FormatDescription()

        [PSCustomObject]@{
            TimeCreated = $time
            EventID     = $id
            AccountName = $account
            IPAddress   = $ip
            ProcessName = $process
            ServiceName = $service
            Message     = $message
        }
    }

    # 출력 또는 저장
    if ($PSBoundParameters.ContainsKey('OutFile')) {
        if ($DBG) { Write-Host "[DBG] CSV 저장 (UTF-8 BOM): $OutFile" }
        $records | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8BOM
        Write-Host "`n[+] 저장 완료: $OutFile (UTF-8 BOM)"
    }
    else {
        if ($DBG) { Write-Host "[DBG] 화면 출력 모드" }
        $records | Format-Table TimeCreated, EventID, AccountName, IPAddress, ProcessName, ServiceName, Message -AutoSize
    }
}
catch {
    if ($WARN) { Write-Warning "[WARN] $_" }
    else        { Write-Error   $_ }
    exit 1
}
