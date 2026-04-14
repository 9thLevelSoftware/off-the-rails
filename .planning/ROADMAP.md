# Off The Rails — Roadmap

## Phases

- [ ] **Phase 1: Foundation** — Project structure, data pipeline, core autoloads
- [x] **Phase 2: Player & Movement** — Player character, camera, basic controls
- [x] **Phase 3: Train Core** — Train scene, Engine car, Workshop car, interaction
- [x] **Phase 4: Expedition Core** — Expedition scene, escalation, extraction
- [ ] **Phase 5: Professions** — 2-3 professions with abilities and bonuses
- [ ] **Phase 6: Crafting** — Workshop station, queue system, basic recipes
- [ ] **Phase 7: Integration** — System connections, basic UI, playtest loop

## Phase Details

### Phase 1: Foundation
**Goal**: Establish project structure and development infrastructure

**Requirements**: R6, R7, R8, R10

**Recommended Agents**:
- Godot Developer (scene/script scaffolding)
- Senior Developer (architecture implementation)
- DevOps Automator (build scripts)

**Success Criteria**:
- [ ] Directory structure matches architectural sketch
- [ ] YAML → .tres build script runs successfully
- [ ] GameState autoload configured and functional
- [ ] Main scene with additive scene loading works
- [ ] MCP tools can create/modify scenes

**Plans**: 2-3

---

### Phase 2: Player & Movement
**Goal**: Playable character with smooth movement and camera

**Requirements**: R1 (foundation for single-player)

**Recommended Agents**:
- Godot Developer (character controller)
- Frontend Developer (input handling)
- QA Verification Specialist (movement feel)

**Success Criteria**:
- [ ] Player character moves with WASD + mouse
- [ ] Camera follows player appropriately
- [ ] Player can transition between Train and Expedition scenes
- [ ] Basic collision and physics work with Jolt

**Plans**: 2

---

### Phase 3: Train Core
**Goal**: Functional train hub with 2-3 interactable cars

**Requirements**: R2

**Recommended Agents**:
- Godot Developer (train scenes, car scripts)
- Senior Developer (subsystem architecture)
- UI Designer (interaction prompts)
- QA Verification Specialist (interaction testing)

**Success Criteria**:
- [ ] Train scene with Engine and Workshop cars
- [ ] Player can enter/exit train
- [ ] Basic subsystem states (Offline, Operational)
- [ ] Car-specific interactions work
- [ ] Visual representation of train state

**Plans**: 3

---

### Phase 4: Expedition Core
**Goal**: Complete expedition loop with escalation and extraction

**Requirements**: R3

**Recommended Agents**:
- Godot Developer (expedition scenes, escalation)
- Senior Developer (escalation algorithm)
- Godot Developer (enemy spawning)
- QA Verification Specialist (escalation balance)

**Success Criteria**:
- [ ] Expedition scene loads additively with train
- [ ] Escalation meter increases over time and with actions
- [ ] Threshold effects (patrol increase, reinforcements)
- [ ] Extraction triggers return to train
- [ ] Basic enemy presence (placeholder)
- [ ] Loot containers with basic items

**Plans**: 4

---

### Phase 5: Professions
**Goal**: 2-3 distinct professions with abilities

**Requirements**: R4

**Recommended Agents**:
- Godot Developer (profession system)
- Senior Developer (ability architecture)
- UI Designer (profession selection, ability UI)
- QA Verification Specialist (ability testing)

**Success Criteria**:
- [ ] Engineer profession with 3 abilities + passives
- [ ] Medic profession with 3 abilities + passives
- [ ] Profession selection at game start
- [ ] Abilities trigger correctly with cooldowns
- [ ] Passive bonuses apply (repair speed, healing rate)
- [ ] Train station assignment per profession

**Plans**: 3

---

### Phase 6: Crafting
**Goal**: Functional workshop with queue-based crafting

**Requirements**: R5

**Recommended Agents**:
- Godot Developer (crafting system)
- Senior Developer (queue architecture)
- UI Designer (crafting UI)
- QA Verification Specialist (recipe testing)

**Success Criteria**:
- [ ] Workshop station interaction
- [ ] Recipe selection UI
- [ ] Queue system with time progression
- [ ] 5-10 basic recipes functional
- [ ] Resource consumption and output
- [ ] Crafting continues during expedition (train-side)

**Plans**: 3

---

### Phase 7: Integration
**Goal**: All systems connected, playable loop, basic UI

**Requirements**: All V1 requirements validated

**Recommended Agents**:
- Senior Developer (system integration)
- UI Designer (HUD, menus)
- QA Verification Specialist (full loop testing)
- Frontend Developer (polish, feedback)

**Success Criteria**:
- [ ] Complete loop: Train → Expedition → Extract → Train
- [ ] Profession abilities work during expedition
- [ ] Crafted items usable during expedition
- [ ] Basic HUD (health, escalation, inventory)
- [ ] Main menu and pause
- [ ] No critical bugs in core loop

**Plans**: 3

---

## Progress

| Phase | Plans | Completed | Status |
|-------|-------|-----------|--------|
| Phase 1: Foundation | 3 | 3 | Verified |
| Phase 2: Player & Movement | 2 | 2 | Verified |
| Phase 3: Train Core | 3 | 3 | Verified |
| Phase 4: Expedition Core | 4 | 4 | Verified |
| Phase 5: Professions | 3 | 3 | Verified |
| Phase 6: Crafting | 3 | 0 | Not Started |
| Phase 7: Integration | 3 | 0 | Not Started |
| **Total** | **~21** | **15** | **71%** |
