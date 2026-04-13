# Off The Rails — Game Design Document

Master reference document. Start here to understand the game and find detailed specifications.

<!-- This document is a navigation index. Deep content lives in linked files. -->

## 1. Vision Summary

**Pitch:** A co-op PvE expedition game where survivors restore a derelict train into a mobile home and battle platform, crossing the overgrown ruins of a rail-built colony world to scavenge, upgrade, and eventually escape the planet.

**Pacing:** Barotrauma meets Project Zomboid on rails.

**Players:** 2-8 co-op

**Full vision:** [vision.md](vision.md)

## 2. Core Loop

### Moment-to-Moment
- Move through hostile ruins
- Search for salvage, fuel, supplies, components
- Avoid or fight enemies
- Solve environmental problems
- Use profession-specific tools and abilities
- Decide whether to push deeper or return

### Expedition Loop
1. Arrive at destination or blocked track segment
2. Assess local conditions and modifiers
3. Choose objective priority
4. Explore, scavenge, fight, solve hazards
5. Recover resources, survivors, intel, or critical parts
6. Return to train before escalation overwhelms
7. Repair, upgrade, craft, select next route

### Campaign Loop
1. Restore basic train function
2. Unlock additional cars and systems
3. Explore deeper branches of the rail network
4. Recover specialists and rare components
5. Repair critical infrastructure and ship systems
6. Construct or assemble launch-capable spacecraft
7. Escape the planet

**Diagram:** [diagrams/core-loop.md](diagrams/core-loop.md)

## 3. The Train

The train is the central hub, base, progression vehicle, and campaign status display.

### Role
- Mobile home base
- Workshop, infirmary, armory, storage
- Visual representation of campaign progress
- Emotional anchor for the crew

### Progression States
1. Wrecked shelter
2. Functional transport
3. Sustainable mobile base
4. Fortified expedition platform
5. Advanced long-range command train
6. Endgame support carrier

### References
- **System doc:** [systems/train.md](systems/train.md)
- **Car definitions:** [data/train-cars.yaml](data/train-cars.yaml)
- **Upgrade tree:** [data/upgrades.yaml](data/upgrades.yaml)

## 4. Expeditions

Players leave the train, enter dangerous zones, complete objectives, and extract before threat escalation overwhelms them.

### Destination Archetypes
- Small town
- Rail station / depot
- Freight yard
- Industrial facility
- Research / medical sector
- Agricultural dome
- Tunnel / underground maintenance
- Crash site / debris field
- Survivor enclave

### Objective Types
- Recover fuel
- Retrieve specific part
- Rescue survivor
- Restore local power
- Clear blocked route
- Secure cargo cache
- Scan / analyze anomaly
- Reactivate switchyard
- Eliminate threat source
- Escort payload to train

### References
- **System doc:** [systems/expeditions.md](systems/expeditions.md)
- **Location data:** [data/locations.yaml](data/locations.yaml)

## 5. Professions

Each player profession changes how the team solves problems, improves efficiency, and opens tactical options.

### Design Philosophy
- Roles unlock options and efficiencies, not hard-lock progression
- Small crews can function with gaps — design for overlap
- Synergy between roles, not dependency

### Role Count
6-8 professions for MVP

### References
- **System doc:** [systems/professions.md](systems/professions.md)
- **Role definitions:** [data/professions.yaml](data/professions.yaml)

## 6. Threats & Enemies

### Escalation Model
Threat escalates by:
- Time spent in area
- Noise and combat
- Opening sealed spaces
- Triggering alarms or power surges
- Carrying special objects
- Failing stealth or safety checks

### Enemy Role Categories
- Swarmers / rushers
- Ambushers / stalkers
- Tough frontline blockers
- Ranged pressure enemies
- Support / nest / buffer units
- Elites / mini-bosses
- Location guardians

### Faction
MVP: 1 enemy faction with variants

## 7. Resources & Economy

### Resource Categories

**Common (expedition drops):**
- Scrap, wiring, chemicals, fuel, fabric/seals, basic meds

**Structured (upgrades):**
- Machine parts, relays, power cores, refined alloys, optical components, medical stock

**Campaign milestone:**
- Engine assemblies, navigation systems, launch hardware, prototype components, rare schematics

### References
- **Resource catalog:** [data/resources.yaml](data/resources.yaml)

## 8. Crafting

### Design Principle
Favor industrial salvage crafting over primitive survival crafting.

### Crafting Categories
- Consumables
- Ammo
- Medical items
- Repair kits
- Tools
- Train upgrade parts
- Mission gear

### References
- **System doc:** [systems/crafting.md](systems/crafting.md)
- **Recipe data:** [data/recipes.yaml](data/recipes.yaml)

## 9. Train Upgrades

### Structure
Each train car has upgrade tiers with dependencies and resource costs.

### References
- **Upgrade tree:** [data/upgrades.yaml](data/upgrades.yaml)

## 10. Route Progression

The rail map acts as the strategic campaign layer.

### Node Types
- Destination nodes
- Junction nodes
- Blocked route nodes
- Hazard nodes
- Survivor nodes
- Landmark nodes
- Story nodes
- Endgame nodes

### Strategic Decisions
- Safe route with lower-value loot
- Dangerous route with rare components
- Detour to rescue a specialist
- Shortcut with heavy train damage risk
- Longer route with better supply access

### References
- **System doc:** [systems/progression.md](systems/progression.md)

## 11. Campaign Arc

### Beginning
Survivors stranded with wrecked train. Basic shelter only.

### Milestones
- Train becomes mobile
- First major route unlocked
- Specialist crew assembled
- Critical ship components recovered
- Launch site reached

### Endgame
Construct or repair spacecraft. Escape the planet.

## 12. Open Questions Index

Consolidated from all design docs:

### Vision
- How does difficulty scale with player count?
- What's the solo play story?
- How long is a full campaign?

### Train
- (To be added as train.md is written)

### Expeditions
- (To be added as expeditions.md is written)

### Professions
- (To be added as professions.md is written)

<!-- Update this index as open questions are added to individual docs -->
