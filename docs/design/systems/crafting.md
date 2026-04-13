# Crafting System

Industrial salvage crafting — rebuilding technology from scavenged components, not primitive survival crafting.

<!-- refs: data/recipes.yaml, data/resources.yaml -->

## Design Philosophy

1. **Industrial, not primitive** — You're salvaging and rebuilding colony tech
2. **Stations matter** — Better stations unlock better recipes and efficiency
3. **Time investment** — Crafting takes time, encouraging preparation
4. **Profession synergy** — Specialists craft faster in their domain
5. **Quality through upgrades** — Station upgrades improve output quality

## Crafting Stations

| Station | Location | Unlocked By | Specialization |
|---------|----------|-------------|----------------|
| Field | Anywhere | Default | Emergency items only |
| Workshop | Workshop Car | Basic Workbench | General crafting, repairs, tools |
| Armory | Armory Car | Armory Racks | Weapons, ammo, combat gear |
| Infirmary | Infirmary Car | Treatment Bay | Medical supplies, treatment items |
| Refinery | Refinery Car | Crude Processor | Fuel processing, material conversion |
| Greenhouse | Greenhouse Car | Basic Planters | Food, botanical items |
| Lab | Lab Car | Research Station | Prototypes, specialty items |

### Station Upgrades

Each station improves through car upgrades:

| Tier | Queue Slots | Speed Bonus | Recipe Access |
|------|-------------|-------------|---------------|
| T1 | 1 | Base | Basic recipes |
| T2 | 2 | +30% | Intermediate recipes |
| T3 | 3 | +60% | Advanced recipes |
| T4 | 4 | +100% | All recipes + prototype variants |

## Crafting Process

### Queue System

1. Select recipe at station
2. Confirm resource cost (resources consumed immediately)
3. Recipe enters queue
4. Crafting progresses in real-time
5. Completed items go to station storage
6. Player retrieves when ready

**Queue Management:**
- Reorder queue priority
- Cancel queued items (50% resource refund)
- Pause/resume crafting
- View time remaining

### Crafting During Gameplay

| Phase | Crafting Status |
|-------|-----------------|
| Train Prep | Active — prime crafting time |
| Travel | Active — crafting continues |
| Expedition | Paused — station unmanned |
| Under Attack | Paused — station disabled |

### Time Modifiers

| Modifier | Effect |
|----------|--------|
| Profession bonus | -25% time (relevant profession) |
| Station upgrade | -30% to -100% (by tier) |
| Power shortage | +50% time |
| Damaged station | +100% time or disabled |
| Rush order | -50% time, +50% resource cost |

## Crafting Categories

### Consumables
Quick-craft items for immediate use.

- **Station:** Workshop, Field
- **Base Time:** 30-60 seconds
- **Examples:** Bandages, ration packs, light sticks, stim shots

### Ammunition
Combat supplies in batches.

- **Station:** Armory, Workshop (basic only)
- **Base Time:** 60-120 seconds
- **Examples:** Standard ammo, shotgun shells, rifle rounds, specialty ammo

### Medical
Health restoration and status treatment.

- **Station:** Infirmary
- **Base Time:** 60-180 seconds
- **Profession Bonus:** Medic (-25%)
- **Examples:** Medical kits, antidotes, surgery supplies, blood packs

### Repair Kits
Equipment and system maintenance.

- **Station:** Workshop
- **Base Time:** 90-120 seconds
- **Examples:** Tool repair kit, weapon maintenance kit, electronics repair kit

### Tools
Profession equipment and utility items.

- **Station:** Workshop
- **Base Time:** 120-300 seconds
- **Examples:** Lockpicks, scanner upgrades, medical tools, engineering kit

### Equipment
Weapons, armor, and gear.

- **Station:** Workshop, Armory
- **Base Time:** 300-600 seconds
- **Examples:** Weapons, armor pieces, backpacks, environmental suits

### Train Parts
Components for train upgrades.

- **Station:** Workshop
- **Base Time:** 600-1200 seconds
- **Examples:** Upgrade components, replacement parts, system modules

### Specialty
Advanced items requiring specific stations.

- **Station:** Lab, Greenhouse
- **Base Time:** 300-900 seconds
- **Profession Bonus:** Researcher, Botanist (-25%)
- **Examples:** Prototypes, advanced compounds, cultivated items

## Field Crafting

Limited crafting available without stations.

### Available Recipes
- Basic bandage
- Improvised torch
- Simple trap
- Jury-rig repair (Machinist only)
- Emergency stim (Medic only)
- Field rations (Botanist only)

### Field Crafting Rules
- 50% slower than station crafting
- Limited recipe list
- No queue (one at a time)
- Machinist unlocks additional field recipes
- Cannot craft during combat

## Recipe Unlocking

### Default Recipes
Available from game start:
- Basic consumables
- Standard ammo
- Simple repairs
- Basic medical

### Schematic Unlocks
Found during expeditions:
- Advanced equipment
- Specialty ammo
- Complex medical
- Upgrade components

### Upgrade Unlocks
Unlocked by station upgrades:
- Higher tier recipes
- Batch crafting
- Quality variants

### Research Unlocks
Unlocked via Lab research:
- Prototype items
- Experimental equipment
- Unique recipes

## Material Conversion

The Refinery allows converting between material types:

| Input | Output | Ratio | Time |
|-------|--------|-------|------|
| Crude Fuel x2 | Processed Fuel x1 | 2:1 | 60s |
| Scrap Metal x5 | Refined Alloys x1 | 5:1 | 120s |
| Scrap Electronics x4 | Circuit Boards x1 | 4:1 | 90s |
| Chemicals x3 + Water x2 | Medical Stock x1 | 5:1 | 150s |

Conversion ratios improve with Refinery upgrades.

## Quality System

Some items have quality tiers:

| Quality | Effect | How to Achieve |
|---------|--------|----------------|
| Poor | -20% effectiveness | Damaged station, no profession |
| Standard | Base effectiveness | Normal crafting |
| Quality | +20% effectiveness | T3+ station + profession |
| Superior | +40% effectiveness | T4 station + profession + rare materials |

Quality applies to:
- Medical items (healing amount)
- Repair kits (repair amount)
- Ammo (damage bonus)
- Equipment (durability, stats)

## Open Questions

- Should failed crafts be possible? (Resource loss on failure)
- Can you craft while traveling through dangerous routes?
- Bulk crafting discount for large quantities?
- Repair vs. replace economy — when is crafting new better than repairing?
- Recipe discovery through experimentation or only schematics?
