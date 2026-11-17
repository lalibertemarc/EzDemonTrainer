# EzDemonTrainer

*Stop buying grimoires your demon already knows.*

You're level 38 and standing at the demon trainer with a fistful of silver. The shop lists Torment, Sacrifice, Consume Shadows, Suffering, Firebolt, Blood Pact... in rank after rank. Did your Voidwalker already learn Sacrifice rank 3? Is Torment rank 4 worth it, or will rank 5 replace it in two levels? The trainer won't tell you, and your Voidwalker isn't even out: the Imp is.

**EzDemonTrainer** remembers what each of your demons has learned and tells you which grimoire to buy next.

## A page per demon

`/grimoire` opens a book with a tab for each demon: Imp, Voidwalker, Succubus, Felhunter (and the Incubus in WoW Forever). Each tab lists every ability and every rank, with the level its grimoire needs:

- **Green**: your demon already knows it.
- **Gold**: buy this one now.
- **Grey**: skip it (a higher rank you can already use replaces it), or not yet.

Hover a rank to see the grimoire's price. The tab shows how many grimoires that demon is waiting for, **Buy now** lists everything worth buying at your level with the total cost, and **Next at level N** tells you when the next one opens.

## It remembers who knows what

Summon a demon once and EzDemonTrainer reads its spellbook. From then on its page stays right even while another demon is out, so you can plan your Voidwalker's shopping with the Imp at your side. Each demon's page updates whenever it's summoned and learns something new.

A demon you haven't summoned since installing the addon shows what it *may* still need, until you call it once.

## At the demon trainer

Talk to the demon trainer and the list opens next to the shop. Every grimoire in the shop gets a tag:

| Tag | Means |
|---|---|
| **Known** | Your demon already has it |
| **Learn** | Buy it |
| **Skip** | A higher rank you can already use replaces it |
| **No demon** | You don't have that demon yet |
| **Lv 38** | Not until that level |

Grimoire tooltips say the same thing anywhere: in your bags or on the auction house.

## When you level up

A short chat line says which grimoires just opened for your demons, so you know a trip to the trainer is worth it. `/grimoire notify off` turns it off.

## Good to know

- **For warlocks.** On any other class it stays quiet and does nothing.
- An enslaved demon isn't one of yours, so it's left out.
- Prices are the trainer's base price; a reputation discount makes them a little cheaper.
- **WoW Forever and Classic Era**, from one download. The Incubus learns from the Succubus' grimoires, and it gets its own page.

## Commands

`/grimoire`, `/demontrainer` or `/ezdemontrainer`. There's also a key binding under **Options > Keybindings > EzDemonTrainer**, and in WoW Forever it sits in the addon drawer by the minimap.

| Command | Does |
|---|---|
| `/grimoire` | Open or close the list |
| `/grimoire <demon>` | Open that demon's page (`imp`, `voidwalker`, `succubus`, `incubus`, `felhunter`) |
| `/grimoire trainer [on\|off]` | Open the list when you talk to the demon trainer |
| `/grimoire tags [on\|off]` | Tags on the trainer's grimoires |
| `/grimoire notify [on\|off]` | The level-up chat line |
| `/grimoire forget <demon\|all>` | Forget what a demon knows (summon it again to read it) |
| `/grimoire reset` | Put the window back in the middle of the screen |

## Join us on Discord

Come say hi: **[join the EzAddons Discord](https://discord.com/invite/bZrAYqbsD8)**.

- Hear about new versions first (pick the addons you care about and get pinged when they update).
- Suggest a feature or a whole new addon.
- Report bugs, and help test what's coming next.

## Tell us what you think!

A grimoire tagged wrong? A demon that didn't get read? **Drop it in the [Discord](https://discord.com/invite/bZrAYqbsD8), leave a comment, or open an issue on [GitHub](https://github.com/lalibertemarc/EzDemonTrainer/issues)** and it might be in the next update.
