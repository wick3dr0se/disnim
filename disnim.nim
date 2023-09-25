import dimscord, asyncdispatch, times, options, strutils, os

let discord = newDiscordClient(getEnv("BOT_TOKEN"))

# // definitions
# respond to the client with pong, time & latency
proc exclamPing(s: Shard, m: Message) {.async.} =
  let
    before = epochTime() * 1000
    msg = await discord.api.sendMessage(m.channel_id, "ping?")
    after = epochTime() * 1000

  discard await discord.api.editMessage(
    m.channel_id,
    msg.id,
    "Pong! took " & $int(after - before) & "ms | " & $s.latency() & "ms."
  )

# wipe all channel messages
proc slashWipe(m: Message) {.async.} =
  var messageIDs: seq[string] = @[]
  let messages = await discord.api.getChannelMessages(m.channel_id)
  
  for message in messages:
    messageIDs.add(message.id)

  # creates illegal access error; attempted to loop 10 iterations and sleep 1 sec but still errors out  
  await discord.api.bulkDeleteMessages(m.channel_id, messageIDs)

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