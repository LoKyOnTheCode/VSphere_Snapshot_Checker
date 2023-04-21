# Snapshot Checker v1.0
Script qui permet de se connecter à un esxi distant et de vérifier les dates de création des snapshots.

# Usage :
.\snap_check.ps1 -Server <ip_serveur> -User  -Pass  -Warning  -Critical 

# Exemple d'output
.\script.ps1 -Server 192.168.51.1 -User root -Pass 'XXXXXXXX' -Warning 3 -Critical 200
