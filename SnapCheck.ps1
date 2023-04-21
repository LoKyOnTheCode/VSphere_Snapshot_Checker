param([string]$Server,
        [string]$User,
        [string]$Pass,
        [string]$Warning,
        [string]$Critical)

$ConfirmPreference = 'None'
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
$CHECKED_USER = ""
if ($User -eq 'root'){
        $CHECKED_USER = "(Attention avec root !)"
}

write-host "
  _________                          .__            __    _________ .__                   __
 /   _____/ ____ _____  ______  _____|  |__   _____/  |_  \_   ___ \|  |__   ____   ____ |  | __ ___________
 \_____  \ /    \\__  \ \____ \/  ___/  |  \ /  _ \   __\ /    \  \/|  |  \_/ __ \_/ ___\|  |/ // __ \_  __ \
 /        \   |  \/ __ \|  |_> >___ \|   Y  (  <_> )  |   \     \___|   Y  \  ___/\  \___|    <\  ___/|  | \/
/_______  /___|  (____  /   __/____  >___|  /\____/|__|    \______  /___|  /\___  >\___  >__|_ \\___  >__|
        \/     \/     \/|__|       \/     \/                      \/     \/     \/     \/     \/    \/


IP : $Server
User : $User $CHECKED_USER
Warning Threshold : $Warning days
Critical Threshold : $Critical days

"

##Variables
$list_OK = @()
$list_WARNING = @()
$list_CRITICAL = @()
$list_ALL = @()

if (!$Server -or !$User -or !$Pass -or !$Warning -or !$Critical) {
        Write-host "
Usage: script.ps1 -Server <ip_serveur> -User <user> -Pass <password> -Warning <seuil warning> -Critical <seuil critique>
" -foregroundcolor Yellow
        exit 3
}

try {
        connect-viserver -server $Server -user $User -password $Pass -ErrorAction Stop
}

catch {
        $exitCode = 3
        write-error "An error occured during connection process. Please check User/Password or IP.
Exiting with code : $exitCode"
        exit $exitCode
}


try {
        $ok = Get-VM | Get-Snapshot | Select-Object vm, name, created | Sort-Object -Property created -Descending | Where {($_.created -ge (Get-Date).AddDays(-$Warning))}
        $list_ALL += $ok
        $list_OK += $ok

        $warni = Get-VM | Get-Snapshot | Select-Object vm, name, created | Sort-Object -Property created -Descending | Where {($_.created -le (Get-Date).AddDays(-$Warning)) -and ($_.created -ge (Get-Date).AddDays(-$Critical))}
        $list_ALL += $warni
        $list_WARNING += $warni


        $criti =  Get-VM | Get-Snapshot | Select-Object vm, name, created | Sort-Object -Property created -Descending | Where {($_.created -lt (Get-Date).AddDays(-$Critical))}
        $list_ALL += $criti
        $list_CRITICAL += $criti




        write-host "
Résumé :
"

        write-host "OK : " $list_OK.count -foregroundcolor green
        foreach ($vm in $ok){
                $dateCreated = $vm.created
                $dateDiff = (Get-Date) - $dateCreated
        }
        $list_OK | Select-Object vm, @{Name="Days"; Expression={((Get-Date)-$_.created).Days}} | Format-Table -AutoSize


        write-host "WARNING : " $list_WARNING.count -foregroundcolor darkyellow
        foreach ($vm in $warni){
                $dateCreated = $vm.created
                $dateDiff = (Get-Date) - $dateCreated
        }
        $list_WARNING | Select-Object vm, @{Name="Days"; Expression={((Get-Date)-$_.created).Days}} | Format-Table -AutoSize

        write-host "CRITICAL : " $list_CRITICAL.count -foregroundcolor red
        foreach ($vm in $criti){
                $dateCreated = $vm.created
                $dateDiff = (Get-Date) - $dateCreated
        }
        $list_CRITICAL | Select-Object vm, @{Name="Days"; Expression={((Get-Date)-$_.created).Days}} | Format-Table -AutoSize

        write-host "############
TOTAL :  " $list_ALL.count
        write-host "############"


###### Retourne les codes d'exit ######

        if ($list_ALL -eq 0){
                write-host "Aucun SnapShot n'a été trouvé !" -Foregroundcolor red
                $exitCode = 0
        }
        if ($list_OK.count -gt 0){
                $exitCode = 0
        }
        if ($list_WARNING.count -gt 0){
                $exitCode = 1
        }
        if ($list_CRITICAL.count -gt 0){
                $exitCode = 2
        }
}


finally{
        disconnect-viserver $Server
        exit $exitCode
}
