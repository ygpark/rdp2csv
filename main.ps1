& .\01-extract-TerminalServices-LocalSessionManager-Operational.ps1 -i Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx -o Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.csv
& .\02-extract-TerminalServices-RDPClient-Operational.ps1 -i Microsoft-Windows-TerminalServices-RDPClient%4Operational.evtx -o Microsoft-Windows-TerminalServices-RDPClient%4Operational.csv
& .\03-extract-RemoteDesktopServices-RdpCoreTS-Operational.ps1 -i Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.evtx -o Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.csv
& .\04-extract-TerminalServices-RemoteConnectionManager-Operational.ps1 -i Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx -o Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.csv
& .\05-extract-Security.ps1 -i Security.evtx -o Security.csv
