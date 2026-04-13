# Expedition System

Expeditions are the core gameplay loop. Players leave the train, enter dangerous locations, complete objectives, and extract before threat escalation overwhelms them.

<!-- refs: data/locations.yaml -->

## Design Principles

1. **Stakes matter** — Expeditions should feel risky, not routine
2. **Time pressure** — Escalation prevents infinite looting
3. **Meaningful choices** — Push deeper or extract? Split up or stay together?
4. **Role synergy** — Different professions shine in different situations
5. **Reward matches risk** — Harder locations yield better loot

## Expedition Flow

### Pre-Expedition (Train)
1. Choose destination from available route nodes
2. Review destination intel (if Signal systems upgraded)
3. Equip appropriate gear for expected conditions
4. Assign roles and responsibilities
5. Craft consumables if needed

### Travel Phase
1. Consume fuel based on distance
2. Resolve route events (if any)
3. Monitor train systems
4. Arrive at destination

### Expedition Phase
1. **Entry** — Assess situation, plan approach
2. **Exploration** — Navigate toward objectives
3. **Objectives** — Complete primary goals
4. **Looting** — Gather resources (optional depth)
5. **Extraction** — Return to train before overwhelmed

### Post-Expedition (Train)
1. Unload recovered resources
2. Treat injuries and status effects
3. Repair damaged equipment
4. Process and store materials
5. Select next destination

## Location Generation

### Hybrid Layout Model

Locations use a hybrid approach: authored key areas connected by procedural elements.

```
[Entry Zone] ─── procedural ─── [Key Area 1] ─── procedural ─── [Key Area 2]
                    │                                │
              procedural                       procedural
                    │                                │
              [Side Area]                    [Objective Zone]
```

**Authored Elements:**
- Entry zones with consistent theming
- Key areas with specific purposes (loot rooms, boss arenas, story beats)
- Objective zones where primary goals are located
- Memorable landmarks for navigation

**Procedural Elements:**
- Connecting corridors, streets, tunnels
- Side branches with optional exploration
- Enemy placement and patrol routes
- Loot container placement (within rules)
- Hazard distribution

### Benefits
- Memorable locations that players learn
- Variety prevents memorization of optimal routes
- Scalable content creation
- Replayability without losing identity

## Threat & Escalation

### Escalation Meter

Every expedition has an invisible escalation meter that increases over time and through player actions.

**Escalation Triggers:**
| Action | Escalation Increase |
|--------|---------------------|
| Time (per minute) | +1-3 (varies by location) |
| Combat noise | +5-15 per engagement |
| Loud actions (explosions, alarms) | +10-25 |
| Opening sealed areas | +5-10 |
| Carrying key items | +1/min passive |
| Failing stealth | +5-10 |

**Escalation Thresholds:**
| Level | Effect |
|-------|--------|
| 0-25% | Normal — Baseline enemy presence |
| 26-50% | Elevated — Increased patrols, faster response |
| 51-75% | High — Reinforcements arrive, aggressive behavior |
| 76-99% | Critical — Overwhelming force, extraction priority |
| 100% | Overrun — Constant assault until extraction |

### Escalation Profiles

Different locations escalate differently:

| Profile | Description | Locations |
|---------|-------------|-----------|
| **Slow Burn** | Gradual increase over 15+ min, time-based | Small Town, Agricultural Dome |
| **Noise-Sensitive** | Low baseline, spikes dramatically with combat | Research Sector, Tunnel |
| **Alarm-Based** | Stable until alarm triggered, then jumps | Industrial, Rail Station |
| **Constant Pressure** | Starts high, stays high, no safe period | Crash Site |
| **Social** | Based on player actions and reputation | Survivor Enclave |

## Mission Modifiers

Modifiers add variety and challenge to expeditions. Each location has a pool of applicable modifiers.

### Environmental Modifiers

| Modifier | Effect | Duration |
|----------|--------|----------|
| **Toxic Air** | Requires masks, exposure damages health | Entire expedition |
| **Low Visibility** | Fog/darkness, -50% detection range both ways | Entire expedition |
| **Power Outage** | No lights, doors manual, some systems offline | Entire expedition |
| **Structural Damage** | Collapse risk, blocked paths, falling debris | Entire expedition |
| **Extreme Cold** | Stamina drain, equipment malfunctions | Entire expedition |
| **Extreme Heat** | Faster fatigue, fire hazards | Entire expedition |
| **Radiation Zone** | Cumulative exposure, requires protection | Entire expedition |

### Tactical Modifiers

| Modifier | Effect | Duration |
|----------|--------|----------|
| **High Density** | +50% enemy count | Entire expedition |
| **Elite Presence** | Guaranteed elite enemy | Until killed |
| **Silent Running** | Any noise triggers max escalation | Entire expedition |
| **Hunted** | Stalker enemy pursues team | Until killed or extraction |
| **Timed** | External deadline (train under attack, etc.) | Until deadline |

### Opportunity Modifiers

| Modifier | Effect | Trade-off |
|----------|--------|-----------|
| **Salvage Rich** | +50% loot quantity | +50% enemy count |
| **Abandoned Cache** | Guaranteed rare loot | In dangerous location |
| **Survivor Signal** | Possible specialist recruitment | May be trap |
| **Fresh Crash** | Milestone components available | Very high threat |

## Objectives

### Primary Objectives

Every expedition has at least one primary objective. Completing it is the main goal.

| Objective Type | Description | Common Locations |
|----------------|-------------|------------------|
| **Recover Fuel** | Find and extract fuel supplies | Freight Yard, Industrial |
| **Retrieve Part** | Locate specific component | Any |
| **Rescue Survivor** | Find and extract a person | Survivor Enclave, Any |
| **Restore Power** | Repair local power systems | Industrial, Rail Station |
| **Clear Route** | Remove blockage for train passage | Tunnel, Rail Station |
| **Secure Cache** | Find and claim a resource stash | Any |
| **Scan Anomaly** | Analyze unknown phenomenon | Research, Crash Site |
| **Reactivate System** | Bring a facility back online | Rail Station, Signal Tower |
| **Eliminate Threat** | Destroy a nest or kill a boss | Any |
| **Escort Payload** | Move heavy item to train | Any |

### Secondary Objectives

Optional goals that provide bonus rewards.

| Objective Type | Reward |
|----------------|--------|
| **Full Survey** | Map the location completely | Intel bonus |
| **No Casualties** | Everyone extracts healthy | Morale bonus |
| **Speed Run** | Complete in under X minutes | Reputation bonus |
| **Stealth** | Complete without combat | Resource bonus |
| **Overkill** | Kill all enemies | XP/upgrade bonus |

## Extraction

### Extraction Methods

| Method | Requirements | Risk |
|--------|--------------|------|
| **Walk Out** | Clear path to entry | Must traverse entire location |
| **Emergency Signal** | Signal Tech ability | Train comes to alternate point |
| **Vehicle** | Find working vehicle | Noise, limited capacity |
| **Underground** | Tunnel access | May encounter new threats |

### Extraction Pressure

Extraction is often the most dangerous part:
- Carrying loot slows movement
- Escalation is usually high by extraction time
- Enemies may pursue to the train
- Train may be under attack when you arrive

### Failed Extraction

If a player goes down during extraction:
- Other players can carry them (very slow)
- Stabilized players can be left for later rescue
- Dead players lose equipped gear
- Team morale penalty

## Open Questions

- How does death work? Permadeath? Respawn at train? Rescue mission?
- Can you abort an expedition early and return later?
- Do locations "reset" between visits or show previous damage?
- How do stealth mechanics work in detail?
- What's the balance between authored and procedural content per location?
