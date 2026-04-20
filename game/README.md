# Farmstead

An original 2D top-down farming sim for PC (Windows / macOS / Linux), inspired by the Hay Day gameplay loop. All code and placeholder art are original — no Supercell assets or trademarks are used.

## What's in the loop

- **Crops**: wheat, corn, carrot, soybean, sugarcane, cotton — each with buy/sell prices, grow time, XP.
- **Animals**: chickens (eggs), cows (milk), sheep (wool), pigs (bacon). Feed them, wait the cycle, collect.
- **Production buildings**: bakery, feed mill, dairy, sugar mill, loom — each with recipes that consume inputs and produce goods over time.
- **Orders board**: four rotating orders, fulfill for coins + XP, discard for 1 diamond.
- **Economy**: coins + diamonds. Level/XP system with diamond rewards on level up.
- **Inventory**: separate silo (crops) and barn (products/recipes) with capacities.
- **Save / load**: JSON file in Godot's `user://` dir, auto-saves on quit, loads on start, with offline-progress time passed to systems.

## Controls

| Key | Action |
|-----|--------|
| Left click on plot | Plant selected crop (empty) or harvest (ready) |
| Left click on animal pen | Feed (if idle) or collect (if ready) |
| Left click on recipe in building | Start recipe (if idle) or collect (if ready) |
| `S` | Toggle shop panel (seed picker + quick sell) |
| `O` | Toggle orders board |
| `F` | Save game |

## Run it

1. Install [Godot 4.2+](https://godotengine.org/download) (free, open source).
2. Open Godot, click **Import**, point at `game/project.godot`.
3. Press **F5** (Play). First launch asks you to pick the main scene — choose `scenes/main.tscn`.

## Export to a PC build

In Godot: **Project → Export → Add...** and pick Windows Desktop / macOS / Linux. Install the matching export templates when prompted (**Editor → Manage Export Templates**).

## Project layout

```
game/
  project.godot            Godot config (autoloads, input map, window)
  icon.svg                 App icon (placeholder art)
  scenes/main.tscn         Entry scene (thin wrapper around main.gd)
  scripts/
    main.gd                Wires up HUD, farm, animals, buildings, shop, orders
    farm.gd                4x4 grid of plots; tracks selected crop
    plot.gd                Single plot: EMPTY -> PLANTED -> READY
    animals.gd             Pen container
    animal_pen.gd          Single animal: feed -> cycle -> collect
    buildings.gd           Production building container
    building.gd            One building with recipes
    hud.gd                 Top bar: coins / diamonds / level / XP / inventory
    shop.gd                Seed picker + quick-sell panel
    orders_ui.gd           Orders board UI
  autoload/
    catalog.gd             Static data: crops, products, recipes, XP curve
    game_state.gd          Coins, diamonds, XP, level (signals)
    inventory.gd           Silo + barn with capacities
    orders.gd              Order generator + fulfill/discard
    save_system.gd         JSON save/load with offline-time hook
```

## Extending

- **New crop**: add an entry to `Catalog.CROPS` in `autoload/catalog.gd`. Done.
- **New recipe**: add to `Catalog.RECIPES` with a matching `building` id.
- **New building**: add to `DEFS` in `scripts/buildings.gd` and add recipes that reference its id.
- **Level unlocks**: animal/building unlock levels are in their respective script files.
- **Bigger farm**: change `GRID_COLS` / `GRID_ROWS` in `scripts/farm.gd`.

## Known simplifications (vs. Hay Day)

These are scoped stubs; extend as you go.

- Buildings have one slot (no production queue).
- No trees / fishing / mining / visitors / town yet — the systems are structured so adding these is additive (new autoload or scene, plug into HUD and save system).
- No neighborhood / multiplayer. Local single-player only.
- Placeholder art is colored shapes drawn with `_draw()`. Swap for sprites by replacing `_draw()` with `TextureRect` / `AnimatedSprite2D`.
