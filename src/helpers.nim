import dimscord, asyncdispatch
import os, options

let
  token* = getEnv("BOT_TOKEN")
  aiKey* = getEnv("AI_KEY")
  discord* {.mainClient.} = newDiscordClient(token)

proc interactionMessage*(id: string, token: string, content: string, flags: set[MessageFlags] = {}) {.async.} =
  await discord.api.interactionResponseMessage(id, token, kind = irtChannelMessageWithSource, response = InteractionCallbackDataMessage(flags: flags, content: content))

proc interactionEditMessage*(token: string, content: Option[string]) {.async.} =
  let app = await discord.api.getCurrentApplication()

  discard await discord.api.editInteractionResponse(app.id, token, "@original", content = content)