# Off The Rails V2 — Roadmap

## Phases

- [ ] **Phase 1: Isometric Foundation** — Tilemap, camera, basic rendering
- [ ] **Phase 2: Player & Movement** — Isometric character controller
- [ ] **Phase 3: Train Car Prototype** — Workshop in isometric with spatial layout
- [ ] **Phase 4: Interaction System** — Spatial approach + interact
- [ ] **Phase 5: Mod Architecture** — Data-driven content, mod loading
- [ ] **Phase 6: V1 Logic Port** — GameState, crafting, signals
- [ ] **Phase 7: Integration** — Wire systems, playable prototype

## Phase Details

### Phase 1: Isometric Foundation
**Goal**: Establish isometric rendering infrastructure in Godot

**Requirements**: R1, R2

**Recommended Agents**:
- Godot Developer (isometric tilemap setup)
- Senior Developer (architecture patterns)

**Success Criteria**:
- [ ] Isometric TileMap configured (64x32 tile size, 2:1 ratio)
- [ ] Y-sorting enabled and working correctly
- [ ] Camera follows a test object smoothly
- [ ] Basic floor tileset renders without visual artifacts
- [ ] Collision shapes align with isometric tiles

**Plans**: 2

---

### Phase 2: Player & Movement
**Goal**: Isometric character with natural-feeling movement

**Requirements**: R3

**Recommended Agents**:
- Godot Developer (character controller)
- Frontend Developer (input handling)

**Success Criteria**:
- [ ] CharacterBody2D with isometric movement
- [ ] WASD converts to isometric directions correctly
- [ ] 4-direction sprite animation (idle + walk)
- [ ] Y-sort positions player correctly relative to objects
- [ ] Movement feels responsive and natural

**Plans**: 2

---

### Phase 3: Train Car Prototype
**Goal**: One train car (Workshop) with spatial floor layout

**Requirements**: R4

**Recommended Agents**:
- Godot Developer (scene composition)
- UI Designer (spatial layout)
- Senior Developer (architecture)

**Success Criteria**:
- [ ] Workshop car as isometric tilemap scene
- [ ] 3-4 equipment objects placed spatially (workbench, locker, crate)
- [ ] Player can walk around objects (not through)
- [ ] Clear visual distinction between floor, walls, equipment
- [ ] Car feels like a real space, not a flat corridor

**Plans**: 2

---

### Phase 4: Interaction System
**Goal**: Spatial approach-and-interact for isometric perspective

**Requirements**: R5

**Recommended Agents**:
- Godot Developer (interaction detection)
- Senior Developer (system design)

**Success Criteria**:
- [ ] Interactable base class for equipment
- [ ] Proximity detection in isometric space
- [ ] Visual prompt when in range ("Press E")
- [ ] Interaction triggers feedback (placeholder for now)
- [ ] Works correctly with Y-sorting (prompt above objects)

**Plans**: 2

---

### Phase 5: Mod Architecture
**Goal**: Data-driven content system with mod loading

**Requirements**: R6, R7, R8, R9, R10

**Recommended Agents**:
- Senior Developer (mod system architecture)
- Backend Architect (data loading, validation)
- Godot Developer (Godot-specific integration)
- Technical Writer (mod API documentation)

**Success Criteria**:
- [ ] All base game content in data files (not hardcoded)
- [ ] ModLoader autoload discovers mods in user://mods/
- [ ] mod.json manifest format defined and validated
- [ ] Content registry merges base + mod data at runtime
- [ ] Example mod adds one custom item successfully
- [ ] Mod loading errors handled gracefully (don't crash)
- [ ] Basic scripting API exposes key systems

**Plans**: 4

---

### Phase 6: V1 Logic Port
**Goal**: Bring forward working V1 systems adapted for isometric

**Requirements**: R11, R12, R13, R14

**Recommended Agents**:
- Senior Developer (architecture adaptation)
- Godot Developer (implementation)

**Success Criteria**:
- [ ] GameState autoload ported and functional
- [ ] Crafting domain logic (CraftJob, CraftQueue, RecipeValidator) ported
- [ ] YAML → .tres pipeline works for V2 data
- [ ] Signal architecture preserved
- [ ] Inventory API functional
- [ ] No regression from V1 logic behavior

**Plans**: 3

---

### Phase 7: Integration
**Goal**: Wire all systems into playable prototype

**Requirements**: All V2 requirements verified together

**Recommended Agents**:
- Senior Developer (system integration)
- QA Verification Specialist (testing)
- Godot Developer (scene wiring)

**Success Criteria**:
- [ ] Player can walk around Workshop car
- [ ] Player can interact with workbench (opens crafting)
- [ ] Crafting queue functional
- [ ] At least one mod loads and adds content
- [ ] No critical bugs in prototype loop
- [ ] Foundation ready for content expansion (V2.1)

**Plans**: 2

---

## Progress

| Phase | Plans | Completed | Status |
|-------|-------|-----------|--------|
| Phase 1: Isometric Foundation | 2 | 0 | Pending |
| Phase 2: Player & Movement | 2 | 0 | Pending |
| Phase 3: Train Car Prototype | 2 | 0 | Pending |
| Phase 4: Interaction System | 2 | 0 | Pending |
| Phase 5: Mod Architecture | 4 | 0 | Pending |
| Phase 6: V1 Logic Port | 3 | 0 | Pending |
| Phase 7: Integration | 2 | 0 | Pending |
| **Total** | **17** | **0** | **0%** |

## V1 Archive

V1 (3D FPS) was completed and shipped on 2026-04-14:
- Repository: https://github.com/9thLevelSoftware/off-the-rails
- 21 plans across 7 phases
- V1 planning files archived to `.planning/archive/v1/`
