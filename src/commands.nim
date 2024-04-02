import dimscord, dimscmd, asyncdispatch, strutils
import strformat, options, times
import openai, unsplash
import ./helpers

var
  unsplashApi = newUnsplashClient(unsplashKey)
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

cmd.addSlash("sum") do (a: int, b: int):
  ## Get the sum of two integers
  await i.id.interactionMessage(i.token, fmt"{a} + {b} = {a + b}")

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

cmd.addSlash("unsplash") do (count: int, query: string):
  ## Retrieve random image(s) via query from Unsplash
  var links: string
  
  await i.deferResponse()

  let
    queries = split(query, ",")
    response = await unsplashApi.randomPhoto(queries, count)
  
  for r in response:
    links &= r.link & " "
  
  discard await i.followup(links)

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

cmd.addSlash("sub") do (role: string):
  ## Subscribe to a role
  let gid = i.guild_id.get()
  let mid = i.member.get().user.id
  let roles = i.member.get().roles

  var roleId: string
  if role.startsWith("<@&") and role.endsWith(">"):
    roleId = role[3..^2]
    
    if roleId in roles:
      await i.id.interactionMessage(i.token, fmt"{role} role already assigned")
      return
    
    try:
      await discord.api.addGuildMemberRole(gid, mid, roleId)
      await i.id.interactionMessage(i.token, fmt"Assigned role {role}")
    except:
      await i.id.interactionMessage(i.token, "403: Bad permissions")
  else:
    await i.id.interactionMessage(i.token, "Invalid role")

cmd.addSlash("unsub") do (role: string):
  ## Unsubscribe to a role
  let gid = i.guild_id.get()
  let mid = i.member.get().user.id
  let roles = i.member.get().roles

  var roleId: string
  if role.startsWith("<@&") and role.endsWith(">"):
    roleId = role[3..^2]

    if roleId notin roles:
      await i.id.interactionMessage(i.token, fmt"{role} role is not assigned")
      return

    await discord.api.removeGuildMemberRole(gid, mid, roleId)
    await i.id.interactionMessage(i.token, fmt"Unassigned role {role}")
  else:
    await i.id.interactionMessage(i.token, "Invalid role")

cmd.addSlash("subs") do (role: string):
  ## Get the amount of subscribers to a role
  await i.deferResponse()

  let gid = i.guild_id.get()
  
  var roleId: string
  if role.startsWith("<@&") and role.endsWith(">"):
    roleId = role[3..^2]
  else:
    await i.id.interactionMessage(i.token, "Invalid role")
    return

  let mems = await discord.api.getGuildMembers(gid, 1000)

  var subCnt = 0

  for mem in mems:
    let roles = mem.roles

    if roleId in roles:
      inc subCnt

  discard await i.followup(fmt"{subCnt} users subscribed to {role}")