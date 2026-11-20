param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName
)

Import-Module vmxtoolkit -ErrorAction Stop

$VMs = @(Get-VMX -VMXName $VMName -WarningAction SilentlyContinue |
    Where-Object { $_.VMXName -eq $VMName })

if ($VMs.Count -eq 0) {
    Write-Output "VM $VMName does not exist"
}
elseif ($VMs | Where-Object { $_.State -eq 'running' }) {
    Write-Output "VM $VMName is online"
}
else {
    Write-Output "VM $VMName is offline"
}
