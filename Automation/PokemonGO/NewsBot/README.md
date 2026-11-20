# Pokémon GO News Discord Bot

This PowerShell script checks [pokemongo.com/news](https://pokemongo.com/news) every 15 minutes and posts new article titles and links to a Discord channel. It uses the Discord bot REST API and PowerShell's built-in web cmdlets; no extra modules are required.

## Configure

Create a Discord application and bot, invite it to your server with permission to send messages, and get the target channel's ID. Set these environment variables in the environment where the script will run:

- `DISCORD_BOT_TOKEN` — the bot token
- `DISCORD_CHANNEL_ID` — numeric ID of the destination channel
- `POKEMONGO_POLL_INTERVAL_SECONDS` — optional polling interval; defaults to `900` and must be at least `60`

Keep the bot token out of source control and configure it through a secure environment or secret manager. Do not put it in this README or commit it.

## Run

From this directory, run:

```powershell
pwsh -File .\Watch-PokemonGoNews.ps1
```

On its first run, the bot records the articles currently on the page without posting them. Later runs announce only articles not already recorded. The `state.json` file is created beside the script and should be kept between runs.

For a single check (useful for testing configuration), run:

```powershell
pwsh -File .\Watch-PokemonGoNews.ps1 -Once
```

Use Task Scheduler or another process manager to keep the bot running if it should start automatically.
