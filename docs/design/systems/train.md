# Train System

The train is not a vehicle you use — it's a place you live. Every system the players rely on exists on the train. When the train is damaged, capabilities degrade. When it's upgraded, new options open. The train's visible state is the campaign's progress bar.

<!-- refs: data/train-cars.yaml, data/upgrades.yaml -->

## Design Principles

1. **Everything important happens on or from the train** — no secondary bases
2. **Visual progression** — players should see their train transform over a campaign
3. **Systemic interdependence** — cars and subsystems rely on each other
4. **Crew scaling** — works with 2 players (skeleton crew) or 8 (full complement)
5. **Damage matters** — systems degrade, require repair, create pressure

## Train Cars

The train consists of 10 distinct car types. Not all cars are available at campaign start — some must be recovered, repaired, or constructed.

| Car | Primary Function | Key Systems |
|-----|------------------|-------------|
| **Engine** | Locomotion, power generation | Locomotion, Power Grid |
| **Cargo** | Storage capacity | Inventory management |
| **Workshop** | Crafting, fabrication, repairs | Fabricator |
| **Infirmary** | Healing, status treatment | Medical Bay |
| **Bunks** | Crew capacity, rest, morale | Climate Control |
| **Greenhouse** | Sustainable food/meds production | Hydroponics |
| **Armory** | Weapon storage, ammo crafting, defense | Turrets/Defense |
| **Signal/Command** | Route intel, comms, navigation | Comms Array, Navigation |
| **Refinery** | Fuel processing, resource conversion | Refinery Stack |
| **Lab/Research** | Schematics, analysis, special crafting | Research Station |

### Car Dependencies

Some cars require others to function:

- **Workshop** requires **Engine** (power)
- **Infirmary** requires **Engine** (power) + **Workshop** (medical supplies)
- **Greenhouse** requires **Engine** (power) + **Refinery** (nutrients)
- **Lab** requires **Engine** (power) + **Workshop** (tools) + **Signal** (data)

### Acquiring Cars

- **Starting:** Engine (damaged), Cargo (basic), Bunks (makeshift)
- **Early recovery:** Workshop, Infirmary
- **Mid-campaign:** Armory, Signal/Command, Refinery
- **Late-campaign:** Greenhouse, Lab/Research

## Subsystems

Each car contains subsystems that can be upgraded, damaged, or disabled.

| Subsystem | Location | Function | When Damaged |
|-----------|----------|----------|--------------|
| **Locomotion** | Engine | Movement speed, fuel consumption | Slower travel, stranding risk |
| **Power Grid** | Engine | Powers all other systems | Systems go offline progressively |
| **Fabricator** | Workshop | Crafting station | Can't craft, only basic repairs |
| **Medical Bay** | Infirmary | Healing, surgery, status cure | Slower recovery, death risk from injuries |
| **Comms Array** | Signal | Route intel, distress calls | Blind travel, no warnings |
| **Navigation** | Signal | Route planning, hazard detection | Limited route options |
| **Climate Control** | Bunks | Crew comfort, morale | Fatigue debuffs |
| **Turrets/Defense** | Armory | Repel attacks during travel | Vulnerable to route ambushes |
| **Hydroponics** | Greenhouse | Passive food/med generation | Supply drain increases |
| **Refinery Stack** | Refinery | Fuel conversion, material processing | Resource inefficiency |
| **Research Station** | Lab | Schematic analysis, prototype crafting | Can't unlock advanced tech |

### Subsystem States

Each subsystem operates in one of four states:

1. **Offline** — Not powered or not installed
2. **Damaged** — Functioning at reduced capacity, needs repair
3. **Operational** — Normal function
4. **Upgraded** — Enhanced function (faster, more efficient, additional features)

## Crew Scaling

The train must function across different crew sizes without feeling empty or overcrowded.

| Crew Size | Car Coverage | Playstyle |
|-----------|--------------|-----------|
| **2 players** | 2-3 cars actively manned | Skeleton crew, constant triage |
| **4 players** | 4-5 cars manned, some multitasking | Standard operations, balanced |
| **6 players** | 6-7 cars manned, light specialization | Full crew, roles solidify |
| **8 players** | All cars manned, deep specialization | Optimal, everyone has a station |

### Unmanned Car Behavior

Cars without a player assigned:
- **Passive function only** — no active abilities, no crisis response
- **Degradation over time** — minor wear accumulates
- **Alert system** — problems flag to other players
- **Periodic check-ins** — someone must visit to prevent failures

This creates expedition tension: take everyone and risk train problems, or leave crew behind and have fewer hands in the field.

## Progression States

The train evolves visually and mechanically through the campaign.

| State | Description | Capabilities |
|-------|-------------|--------------|
| **1. Wreck** | Immobile, 2-3 cars barely functional | Shelter only, must scavenge to move |
| **2. Limping** | Mobile but fragile, 4-5 cars | Short routes, frequent breakdowns |
| **3. Functional** | Stable operations, 6-7 cars | Standard expedition range |
| **4. Fortified** | Upgraded systems, all cars online | Longer routes, better defenses |
| **5. Command** | Fully optimized, advanced tech | Endgame routes, launch prep viable |

### State Transitions

Transitions are gated by:
- **Car recovery** — finding and attaching new cars
- **Key repairs** — fixing critical subsystems
- **Upgrade milestones** — reaching certain upgrade thresholds
- **Crew milestones** — recruiting specialists

## Train Resources

The train consumes and stores resources:

### Consumption
- **Fuel** — consumed during travel, scales with distance and speed
- **Supplies** — consumed passively by crew (food, water, air filters)
- **Power** — generated by engine, distributed to subsystems

### Storage
- **Cargo capacity** — limited by Cargo car upgrades
- **Specialized storage** — some items require specific cars (weapons in Armory, meds in Infirmary)

## Train Combat

The train can be attacked during travel or while stationary at hostile locations.

### Defense Systems
- **Turrets** — automated or manned, require ammo
- **Armor plating** — damage reduction, upgradeable
- **Emergency systems** — fire suppression, breach sealing

### Damage Model
- Attacks target specific cars or subsystems
- Damage cascades if not addressed (fire spreads, breaches worsen)
- Critical damage can disable cars entirely
- Catastrophic damage = campaign loss

## Open Questions

- Should cars be physically arrangeable (player chooses order) or fixed?
- Can cars be detached/lost, or are they permanent once acquired?
- How visible is the train to enemies? Stealth upgrades?
- What happens if Engine is destroyed? Instant loss or recovery scenario?
- Interior customization beyond functional upgrades?
