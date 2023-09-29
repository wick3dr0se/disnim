import dimscord, asyncdispatch, times, options, tables, strutils, os

let discord = newDiscordClient(getEnv("BOT_TOKEN"))

# // definitions
# send bot usage/help embed
proc exclamHelp(m: Message) {.async.} =
  discard await discord.api.sendMessage(
    m.channel_id,
    embeds = @[Embed(
      title: some "Commands:",
      description: some """
        > `!help` ... display this message
        > `!ping` ... ping the bot server
        > `/wipe` ... wipe all channel messages
      """,
      color: some 0x7789ec
    )]
  )
 
# respond to the client with pong, time & latency
proc exclamPing(s: Shard, m: Message) {.async.} =
  let
    before = epochTime() * 1000
    msg = await discord.api.sendMessage(m.channel_id, "Ping?")
    after = epochTime() * 1000

  discard await discord.api.editMessage(
    m.channel_id,
    msg.id,
    "Pong! took " & $int(after - before) & "ms | " & $s.latency() & "ms."
  )

# wipe all channel messages
proc slashWipe(m: Message) {.async.} =
  while true:
    let messages = await discord.api.getChannelMessages(m.channel_id)

    if messages.len == 0:
      break

    for i in messages:
      await discord.api.deleteMessage(m.channel_id, i.id)
      await sleepAsync(750)

# // custom procs
# when bot is connected to discord & ready
proc onBotReady(s: Shard, r: Ready) {.async.} =
  echo "Ready as " & $r.user & " in: "

  for g in r.guilds:
    let
      guild = await discord.api.getGuild(g.id)
      memb = await discord.api.getGuildMember(guild.id, r.user.id)
      perms = computePerms(guild, memb)

    echo("Guild: (", guild.name, "): '", guild.id, "'")
    echo("Permissions: ", perms)

# proccess messages when created
proc onCreateMessage(s: Shard, m: Message) {.async.} =
  if m.author.bot: return

  let
    guild = s.cache.guilds[m.guild_id.get]
    ch = s.cache.guildChannels[m.channel_id]
    memb = await s.getGuildMember(m.guild_id.get, m.author.id)
    perms = guild.computePerms(memb, ch)

  if permManageMessages notin perms.allowed:
    echo("Error: permission 'Manage Messagess' not accessible for " & memb.user.username & "!")
    discard await discord.api.sendMessage(m.channel_id, "Permission not allowed!")
    return

  if m.content.startsWith("!help"):
    await exclamHelp(m)
  elif m.content.startsWith("!ping"):
    await exclamPing(s, m)
  elif m.content.startsWith("/wipe"):
    await slashWipe(m)

# // event templates
# triggers when guild member joins
proc guildMemberAdd(s: Shard, g: Guild, m: Member) {.event(discord).} =
  let ch = g.system_channel_id.get()

  discard await discord.api.sendMessage(
    ch,
    embeds = @[Embed(
      title: some "New Member:",
      description: some "Welcome to " & g.name & ", " & m.user.username & "!",
      color: some 0x00cc66
    )]
  )

  echo("User: ", m.user.username, " joined ", g.name)


# re-define our custom procs to existing template names
discord.events.onReady = onBotReady # triggers when bot is ready
discord.events.messageCreate = onCreateMessage # triggers when a message is created

waitFor discord.startSession(
  # pass all our intents
  gateway_intents = {
    giGuilds,
    giGuildMembers,
    giGuildMessages,
    giMessageContent
  }
)