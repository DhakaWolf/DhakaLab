# TRIGGERcmd

Test-VMWorkstation.ps1
: Returns simple output on the status of the VMware Workstation Pro process. 

Get-LabVMStatus.ps1
: Returns simple output on the status of a specific virtual machine. The VM name is the first positional parameter.

Usage: `.\Get-LabVMStatus.ps1 "VM Name"`

Output: `VM VM Name is online`, `VM VM Name is offline`, or `VM VM Name does not exist`
