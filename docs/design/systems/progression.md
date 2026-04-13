# Campaign Progression

The campaign unfolds across five phases, each with distinct goals, challenges, and pacing. Players progress by completing milestones that unlock new train states, route branches, and capabilities.

<!-- refs: data/upgrades.yaml, data/locations.yaml, data/resources.yaml -->

## Design Principles

1. **Clear goals** — Players always know what they're working toward
2. **Earned progress** — Milestones require effort, not just time
3. **Rising stakes** — Each phase increases challenge and reward
4. **Player-driven pace** — Side content available but not required
5. **Visible progress** — Train state reflects campaign advancement

## Campaign Overview

| Phase | Train State | Sessions | Focus |
|-------|-------------|----------|-------|
| **1. Survival** | Wreck → Limping | 2-4 | Get mobile, establish basics |
| **2. Expansion** | Limping → Functional | 4-6 | Add cars, build routines |
| **3. Exploration** | Functional → Fortified | 6-8 | Unlock routes, recruit specialists |
| **4. Preparation** | Fortified → Command | 4-6 | Gather launch components |
| **5. Endgame** | Command | 2-3 | Final push, escape the planet |

**Total estimated campaign:** 18-27 sessions (~30-50 hours)

---

## Phase 1: Survival

### Starting Condition
- Train wrecked, immobile
- 2-3 cars barely functional (Engine, Cargo, Bunks)
- Limited supplies
- Immediate area only accessible

### Goals
1. Repair Engine to minimal function
2. Secure basic supplies (food, water, meds)
3. Establish Workshop capability
4. Complete first expedition
5. Reach first route node

### Available Content
- **Locations:** Immediate wreck site, 1-2 nearby nodes (Small Town, Rail Station)
- **Enemies:** Low-tier only (swarmers, basic ambushers)
- **Crafting:** Basic recipes only
- **Train:** Engine (T1), Cargo (T1), Bunks (T1), Workshop (T1)

### Milestone Gate: Survival → Expansion
- [ ] Engine repaired (Patched Locomotion)
- [ ] Workshop online (Basic Workbench)
- [ ] First route completed (reached second node)
- [ ] Basic supplies secured (not starving)

### Pacing Notes
- Tutorial content — teach core mechanics
- Low pressure — escalation is forgiving
- Quick wins — progress should feel rapid
- Establishes the loop before adding complexity

---

## Phase 2: Expansion

### Starting Condition
- Train mobile but fragile
- Core cars functional
- Basic route access
- Crew still small/vulnerable

### Goals
1. Recover additional train cars (Infirmary, Armory, Signal)
2. Upgrade core systems to T2
3. Establish sustainable supply chain
4. Reach first major junction
5. Recruit first specialist (optional)

### Available Content
- **Locations:** Expanded network (Freight Yard, Industrial Facility, Agricultural Dome)
- **Enemies:** Medium-tier introduced (blockers, ranged)
- **Crafting:** Intermediate recipes, schematic unlocks begin
- **Train:** 5-7 cars, T1-T2 upgrades

### New Systems Unlocked
- Infirmary healing and status treatment
- Armory weapon maintenance and ammo crafting
- Signal route intel and hazard warnings
- Refinery fuel processing

### Milestone Gate: Expansion → Exploration
- [ ] 6+ train cars online
- [ ] Signal/Command functional (Comms Array)
- [ ] First junction reached
- [ ] Sustainable supply flow established

### Pacing Notes
- Core systems come online — more options
- Crafting becomes meaningful
- Routes offer meaningful choices
- Challenge ramps gradually

---

## Phase 3: Exploration

### Starting Condition
- Train functional and stable
- Multiple route branches available
- Core crew assembled
- Ready for serious expeditions

### Goals
1. Explore all accessible route branches
2. Recover Navigation Module
3. Recruit 2+ specialists
4. Unlock path to launch site
5. Upgrade critical systems to T3

### Available Content
- **Locations:** Full variety including Research Sector, Tunnel, Survivor Enclave
- **Enemies:** High-tier introduced (elites, stalkers, guardians)
- **Crafting:** Advanced recipes, research unlocks begin
- **Train:** All 10 cars available, T2-T3 upgrades

