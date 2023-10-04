import dimscord, dimscmd, asyncdispatch
import strformat, options, times
import openai
import ./helpers

var
  ai = newAIClient(aiKey)
  cmd = discord.newHandler()

proc interactionHandler*(s: Shard, i: Interaction) {.async.} =
  discard await cmd.handleInteraction(s, i)

proc prefixHandler*(s: Shard, m: Message) {.async.} =
  discard await cmd.handleMessage("!", s, m)

proc slashRegistrar*() {.async.} = await cmd.registerCommands()

cmd.addChat("help") do ():
  discard await discord.api.sendMessage(msg.channel_id,
    embeds = @[Embed(
      color: some 0x7789ec,
      fields: some @[
        EmbedField(
          name: "Prefix Commands",
          value: """
            > `!help`, `!disnim` ... display this message
            > `!ping` ... ping the bot server
          """
        ),
        EmbedField(
          name: "Slash Commands",
          value: """
            > `/ai` ... chat with openai
            > `/image` ... generate images with dall-e
            > `/purge` ... delete <N> messages
            > `/sum` ... get the sum of two integers
          """
        )
      ]
    )]
  )

cmd.addChat("ping") do ():
  let
    before = epochTime() * 1000
    m = await discord.api.sendMessage(msg.channel_id, "Ping?")
    after = epochTime() * 1000
    
  discard await discord.api.editMessage(
    msg.channel_id,
    m.id,
    "Pong! Took " & $int(after - before) & "ms | " & $s.latency() & "ms."
  )

cmd.addChatAlias("help", ["disnim"])

cmd.addSlash("ai") do (text: string):
  ## Chat with OpenAI
  await i.deferResponse()

  var response = await ai.chat(text)

  while true:
    if response.len > 2000:
      discard await i.followup(response[0..1999])
      response = response[2000 .. response.len - 1]
    else:
      discard await i.followup(response[0 .. response.len - 1])
      break

cmd.addSlash("image") do (prompt: string):
  ## Generate an image with DALL-E
  await i.deferResponse()
  
  let response = await ai.imageGen(prompt)

  discard await i.followup(response)

cmd.addSlash("purge") do (amount: int = 0):
  ## Delete <N> messages
  await i.deferResponse()
  
  var
    a: int = amount
    b: int

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

cmd.addSlash("sum") do (a: int, b: int):
  ## Get the sum of two integers
  await i.id.interactionMessage(i.token, fmt"{a} + {b} = {a + b}")