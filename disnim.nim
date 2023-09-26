import dimscord, asyncdispatch, times, options, strutils, os
import ./helpers

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

# // templates & calls
# we use handler procs because the existing template event handlers can't take our custom procs
# when bot is connected to discord & ready
proc onBotReady(s: Shard, r: Ready) {.async.} =
  echo "Ready as " & $r.user & " in: "
  getGuilds(r)

# scan and handle create message events
proc onCreateMessage(s: Shard, m: Message) {.async.} =
  if m.author.bot: return

  if m.content.startsWith("!help"):
    await exclamHelp(m) # call '!help' command
  elif m.content.startsWith("!ping"):
    await exclamPing(s, m) # call '!ping' command
  elif m.content.startsWith("/wipe"):
    await slashWipe(m) # call '/wipe' command

# re-define procs to existing template names
discord.events.onReady = onBotReady
discord.events.messageCreate = onCreateMessage

waitFor discord.startSession()