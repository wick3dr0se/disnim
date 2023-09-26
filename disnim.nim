import dimscord, asyncdispatch, times, options, strutils, os

let discord = newDiscordClient(getEnv("BOT_TOKEN"))

# // definitions
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

# scan and handle message events
proc handleMessage(s: Shard, m: Message) {.async.} =
  if m.author.bot: return

  if m.content.startsWith("!ping"):
    await exclamPing(s, m) # call '!ping' command
  elif m.content.startsWith("/wipe"):
    await slashWipe(m) # call '/wipe' command

# // templates & calls
# when bot is connected to discord & ready
proc onReady(s: Shard, r: Ready) {.event(discord).} =
  echo "Ready as " & $r.user # write bot username

# re-define procs to existing template names
discord.events.messageCreate = handleMessage

waitFor discord.startSession()