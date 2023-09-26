import dimscord, os, asyncdispatch

let discord* = newDiscordClient(getEnv("BOT_TOKEN"))

proc getGuilds*(r: Ready) {.async.} =
  for guildID in r.guilds:
    let guild = await discord.api.getGuild(guildID.id)
    echo(guild.name, ": ", guild.id)