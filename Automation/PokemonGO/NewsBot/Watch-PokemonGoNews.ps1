[CmdletBinding()]
param(
    [switch]$Once
)

$ErrorActionPreference = 'Stop'

$newsUri = 'https://pokemongo.com/news'
$statePath = Join-Path $PSScriptRoot 'state.json'
$defaultPollIntervalSeconds = 900

function Get-NewsArticles {
    $response = Invoke-WebRequest -Uri $newsUri -TimeoutSec 30 -ErrorAction Stop
    $pattern = '(?is)<a\b[^>]*href="(?<path>/news/[^"#?]+)"[^>]*>(?<body>.*?)</a>'
    $matches = [regex]::Matches($response.Content, $pattern)
    $articles = @()
    $seenUrls = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($match in $matches) {
        $title = [System.Net.WebUtility]::HtmlDecode(
            ($match.Groups['body'].Value -replace '<[^>]+>', ' ' -replace '\s+', ' ')
        ).Trim()

        if ([string]::IsNullOrWhiteSpace($title)) {
            continue
        }

        $path = [System.Net.WebUtility]::HtmlDecode($match.Groups['path'].Value)
        $url = [uri]::new([uri]$newsUri, $path).AbsoluteUri
        if ($seenUrls.Add($url)) {
            $articles += [PSCustomObject]@{
                Title = $title
                Url   = $url
            }
        }
    }

    if ($articles.Count -eq 0) {
        throw "No news articles were found at $newsUri. The page markup may have changed."
    }

    return $articles
}

function Save-NewsState {
    param(
        [Parameter(Mandatory)]
        [string[]]$SeenUrls
    )

    $state = @{
        SeenUrls      = @($SeenUrls)
        UpdatedAtUtc  = [datetime]::UtcNow.ToString('o')
    }
    $json = ConvertTo-Json -InputObject $state -Depth 3
    $temporaryPath = "$statePath.tmp"

    [System.IO.File]::WriteAllText(
        $temporaryPath,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )
    Move-Item -LiteralPath $temporaryPath -Destination $statePath -Force
}

function Send-DiscordNews {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Article,

        [Parameter(Mandatory)]
        [string]$BotToken,

        [Parameter(Mandatory)]
        [string]$ChannelId
    )

    $payload = @{
        content = "$($Article.Title)`n$($Article.Url)"
        allowed_mentions = @{
            parse = @()
        }
    }
    $body = ConvertTo-Json -InputObject $payload -Depth 4 -Compress
    $headers = @{
        Authorization = "Bot $BotToken"
    }
    $discordUri = "https://discord.com/api/v10/channels/$ChannelId/messages"

    Invoke-RestMethod `
        -Uri $discordUri `
        -Method Post `
        -Headers $headers `
        -ContentType 'application/json' `
        -Body $body `
        -TimeoutSec 30 `
        -ErrorAction Stop | Out-Null
}

if ([string]::IsNullOrWhiteSpace($env:DISCORD_BOT_TOKEN)) {
    throw 'Set the DISCORD_BOT_TOKEN environment variable before starting the bot.'
}
if ([string]::IsNullOrWhiteSpace($env:DISCORD_CHANNEL_ID) -or $env:DISCORD_CHANNEL_ID -notmatch '^\d+$') {
    throw 'Set DISCORD_CHANNEL_ID to the numeric ID of the Discord channel.'
}

$pollIntervalSeconds = $defaultPollIntervalSeconds
if (-not [string]::IsNullOrWhiteSpace($env:POKEMONGO_POLL_INTERVAL_SECONDS)) {
    $parsedInterval = 0
    if (-not [int]::TryParse($env:POKEMONGO_POLL_INTERVAL_SECONDS, [ref]$parsedInterval) -or $parsedInterval -lt 60) {
        throw 'POKEMONGO_POLL_INTERVAL_SECONDS must be an integer of at least 60.'
    }
    $pollIntervalSeconds = $parsedInterval
}

$botToken = $env:DISCORD_BOT_TOKEN
$channelId = $env:DISCORD_CHANNEL_ID
$seenUrls = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $state.SeenUrls) {
        throw "State file '$statePath' is missing its SeenUrls list."
    }
    foreach ($url in @($state.SeenUrls)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$url)) {
            [void]$seenUrls.Add([string]$url)
        }
    }
}
else {
    $initialArticles = @(Get-NewsArticles)
    foreach ($article in $initialArticles) {
        [void]$seenUrls.Add($article.Url)
    }
    Save-NewsState -SeenUrls @($seenUrls)
    Write-Host "Initialized tracking for $($initialArticles.Count) existing articles; no messages sent."
}

while ($true) {
    try {
        $articles = @(Get-NewsArticles)
        $newArticles = @($articles | Where-Object { -not $seenUrls.Contains($_.Url) })
        [array]::Reverse($newArticles)

        foreach ($article in $newArticles) {
            Send-DiscordNews -Article $article -BotToken $botToken -ChannelId $channelId
            [void]$seenUrls.Add($article.Url)
            Save-NewsState -SeenUrls @($seenUrls)
            Write-Host "Posted: $($article.Title)"
        }

        if ($newArticles.Count -eq 0) {
            Write-Host "No new articles found at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')."
        }
    }
    catch {
        if ($Once) {
            throw
        }
        Write-Error -Message "News check failed: $($_.Exception.Message)" -ErrorAction Continue
    }

    if ($Once) {
        break
    }
    Start-Sleep -Seconds $pollIntervalSeconds
}