### New Systems Unlocked
- Greenhouse sustainability
- Lab research and prototypes
- Specialist recruitment
- Route authorization (locked branches)

### Milestone Gate: Exploration → Preparation
- [ ] Navigation Module recovered
- [ ] 2+ specialists recruited
- [ ] Path to launch site identified
- [ ] Lab online (Research Station)

### Pacing Notes
- Player agency peaks — many viable paths
- Difficulty varies by route choice
- Side content vs. main progression balance
- Specialists provide tangible benefits

---

## Phase 4: Preparation

### Starting Condition
- Train fully capable
- Launch site location known
- Missing critical components
- High-value targets identified

### Goals
1. Recover all Launch Hardware components
2. Recover Engine Assembly (if not already)
3. Upgrade train to Command state
4. Clear path to launch site
5. Prepare for final expedition

### Available Content
- **Locations:** Crash Sites, deep-territory nodes, high-risk zones
- **Enemies:** Full roster including very high threat
- **Crafting:** All recipes potentially available
- **Train:** All cars, T3-T4 upgrades

### Launch Components Required
| Component | Location | Challenge |
|-----------|----------|-----------|
| Launch Hardware #1 | Crash Site Alpha | Very High |
| Launch Hardware #2 | Research Sector Deep | High + Radiation |
| Launch Hardware #3 | Freight Yard Omega | High + Escort |
| Engine Assembly | Industrial Complex | High |
| Navigation Module | Signal Tower | Medium-High |

### Milestone Gate: Preparation → Endgame
- [ ] All Launch Hardware recovered (3 pieces)
- [ ] Engine Assembly installed
- [ ] Train at Command state
- [ ] Launch site route cleared

### Pacing Notes
- Focused objectives — clear shopping list
- High-stakes expeditions
- Resource management critical
- Crew at peak capability

---

## Phase 5: Endgame

### Starting Condition
- All components gathered
- Train fully upgraded
- Launch site accessible
- Final challenge awaits

### Goals
1. Travel to launch site
2. Secure the site
3. Assemble/repair the spacecraft
4. Defend during launch preparation
5. Escape the planet

### Endgame Structure

**Stage 1: Journey**
- Navigate to launch site (may require multiple sessions)
- Route is dangerous — constant pressure
- Train may take significant damage

**Stage 2: Arrival**
- Secure launch site perimeter
- Clear immediate threats
- Establish defensive positions

**Stage 3: Assembly**
- Transport components from train to ship
- Assemble spacecraft (timed phases)
- Defend against waves while working

**Stage 4: Launch**
- Final defense wave
- Launch sequence
- Escape cutscene / ending

### Ending Variations
| Outcome | Condition |
|---------|-----------|
| **Full Escape** | All surviving crew escapes |
| **Partial Escape** | Some crew left behind (sacrifice play) |
| **Pyrrhic Victory** | Escape with heavy losses |
| **Failure** | Train destroyed or all crew dead |

### Pacing Notes
- Climactic and intense
- No grinding — use what you have
- Meaningful sacrifice choices possible
- Clear victory condition

---

## Route Map Structure

### Map Layout

```
                         [STARTING WRECK]
                               │
                        ┌──────┴──────┐
                        │  Tutorial   │
                        │    Zone     │
                        └──────┬──────┘
                               │
                    ┌──────────┼──────────┐
                    │          │          │
              [Small Town]  [Rail      [Freight
               (supplies)   Station]    Yard]
                    │          │          │
                    └──────────┼──────────┘
                               │
                        ┌──────┴──────┐
                        │    FIRST    │
                        │   JUNCTION  │
                        └──────┬──────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    [Branch A]          [Branch B]          [Branch C]
    (Safe Route)        (Risky Route)       (Unknown)
           │                   │                   │
    ┌──────┴──────┐     ┌──────┴──────┐     ┌──────┴──────┐
    │Agricultural │     │Industrial  │     │ Research   │
    │   Domes     │     │  Complex   │     │  Sector    │
    └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
           │                   │                   │
           └───────────────────┼───────────────────┘
                               │
                        ┌──────┴──────┐
                        │     HUB     │
                        │   STATION   │
                        └──────┬──────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    [Survivor       [Deep            [Crash
     Enclave]       Tunnels]          Sites]
           │                   │                   │
           │            ┌──────┴──────┐            │
           │            │  BLOCKED    │            │
           │            │   ROUTE     │◄─── Requires
           │            └──────┬──────┘     Nav Module
           │                   │                   │
           └───────────────────┼───────────────────┘
                               │
                        ┌──────┴──────┐
                        │   LAUNCH    │
                        │    SITE     │
                        └─────────────┘
```

