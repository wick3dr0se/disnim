import dimscord, os, asyncdispatch

let discord* = newDiscordClient(getEnv("BOT_TOKEN"))

proc getGuilds*(r: Ready) {.async.} =
  for guildID in r.guilds:
    let
      guild = await discord.api.getGuild(guildID.id)
      member = await discord.api.getGuildMember(guild.id, r.user.id)
      perms = computePerms(guild, member)

    echo("GUILD: (", guild.name, "): '", guild.id, "'")
    echo("PERMISSIONS: ", perms)