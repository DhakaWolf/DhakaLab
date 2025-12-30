function Get-GHReleaseURL{
    param (
        $Owner,
        $Repo
    )
    $Result = (Invoke-RestMethod -Method 'GET' -uri "https://api.github.com/repos/$($Owner)/$($Repo)/releases/latest").assets.browser_download_url
    if ($null -ne $Result) {
        if ($result ) {
            <# Action to perform if the condition is true #>
        }
        return $Result
    }
}
function Test-ACTInstalled{
    $ctrACTInstances = [int]0
    If((Test-Path "$env:USERPROFILE\Advanced Combat Tracker\Advanced Combat Tracker.exe")){
        $ctrACTInstances ++
        $varACTInstall = "$env:USERPROFILE\Advanced Combat Tracker\Advanced Combat Tracker.exe"
    }elseif((Test-Path "$env:ProgramFiles\Advanced Combat Tracker\Advanced Combat Tracker.exe")){
        $ctrACTInstances ++
        $varACTInstall = "$env:ProgramFiles\Advanced Combat Tracker\Advanced Combat Tracker.exe"
    }elseif((Test-Path "$env:ProgramFiles(x86)\Advanced Combat Tracker\Advanced Combat Tracker.exe")){
        $ctrACTInstances ++
        $varACTInstall = "$env:ProgramFiles(x86)\Advanced Combat Tracker\Advanced Combat Tracker.exe"
    }Else{
        Write-Output "Advanced Combat Tracker is not installed on this system."
    }
    if ($ctrACTInstances -gt 1) {
        Write-Output "Multiple instances of Advanced Combat Tracker were found on this system. Please ensure only one instance is installed."
    } Else {
        return $varACTInstall
    }
}
function Start-ACTProcess {
    # Check for updates to ACT
    
    # Check for plugins, check for updates to plugins
    ## List of plugins enabled
    [xml]$objACTConfig = gc "$env:USERPROFILE\AppData\Roaming\Advanced Combat Tracker\Config\Advanced Combat Tracker.config.xml" -Raw
    $pluginsEnabled = $objACTConfig.Config.ActPlugins.Plugin | Where-Object { $_.Enabled -eq 'true' } | Select-Object -ExpandProperty Name
    Foreach ($plugin in $pluginsEnabled){
        $file = Split-Path $plugin -Leaf
        Switch ($file){
            "FFXIV_ACT_Plugin.dll" {
                Start-BitsTransfer -Source (Get-GHReleaseURL -Owner "ravahn" -Repo "FFXIV_ACT_Plugin") -Destination "$env:APPDATA\Advanced Combat Tracker\Plugins\FFXIV_ACT_Plugin.zip"
                Expand-Archive -Path "$env:APPDATA\Advanced Combat Tracker\Plugins\FFXIV_ACT_Plugin.zip" -DestinationPath "$env:APPDATA\Advanced Combat Tracker\Plugins\" -Force
                Remove-Item "$env:APPDATA\Advanced Combat Tracker\Plugins\FFXIV_ACT_Plugin.zip"
            }
            "OverlayPlugin.dll" {
                Start-BitsTransfer -Source (Get-GHReleaseURL -Owner "OverlayPlugin" -Repo "OverlayPlugin") -Destination "$env:APPDATA\Advanced Combat Tracker\Plugins\OverlayPlugin.zip"
                Expand-Archive -Path "$env:APPDATA\Advanced Combat Tracker\Plugins\OverlayPlugin.zip" -DestinationPath "$env:APPDATA\Advanced Combat Tracker\Plugins\" -Force
                Remove-Item "$env:APPDATA\Advanced Combat Tracker\Plugins\OverlayPlugin.zip"
            }
            "CactbotOverlay.dll" {
                Start-BitsTransfer -Source (Get-GHReleaseURL -Owner "OverlayPlugin" -Repo "cactbot") -Destination "$env:APPDATA\Advanced Combat Tracker\Plugins\cactbot.zip"
                Expand-Archive -Path "$env:APPDATA\Advanced Combat Tracker\Plugins\cactbot.zip" -DestinationPath "$env:APPDATA\Advanced Combat Tracker\Plugins\cactbot" -Force
                Remove-Item "$env:APPDATA\Advanced Combat Tracker\Plugins\cactbot.zip"
            }
            "ActStatter.dll" {
                Start-BitsTransfer -Source (Get-GHReleaseURL -Owner "eq2reapp" -Repo "ActStatter") -Destination "$env:APPDATA\Advanced Combat Tracker\Plugins\ActStatter.dll"
            }
        }
    }
    ## OverlayPlugin - Cactbot
    $varOverlayPluginVer = Get-GHRelease -Owner "OverlayPlugin" -Repo "cactbot"
    $varInstOverlayPluginVer = ((Get-Item "$env:APPDATA\Advanced Combat Tracker\Plugins\cactbot\cactbot\CactbotOverlay.dll").VersionInfo.FileVersion -replace '.0','')

    $results = @()
        $running = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($running) {
            Stop-Process -Id $running.Id -Force
        }
        else {
            try {
                $started = Start-Process -FilePath "$env:USERPROFILE\Advanced Combat Tracker\Advanced Combat Tracker.exe" -PassThru -Verb RunAs
                $results += "$ProcessName started successfully (PID: $($started.Id))"
            }
            catch {
                $results += "Failed to start $ProcessName : $($_.Exception.Message)"
            }
    }
    return $results -join "`n"
}
function Start-FFXIVProcess {
    $results = @()
        $running = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($running) {
            $results += "$ProcessName is already running (PID: $($running.Id))"
        }
        else {
            try {
                $started = Start-Process -FilePath "F:\DhakaLab\Shares\FINAL FANTASY XIV - A Realm Reborn\game\ffxiv_dx11.exe" -PassThru
                $results += "$ProcessName started successfully (PID: $($started.Id))"
            }
            catch {
                $results += "Failed to start $ProcessName : $($_.Exception.Message)"
            }
    }
    return $results -join "`n"
}

# Execute and output results as string
$output = Start-ACTProcess
$output = Start-FFXIVProcess
Write-Output $output