### Route Node Types

| Type | Description | Gameplay |
|------|-------------|----------|
| **Destination** | Standard expedition location | Primary content |
| **Junction** | Route splits, player chooses path | Strategic decision |
| **Blocked** | Requires item/action to pass | Milestone gate |
| **Hazard** | Travel event, no expedition | Resource cost |
| **Survivor** | Enclave, social encounters | Trade/recruit |
| **Landmark** | Story beat, unique encounter | Narrative |
| **Endgame** | Final zone, high stakes | Climax |

### Route Strategy

Players must choose between:

| Route Type | Pros | Cons |
|------------|------|------|
| **Safe Routes** | Lower risk, reliable supplies | Slower progress, common loot |
| **Risky Routes** | Rare components, shortcuts | High danger, potential losses |
| **Detours** | Specialists, unique items | Time cost, fuel consumption |
| **Shortcuts** | Faster progress | Heavy damage risk, no loot |

---

## Difficulty Scaling

### By Phase

| Phase | Enemy Density | Elite Chance | Escalation Rate |
|-------|---------------|--------------|-----------------|
| Survival | Low | 5% | Slow |
| Expansion | Medium | 15% | Moderate |
| Exploration | Medium-High | 25% | Moderate-Fast |
| Preparation | High | 35% | Fast |
| Endgame | Very High | 50% | Constant |

### By Player Count

| Players | Enemy Scaling | Loot Scaling | Objective Scaling |
|---------|---------------|--------------|-------------------|
| 2 | 60% | 80% | Single objectives |
| 4 | 100% (baseline) | 100% | Standard |
| 6 | 130% | 115% | Additional objectives |
| 8 | 160% | 130% | Complex objectives |

### Dynamic Difficulty

Optional modifiers based on performance:
- Struggling crews get slightly easier escalation
- Dominant crews face tougher variants
- Never removes player agency or meaningful challenge

---

## Specialist Recruitment

### Available Specialists

NPCs that can be recruited to fill profession roles or provide bonuses.

| Specialist | Location | Recruitment |
|------------|----------|-------------|
| Veteran Engineer | Survivor Enclave A | Trade + Quest |
| Field Medic | Research Sector | Rescue mission |
| Salvage Expert | Freight Yard | Hire (resources) |
| Security Chief | Industrial Complex | Rescue + Trust |
| Comm Officer | Signal Tower | Repair quest |
| Master Machinist | Survivor Enclave B | Trade + Quest |
| Botanist | Agricultural Dome | Rescue mission |
| Researcher | Crash Site | Rescue + Resources |

### Specialist Benefits
- Can man train stations while players expedition
- Provide passive bonuses in their specialty
- Can join expeditions (AI-controlled)
- Unlock unique dialogue and quests

---

## Campaign Variants

### Standard Campaign
- Full progression as described
- 20-30 hours
- Recommended for first playthrough

### Short Campaign
- Reduced milestone requirements
- Fewer required components
- Compressed route map
- 10-15 hours

### Endless Mode
- No escape objective
- Procedural route generation
- Escalating challenge
- Leaderboard/scoring focus

### New Game+
- Keep some upgrades/schematics
- Harder enemies from start
- New route variants
- Additional story content

---

## Open Questions

- How much player choice in route order vs. gated progression?
- Can players backtrack to earlier areas, and if so, do they reset?
- How are specialists handled if player dies and specialist was filling that role?
- What's the failure state? Total loss, or can you recover from near-death?
- Should there be mid-campaign difficulty adjustment options?
- How do saves work? Per-session? Persistent campaign?
