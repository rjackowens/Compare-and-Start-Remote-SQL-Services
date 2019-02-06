# This is a list of all servers we're pulling service info from
$ServersOutput = Get-ADComputer -Filter * | Select-Object -Property DNSHostName | Sort-Object -Property DNSHostName

# Specifies Local Folder Location to Save Lists 
$MasterListPath = "C:\Users\" + $env:username + "\Documents\masterlist.csv"
$CurrentListPath = "C:\Users\" + $env:username + "\Documents\currentlist.csv"

$SaveStatusPrompt = Read-Host "Do you want to save the status of all current SQL services to masterlist? Enter Y or N"

if ($SaveStatusPrompt.ToUpper() -eq "Y") {

    # Saves all Master SQL Service Info to masterlist.csv 
    $GetMasterList = $ServersOutput.DNSHostName | ForEach-Object {

        Get-Service -ComputerName $_ -Exclude "MSSQLServerADHelper100" | Where-Object ({$_.DisplayName -Like '*SQL*' -OR $_.Name -Like '*MSDTC*'}) | Select-Object DisplayName, MachineName, Status
    }

    # Export Master List
    $GetMasterList | Export-Csv -Path $MasterListPath -NoTypeInformation
}

# Saves all current SQL Service Info to currentlist.csv
$GetCurrentList = $ServersOutput.DNSHostName | ForEach-Object {

    Get-Service -ComputerName $_ -Exclude "MSSQLServerADHelper100" | Where-Object ({$_.DisplayName -Like '*SQL*' -OR $_.Name -Like '*MSDTC*'}) | Select-Object DisplayName, MachineName, Status
}

# Export Current List
$GetCurrentList | Export-Csv -Path $CurrentListPath -NoTypeInformation

# Imports Both Lists 
$MasterList = Import-Csv -Path  $MasterListPath 
$CurrentList = Import-Csv -Path  $CurrentListPath

# Compares both Lists by DisplayName, MachineName, and Status
$ObjectList = Compare-Object -ReferenceObject $MasterList -DifferenceObject $CurrentList -Property DisplayName, MachineName, Status | Sort-Object -Unique DisplayName | Select-Object DisplayName, MachineName, Status

$StartServicePrompt = Read-Host "Do you want to start all stopped services? Enter Y or N"

if ($StartServicePrompt.ToUpper() -eq "Y") {

    # This starts all stopped services
    $ObjectList | ForEach-Object {

        Get-Service -Name $_.DisplayName -ComputerName $_.MachineName | Start-Service
    }
}
