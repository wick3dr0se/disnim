import dimscord, dimscmd, asyncdispatch
import strformat, options, times
import ./helpers

var cmd = discord.newHandler()

proc interactionHandler*(s: Shard, i: Interaction) {.async.} =
  discard await cmd.handleInteraction(s, i)

proc prefixHandler*(s: Shard, m: Message) {.async.} =
  discard await cmd.handleMessage("!", s, m)

proc slashRegistrar*() {.async.} =

  await cmd.registerCommands()

cmd.addChat("help") do ():
  discard await discord.api.sendMessage(
    msg.channel_id,
    embeds = @[
      Embed(
        color: some 0x7789ec,
        fields: some @[
          EmbedField(
            name: "Prefix Commands",
            value: """
              > `!help` ... display this message
              > `!ping` ... ping the bot server
            """
          ),
          EmbedField(
            name: "Slash Commands",
            value: """
              > `/sum` ... get the sum of two integers
              > `/purge` ... delete <N> messages
            """
          )
        ]
      )
    ]
  )

cmd.addChat("ping") do ():
  let
    before = epochTime() * 1000
    m = await discord.api.sendMessage(msg.channel_id, "Ping?")
    after = epochTime() * 1000
    
  discard await discord.api.editMessage(
    msg.channel_id,
    m.id,
    "Pong! took " & $int(after - before) & "ms | " & $s.latency() & "ms."
  )

cmd.addSlash("sum") do (a: int, b: int):
  ## Get the sum of two integers
  await interactionMessage(i.id, i.token, fmt"{a} + {b} = {a + b}")

cmd.addSlash("purge") do (amount: int = 0):
  ## Delete <N> messages
  var
    a: int = amount
    b: int

  await i.deferResponse()

  while true:
    let msgs = await discord.api.getChannelMessages(i.channel_id.get())

    if msgs.len == 0: return

    if amount == 0: a = msgs.len

    for m in msgs:
      if a >= b:
        await discord.api.deleteMessage(m.channel_id, m.id)
        await sleepAsync(600)

        b += 1
      else:
        return