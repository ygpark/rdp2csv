# 파일명: extract-TerminalServices-RemoteConnectionManager-Operational.ps1
<#
.SYNOPSIS
    Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx 에서 사용자 인증 이벤트 추출

.DESCRIPTION
    - 기본 이벤트 ID: 1149 (User authentication succeeded)
    - -DBG 옵션: 디버그 로그([DBG]) 출력
    - -WARN 옵션: 경고 로그([WARN]) 출력
    - -o 옵션: 화면 출력 없이 지정된 CSV 파일로 저장 (UTF-8 BOM)
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

    $eventIds = 1149
    if ($DBG) { Write-Host "[DBG] 조회할 이벤트 ID: $eventIds" }

    $events = Get-WinEvent -FilterHashtable @{ Path = $EvtxFile; Id = $eventIds } -ErrorAction Stop

    if ($events.Count -eq 0) {
        if ($WARN) { Write-Warning "[WARN] 이벤트(ID=$eventIds) 로그가 없습니다." }
        return
    }

    $records = foreach ($evt in $events) {
        if ($DBG) { Write-Host "[DBG] 처리 중: EventID=$($evt.Id), Time=$($evt.TimeCreated)" }

        $xml = [xml]$evt.ToXml()
        $time = $evt.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
        $id   = $evt.Id

        # Param2=Domain, Param1=User, Param3=RemoteHost
        $domain = ($xml.Event.EventData.Data | Where-Object Name -eq 'Param2').'#text'
        $user   = ($xml.Event.EventData.Data | Where-Object Name -eq 'Param1').'#text'
        $username = if ($domain) { "$domain\$user" } else { $user }
        $ip = ($xml.Event.EventData.Data | Where-Object Name -eq 'Param3').'#text'

        $message = $evt.FormatDescription()

        [PSCustomObject]@{
            TimeCreated = $time
            EventID     = $id
            UserName    = $username
            IPAddress   = $ip
            Message     = $message
        }
    }

    if ($PSBoundParameters.ContainsKey('OutFile')) {
        if ($DBG) { Write-Host "[DBG] CSV 저장 (UTF-8 BOM): $OutFile" }
        $records | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8BOM
        Write-Host "`n[+] 저장 완료: $OutFile"
    }
    else {
        if ($DBG) { Write-Host "[DBG] 화면 출력 모드" }
        $records | Format-Table TimeCreated, EventID, UserName, IPAddress, Message -AutoSize
    }
}
catch {
    if ($WARN) { Write-Warning "[WARN] $_" }
    else        { Write-Error   $_ }
    exit 1
}
