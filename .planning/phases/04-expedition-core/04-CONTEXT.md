# Phase 4: Expedition Core — Context

## Phase Goal

Complete expedition loop with escalation and extraction mechanics. Players should experience time pressure that increases threat as they explore, with clear feedback on escalation state and meaningful extraction decisions.

## Requirements

**R3**: Expedition system with escalation meter and extraction mechanics

## Success Criteria

- [ ] Expedition scene loads additively with train
- [ ] Escalation meter increases over time and with actions
- [ ] Threshold effects (patrol increase, reinforcements)
- [ ] Extraction triggers return to train
- [ ] Basic enemy presence (placeholder)
- [ ] Loot containers with basic items

## Existing Assets

### From Phase 2
- `src/expedition/expedition.tscn` — Scene with floor, PlayerSpawn, ExitTrigger
- `src/expedition/expedition.gd` — Basic script with exit trigger → train transition
- `src/autoloads/game_state.gd` — Scene transition API (transition_to_train/expedition)

### From Phase 3 (Patterns to Reuse)
- `Subsystem` class — State machine with signals (model for EscalationManager)
- `Interactable` class — Interface for interactive elements (reuse for LootContainer)
- Two-phase initialization pattern (create then wire dependencies)
- Composition pattern (container holds components)

### Design Documentation
- `docs/design/systems/expeditions.md` — Full expedition design spec
- Escalation meter: 0-100% with 5 thresholds
- Escalation profiles: time-based, noise-sensitive, etc.
- Extraction methods and pressure mechanics

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Escalation approach | Node-based manager | Matches Subsystem pattern, clear ownership |
| Threshold system | Signal-based | Decoupled, extensible for future effects |
| Loot containers | Interactable extension | Reuses proven pattern from Phase 3 |
| Enemy presence | Placeholder nodes | V1 scope — full AI deferred |
| Spawning | Threshold-triggered | Simple, testable, matches design doc |

## V1 Scope Boundaries

**In Scope:**
- Single escalation profile (time-based + action triggers)
- 5 threshold levels with signals
- Basic loot containers with item pickup
- Placeholder enemy nodes (visual only, no AI)
- Spawn rate tied to escalation level

**Out of Scope (V2+):**
- Multiple escalation profiles per location
- Procedural location generation
- Full enemy AI and combat
- Inventory system integration
- Mission objectives system

## Plan Structure

| Plan | Wave | Name | Dependencies |
|------|------|------|--------------|
| 04-01 | 1 | Escalation System Architecture | None |
| 04-02 | 2 | Escalation Triggers & Thresholds | 04-01 |
| 04-03 | 2 | Loot System | 04-01 |
| 04-04 | 3 | Enemy Presence & Integration | 04-01, 04-02, 04-03 |

## Cross-Phase Dependencies

- **Phase 2 → Phase 4**: Player movement, scene transitions, exit trigger detection
- **Phase 3 → Phase 4**: Subsystem/Interactable patterns, interaction controller
- **Phase 4 → Phase 5**: Profession abilities may modify escalation rates
- **Phase 4 → Phase 6**: Crafted items may affect loot or combat
- **Phase 4 → Phase 7**: Full loop integration, HUD for escalation display

## Risk Areas

| Risk | Mitigation |
|------|------------|
| Escalation balance feels wrong | Make rates configurable, tune in Phase 7 |
| Enemy spawning overwhelms player | Start conservative, increase via thresholds |
| Loot container interaction conflicts with Phase 3 controller | Test interaction priority early |
| Performance with many spawned nodes | Profile in Plan 04-04, set spawn limits |

---
*Generated: 2026-04-13*
