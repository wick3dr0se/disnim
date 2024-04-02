import dimscord, asyncdispatch
import options, re
import ./src/[helpers, commands]

proc onReady(s: Shard, r: Ready) {.event(discord).} =
  echo("Ready as ", $r.user, " in:")
  
  for g in r.guilds:
    let
      guild = await discord.api.getGuild(g.id)
      memb = await discord.api.getGuildMember(guild.id, r.user.id)
      perms = computePerms(guild, memb)

    echo("Guild: ", guild.name, "#", guild.id)
    echo("Permissions: ", perms.allowed)

    await slashRegistrar()

proc interactionCreate(s: Shard, i: Interaction) {.event(discord).} =
  await interactionHandler(s, i)

proc guildMemberAdd(s: Shard, g: Guild, m: Member) {.event(discord).} =
  discard await discord.api.sendMessage(
    g.system_channel_id.get(),
    embeds = @[Embed(
      title: some "Member Joined",
      description: some "Welcome to " & g.name & ", " & $m.user & "!",
      color: some 0x00cc66
    )]
  )

  echo("User: ", $m.user, " joined ", g.name)

proc guildMemberRemove(s: Shard, g: Guild, m: Member) {.event(discord).} =
  echo("User: ", $m.user, " left ", g.name)
  #[
  discard await discord.api.sendMessage(
    g.system_channel_id.get(),
    embeds = @[Embed(
      title: some "Member Left",
      description: some "Au revoir " & $m.user & ", may your code be as stable as your loyalty!",
      color: some 0xff4d4d
    )]
  )
  ]#

proc messageCreate(s: Shard, m: Message) {.event(discord).} =
  if m.author.bot: return

  if m.content.contains(re"(?:https?:\/\/)?(?:\w+\.)?discord(?:(?:app)?\.com\/invite|\.gg)\/([A-Za-z0-9-]+)"):
    await discord.api.deleteMessage(m.channel_id, m.id, "No Discord links allowed!")

  await prefixHandler(s, m)

waitFor discord.startSession(
  gateway_intents = {
    giGuilds,
    giGuildMembers,
    giGuildMessages,
    giMessageContent
  }
)