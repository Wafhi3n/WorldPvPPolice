# Changelog - World PvP Police Guild

## v0.1.0-beta - 2026-11-18

First beta, made for WoW: Forever. It's only been tried on a test client so far, so expect rough
edges on live servers.

- Killed by another player in the open world? A small box under the death window offers to call
  your guild for help. It names who killed you, up to five players read from the whole death recap
  rather than the killing blow alone, so a hunter whose pet finished you off still shows up.
- Add a message if you like, then click Call. Releasing your spirit with a message typed sends the
  call too.
- Guildmates running the addon get a window with your name, zone, coordinates, death count, killers
  and message. "On my way" tells the guild and puts a waypoint on you, "Show on map" marks you on
  the world map.
- Your own "Your call" window lists who's on the way. Die again and the same call updates; you can
  change the message there. "All clear" ends it for everyone, and a call with no news for 30
  minutes ends on its own.
- Calls survive a /reload or a logout, and a guildmate who logs in during your call still gets it.
- Nothing happens in battlegrounds, arenas or dungeons.
- `/wpp off` stops incoming calls, `/wpp options` opens the settings page.
- English, French, German and Spanish.
- Posting calls to your guild's Discord is a separate addon, World PvP Police Guild - Discord.
