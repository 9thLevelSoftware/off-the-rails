# Phase 5: Professions — Context

## Phase Goal

Implement 2-3 distinct professions (Engineer, Medic) with abilities and passive bonuses, including train station assignment and basic profession selection flow.

## Requirements

**R4**: 2-3 professions with distinct abilities and train station roles

## Success Criteria

- [ ] Engineer profession with 3 abilities + passives
- [ ] Medic profession with 3 abilities + passives
- [ ] Profession selection at game start
- [ ] Abilities trigger correctly with cooldowns
- [ ] Passive bonuses apply (repair speed, healing rate)
- [ ] Train station assignment per profession

## Existing Assets

### From Phase 2
- `src/player/player.gd` — CharacterBody3D with WASD movement, mouse look
- `src/player/player.tscn` — Player scene with CameraMount

### From Phase 3
- `src/train/subsystems/power_source.gd` — Subsystem pattern (state machine with signals)
- `src/train/interaction/interaction_controller.gd` — Interaction system with priority routing
- `src/train/cars/car_data.gd` — Resource pattern for car definitions
- Train cars: Engine, Workshop with subsystems

### From Phase 4
- `src/expedition/escalation/escalation_manager.gd` — Manager node pattern with signals
- `src/expedition/loot/loot_container.gd` — Interactable extension pattern

### Core Systems
- `src/autoloads/game_state.gd` — Session lifecycle, scene transitions
- Build pipeline: `tools/build_data.py` (YAML → .tres)

### Design Documentation
- `docs/design/systems/professions.md` — Full profession spec (8 professions)
- `docs/design/data/professions.yaml` — Profession data definitions

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data layer | Wrapper classes over existing ProfessionData | Preserves existing .tres files, adds type safety |
| Ability system | Node-based AbilityManager with AbilityData wrappers | Uses typed data with parsed cooldowns |
| Cooldowns | Float seconds via ProfessionUtils.parse_cooldown() | Converts "120s" → 120.0 at load time |
| Passive bonuses | Static mapping table (PassiveBonusMapping) | Explicit string → struct conversion |
| Station assignment | Reuse ProfessionData.can_work_at() | Already exists, don't duplicate |
| Effect routing | Direct method call + signals | AbilityManager → AbilityEffects.execute_ability() |

## CRITICAL: Existing Code to Preserve

| Asset | Location | Status |
|-------|----------|--------|
| ProfessionData | src/data/types/profession_data.gd | DO NOT MODIFY |
| Profession .tres files | src/data/professions/*.tres | DO NOT REGENERATE |
| TrainCar.car_id | src/train/cars/train_car.gd | Use directly, not car_data.id |
| ProfessionData.can_work_at() | Line 48 | Reuse for station assignment |

## V1 Scope Boundaries

**In Scope:**
- Engineer and Medic professions (2 of 8)
- 3 abilities per profession with cooldowns
- Passive bonuses (repair speed, healing rate, material costs)
- Train station assignment (static mapping)
- Basic profession selection (startup or command)

**Out of Scope (V2+):**
- Remaining 6 professions (Scavenger, Security, Signal Tech, Machinist, Botanist, Researcher)
- Cross-training system
- Profession-specific equipment
- NPC specialists
- Skill trees / progression within profession
- Dual-classing

## Plan Structure

| Plan | Wave | Name | Dependencies |
|------|------|------|--------------|
| 05-01 | 1 | Profession Data Architecture | None |
| 05-02 | 2 | Ability System Implementation | 05-01 |
| 05-03 | 3 | Passive Bonuses & Selection | 05-01, 05-02 |

## Cross-Phase Dependencies

- **Phase 3 → Phase 5**: Subsystem pattern, car definitions, interaction system
- **Phase 4 → Phase 5**: Manager node pattern, signal-based triggers
- **Phase 5 → Phase 6**: Profession passives affect crafting speed/costs (Machinist)
- **Phase 5 → Phase 7**: Ability UI, profession display in HUD

## Risk Areas

| Risk | Mitigation |
|------|------------|
| Ability effects need systems that don't exist yet | Stub effect handlers, emit signals for future |
| Passive bonus timing (when to apply) | Apply on profession assignment, recalculate on change |
| Cooldown sync issues if time scale changes | Use Engine.get_process_delta not wall clock |
| Station assignment with missing cars | Graceful fallback, warn if car not found |

## Codebase Conventions (from CODEBASE.md)

- GDScript for all gameplay code
- class_name declarations for reusable classes
- Signals for cross-system communication
- Two-phase initialization (create then wire) for complex dependencies
- Groups for node discovery ("player", "train_car", "interactable")

---
*Generated: 2026-04-13*
