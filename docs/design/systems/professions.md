# Profession System

Professions define what each player specializes in — both aboard the train and during expeditions. They create synergy and efficiency, not hard gates.

<!-- refs: data/professions.yaml -->

## Design Philosophy

1. **Options, not gates** — A crew without a Medic can still heal (slowly, crudely). Professions make things *better*, not *possible*.
2. **Train + field roles** — Every profession has value both aboard the train and during expeditions
3. **Scaling coverage** — Small crews have gaps to manage; full crews specialize deeply
4. **Synergy over dependency** — Roles complement each other without creating bottlenecks

## Professions Overview

| Profession | Focus | Primary Car |
|------------|-------|-------------|
| Engineer | Train systems, power, repairs | Engine |
| Medic | Healing, status treatment, triage | Infirmary |
| Scavenger | Loot detection, carry capacity, extraction | Cargo |
| Security | Combat, defense, threat management | Armory |
| Signal Tech | Navigation, comms, intel, route planning | Signal/Command |
| Machinist | Crafting, fabrication, upgrades | Workshop |
| Botanist | Greenhouse, sustainability, consumables | Greenhouse |
| Researcher | Lab, schematics, prototype tech | Lab |

## Profession Details

### Engineer

The train's lifeline. Keeps systems running, power flowing, and breakdowns from becoming disasters.

**Active Abilities:**
- Emergency Repair — Fast fix under pressure, temporary but immediate
- Power Reroute — Redirect power from non-critical to critical systems
- System Overclock — Boost a subsystem temporarily at risk of damage

**Passive Bonuses:**
- 25% faster repair speed
- 15% reduced material cost for repairs
- Early warning on system failures

**Train Station:** Engine car

**Field Role:** Restore local power systems, bypass electronic security, salvage machinery for parts, assess structural integrity

---

### Medic

Keeps the crew alive. Handles everything from minor injuries to emergency surgery.

**Active Abilities:**
- Field Surgery — Perform complex medical procedures outside infirmary
- Stabilize — Prevent downed player from dying, buying time for extraction
- Purge — Remove status effects (poison, infection, radiation)

**Passive Bonuses:**
- 30% faster healing rate
- 20% reduced medical supply consumption
- Diagnose conditions faster

**Train Station:** Infirmary car

**Field Role:** Revive downed players, cure afflictions in the field, make triage decisions, identify medical hazards

---

### Scavenger

The expedition's eyes and hands. Finds what others miss and carries more back.

**Active Abilities:**
- Loot Sense — Highlight nearby items and containers through walls
- Efficient Packing — Reorganize inventory for bonus capacity
- Quick Grab — Faster looting animation, grab while moving

**Passive Bonuses:**
- 40% increased carry capacity
- Better quality rolls on loot tables
- Detect hidden containers

**Train Station:** Cargo car

**Field Role:** Find hidden caches, optimize team loot distribution, lead extraction with full packs, appraise item value quickly

---

### Security

Combat specialist and threat manager. Protects the team and controls engagements.

**Active Abilities:**
- Suppression Fire — Pin enemies, reduce their accuracy and aggression
- Defensive Stance — Damage reduction and threat draw
- Threat Tag — Mark priority targets for team focus

**Passive Bonuses:**
- 15% weapon handling improvement
- 10% reduced ammo consumption
- Faster threat identification

**Train Station:** Armory car

**Field Role:** Point defense during looting, crowd control in engagements, combat leadership, protect vulnerable team members

---

### Signal Tech

Information warfare and navigation. Knows where to go and what's coming.

**Active Abilities:**
- Area Scan — Reveal enemies, items, and hazards in radius
- Comms Intercept — Gather intel from enemy communications
- Route Override — Unlock blocked paths or alternate routes

**Passive Bonuses:**
- Better destination intel before arrival
- Advance warning on route hazards
- Faster terminal interaction

**Train Station:** Signal/Command car

**Field Role:** Hack terminals, disable alarm systems, call for emergency extraction, coordinate team positioning

---

### Machinist

The maker. Builds what the team needs, when they need it.

**Active Abilities:**
- Field Fabrication — Craft basic items without workshop
- Jury-Rig — Create temporary solutions from available materials
- Upgrade Installation — Install upgrades faster with bonus effects

**Passive Bonuses:**
- 25% faster crafting speed
- 15% reduced material costs for crafting
- Unlock advanced recipe variants

**Train Station:** Workshop car

**Field Role:** Craft consumables during expedition, repair tools mid-mission, assess salvage potential, improvise solutions

---

### Botanist

Sustainability specialist. Keeps the train fed and stocked for long campaigns.

**Active Abilities:**
- Harvest Optimization — Extract maximum yield from plant sources
- Medicinal Preparation — Create remedies from harvested plants
- Crop Boost — Accelerate greenhouse growth temporarily

**Passive Bonuses:**
- 30% increased yield from plants
- Food and medicine last 20% longer
- Identify plant properties instantly

**Train Station:** Greenhouse car

**Field Role:** Identify edible and useful plants, harvest samples for cultivation, create natural remedies, assess environmental toxicity

---

### Researcher

The endgame specialist. Unlocks advanced technology and understands the unknown.

**Active Abilities:**
- Schematic Analysis — Unlock new recipes from found schematics
- Anomaly Scan — Identify and analyze unknown phenomena
- Prototype Activation — Use experimental tech safely

**Passive Bonuses:**
- 40% faster research speed
- Unlock advanced tech tree branches
- Better yields from analysis

**Train Station:** Lab car

**Field Role:** Analyze artifacts and anomalies, identify unknown threats, collect research samples, interface with alien/advanced technology

## Crew Scaling

### Coverage by Crew Size

| Size | Professions | Gap Strategy |
|------|-------------|--------------|
| 2 | 2 of 8 | Heavy cross-training, automation, careful planning |
| 3 | 3 of 8 | Strategic role selection, some cross-training |
| 4 | 4 of 8 | Balanced coverage, manageable gaps |
| 5 | 5 of 8 | Minor gaps, overlap handles most situations |
| 6 | 6 of 8 | Near-full coverage, light specialization |
| 7 | 7 of 8 | One gap, easily managed |
| 8 | 8 of 8 | Full coverage, maximum specialization |

### Cross-Training

Players can learn basic abilities from other professions:
- Requires time and resources to learn
- Basic versions are slower/costlier than specialist versions
- Full abilities remain profession-locked
- Creates meaningful progression for experienced players

### Recommended Minimum Coverage

For viable expeditions, prioritize:
1. **Security OR Engineer** — Combat or problem-solving
2. **Medic** — Someone needs to keep people alive
3. **Scavenger OR Signal Tech** — Finding things or knowing where to go

## Profession Synergies

Strong combinations that multiply effectiveness:

| Combo | Synergy |
|-------|---------|
| Engineer + Machinist | Repair and build anything |
| Medic + Botanist | Medical self-sufficiency |
| Scavenger + Signal Tech | Find everything, miss nothing |
| Security + Engineer | Combat and field problem-solving |
| Researcher + Signal Tech | Information dominance |
| Machinist + Researcher | Craft advanced prototypes |

## Open Questions

- Can players change profession mid-campaign, or is it locked at start?
- Profession-specific equipment, or shared gear with profession bonuses?
- NPC specialists — can rescued survivors fill profession roles?
- Progression within profession — skill trees or flat abilities?
- Dual-classing — can a player have a secondary profession at reduced effectiveness?
