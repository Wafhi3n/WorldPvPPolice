# World PvP Police Guild

A World of Warcraft addon for WoW: Forever. When another player kills you in the open world, a box
under the death window lets you call your guild for help. It names your killers (up to five, read
from the death recap) and the place you died. Guildmates who run the addon get a window with "On my
way", which sets a waypoint on you, and "Show on map". You keep a "Your call" window listing who's
coming, and "All clear" ends the call for everyone.

- `/wpp`: are guild calls coming in or not.
- `/wpp on`, `/wpp off`: receive guildmates' calls or not (your own calls still go out).
- `/wpp options`: the settings page.
- `/wpp version`

Nothing happens in battlegrounds, arenas or dungeons. Calls survive a `/reload` or a logout and end
after 30 minutes without news.

Languages: English, French, German, Spanish; other game languages fall back to English.

Posting calls to the guild's Discord is a separate, optional addon:
[World PvP Police Guild - Discord](https://github.com/Wafhi3n/WorldPvPPoliceDiscord), for guilds
running the [World PvP Police bot](https://github.com/Wafhi3n/WorldPvPPoliceBot).

## How it works

`WorldPvPPolice_Death.lua` reads the killers from `C_DeathRecap.GetRecapEvents` and the place from
`C_DeathInfo.GetCorpseMapPosition`. Calls, "On my way" and "All clear" travel as guild addon messages
(prefix `WPPolice`), never as chat lines; the format lives in `WorldPvPPolice_Line.lua`. While a call
runs, `WorldPvPPolice_Roster.lua` rereads the guild roster and whispers the call (as an addon
message) to anyone who just logged in. `WorldPvPPolice_Bridge.lua` is the hook an output module such
as the Discord addon plugs into.

Developed in a private workspace with its own checks and headless tests; what has been seen working
in game is logged in `docs/verif-registre.md`. MIT licensed.
