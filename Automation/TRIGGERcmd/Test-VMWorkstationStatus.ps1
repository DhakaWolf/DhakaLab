try {
    $objProc = Get-Process -Name 'vmware'
    If ($objProc){
        If ($objProc.Responding -eq $true){
            Write-Output 'Workstation is currently running.'
        } Else {
            Write-Output 'Workstation is currently not running or not responding.'
        }
    }
}
catch {
    Write-Output "There was a problem checking the status of VMware Workstation on $env:HOSTNAME"
}