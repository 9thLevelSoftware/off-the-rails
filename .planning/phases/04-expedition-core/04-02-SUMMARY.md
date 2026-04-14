# Plan 04-02 Summary: Escalation Triggers & Thresholds

## Status: Complete

## Files Modified
- `src/expedition/escalation/escalation_manager.gd` (extended)

## Implementation Details

### Time-Based Escalation
```gdscript
@export var time_escalation_rate: float = 2.0  # per minute
@export var time_escalation_enabled: bool = true
var _escalation_timer: float = 0.0
var _is_paused: bool = false
```

### Trigger Constants
```gdscript
const TRIGGER_COMBAT_LIGHT := 5.0
const TRIGGER_COMBAT_HEAVY := 15.0
const TRIGGER_ALARM := 25.0
const TRIGGER_SEALED_AREA := 7.0
```

### New Methods
```gdscript
func add_escalation(amount: float, reason: String = "") -> void
func trigger_combat(heavy: bool = false) -> void
func trigger_alarm() -> void
func trigger_sealed_area() -> void
func pause_escalation() -> void
func resume_escalation() -> void
func start_expedition() -> void
func end_expedition() -> void
var is_paused: bool  # read-only getter
```

## Verification Results
| Check | Result |
|-------|--------|
| LSP diagnostics | 0 errors, 0 warnings |
| Time escalation | Works at configurable rate |
| Action triggers | Debug output confirmed |
| Pause/resume | Correctly stops/resumes time-based only |

## Tuning Recommendations
- 2.0/min default: takes 50 min to reach 100% from time alone
- Consider 3.0-10.0/min for shorter expeditions
- Action triggers can add 50%+ during active play
- Recommend playtesting to calibrate

## Integration Notes for 04-04
- Call `start_expedition()` when entering expedition
- Call `end_expedition()` on extraction/death
- Connect to `threshold_crossed` signal for spawner behavior
- Use `trigger_combat()`, `trigger_alarm()` from combat systems
- `is_overrun()` true at 100% - use for forced extraction

---
*Executed: 2026-04-13*
