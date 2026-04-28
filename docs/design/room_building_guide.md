# Building Rooms in Godot 4.6 — Workshop Slice Guide

Practical guide for assembling the Workshop train car interior using the assets you've extracted. Scope is V2.0 slice only: one room, one character, three props, one light.

## The mental model

A Godot 3D scene is a tree of nodes. For a room, you typically have:

```
Workshop (Node3D)                  ← scene root, groups everything
├── Environment (Node3D)           ← static geometry
│   ├── Floor_01..09 (Node3D)      ← imported .gltf floor modules
│   ├── Wall_N_01..05              ← north wall pieces
│   ├── Wall_S_01..05              ← south wall pieces
│   ├── Wall_E_01..05, Wall_W...
│   └── Props
│       ├── Workbench
│       ├── Locker
│       └── Crate
├── Lighting (Node3D)
│   ├── DirectionalLight3D         ← "sun"/ambient fill
│   └── OmniLight3D                ← overhead work lamp
├── Characters (Node3D)
│   └── Player (CharacterBody3D)
└── IsoCamera                      ← the iso_camera.tscn you just made
```

You drag `.gltf` files from the FileSystem dock into the scene tree, and each becomes a Node3D with a `MeshInstance3D` child. You move them around by dragging gizmos in the 3D viewport or typing exact coordinates in the Inspector's `Transform > Position` field.

## First-time setup (one-off)

### 1. Merge the Quaternius character addon into your project

The `assets/characters/universal/quaternius/` folder is a standalone Godot project. You want just its `addons/quaternius/` folder in your main project.

Copy (or symlink) `off-the-rails/assets/characters/universal/quaternius/addons/quaternius/` into `off-the-rails/addons/quaternius/`. That's it — Godot will pick it up. You can delete the rest of the standalone project afterward if you want to save space.

### 2. Configure the iso camera scene

Open `src/camera/IsoCamera.tscn` in the editor to confirm it loaded correctly. The transform is pre-baked to dimetric (pitch -35.264°, yaw 45°, orthographic, size 12). Drop this scene into any level scene as a child of the scene root.

### 3. Set import defaults for the MegaKit

The meshes are .gltf with PBR textures. Godot 4.6 imports these cleanly by default, but if the textures look wrong:

- Select a .gltf in the FileSystem dock → Import tab → check that `Materials > Storage` is set to "Built-In (Keep)" for first-time viewing.
- For physics, the kit meshes have no colliders. You'll add collision manually per section 5 below.

## Building the Workshop room — step by step

### Step 1: New scene

`Scene > New Scene > 3D Scene`. Name the root node `Workshop`. Save as `src/scenes/workshop/Workshop.tscn`.

### Step 2: Add the camera

Drag `src/camera/IsoCamera.tscn` from FileSystem into the scene tree. It becomes a child of Workshop. You should see the viewport switch to an isometric angle. If the camera has no target yet, it stays at origin — that's fine for now.

Add a `WorldEnvironment` node to the scene root and set its Environment resource's background to a solid dark color and ambient light to something muted like `#222`. This prevents the room from being pitch-black when you haven't lit it yet.

### Step 3: Lay the floor

Open the FileSystem dock, navigate to `assets/environment/scifi_megakit/Platforms/`. You'll see 53 platform .gltf files. Find one that looks like a basic 1×1 floor tile — `Platform_Simple.gltf` or similar. Drag it into the scene. It appears at origin.

To tile the floor: select the floor node, copy it (Ctrl+D to duplicate), move it one tile along X (use the gizmo or set Position.x = 2.0 if the module is 2m wide — check by selecting the first one and reading its mesh's AABB). Repeat for a 5×5 grid.

**Turn on grid snap** before duplicating: `Editor > Snap Settings`, set `Translate Snap` to match the module size (1.0 or 2.0), then press `Y` in the viewport to toggle Use Snap. Now when you drag tiles, they jump to integer grid positions and line up perfectly.

**Pro move:** once you have one row of 5 floor tiles, select all 5 and duplicate the row. You now have 10 tiles in two rows. Duplicate those 10 to get 20. And so on. Much faster than placing them one at a time.

### Step 4: Walls

Navigate to `assets/environment/scifi_megakit/Walls/`. 117 wall modules — overwhelming. For a first pass, find two or three that look like generic straight panel walls. Good candidates to look for by filename: `Wall_Simple`, `Wall_Panel`, `Wall_Metal`, or anything without "Corner" / "Door" / "Window" in the name.

Place walls along the perimeter of your floor. If your floor is 5×5 tiles and each tile is 2m, your room is 10m × 10m. Wall tiles will likely be 2m wide × 3m tall — match them to floor tiles one-to-one along each edge.

You'll need to rotate walls 90°/180°/270° depending on which edge they're on. Select the wall node and set `Rotation.y` to 0, 90, 180, or 270 as needed. Godot's gizmo rotation also works — press `R` for rotate, drag the green ring.

Leave a 2m gap somewhere on one wall as a doorway. Don't worry about a door mesh yet for V2.0 — the gap is enough.

### Step 5: Collision on static geometry

None of the MegaKit meshes have colliders by default. Easiest fix:

1. Select the top-level Environment node.
2. In the Inspector menu (three-dot menu on the Environment node), click `Create > Trimesh Static Body`.
3. Godot walks all descendant MeshInstance3Ds and adds a StaticBody3D + ConcaveCollisionShape3D matching the visual geometry.

Alternative per-node: select any MeshInstance3D, use the toolbar menu `Mesh > Create Trimesh Static Body`. That wraps just that one mesh in a static body.

Concave collision is fine for static environment. Use `Create Convex Collision Sibling` (not Trimesh) for moveable props since convex is faster.

### Step 6: Props

Navigate to `assets/environment/scifi_megakit/Props/`. 43 options. Drag in three:
- Something bench-like for the workbench (`Prop_Workbench`, `Prop_Machine`, or similar).
- Something locker/cabinet-like (`Prop_Locker`, `Prop_Cabinet`).
- Something crate-like (`Prop_Crate`, `Prop_Box`).

Place them against a wall with grid snap on. Add convex collision via the toolbar menu as above.

For the interaction system, each prop needs an Area3D child with a CollisionShape3D that defines the interaction trigger volume. Your existing interaction system in `src/interaction/` already handles the trigger logic — you just need to attach its scene/script to each prop.

### Step 7: Lighting

A single overhead lamp:

1. Add an `OmniLight3D` node as a child of Lighting.
2. Position it at Y = 3.0 over the center of the room.
3. Set `light_color` to a warm value like `#ffcc88`.
4. Set `light_energy` to 2.0 or 3.0.
5. Set `omni_range` to 8.0.
6. Enable `shadow_enabled`.

For ambient fill, add a `DirectionalLight3D`:
1. `light_energy` 0.3 (very low — it's fill, not primary).
2. `shadow_enabled` off (one shadow-caster is enough for perf).
3. Rotate it so it matches the "upper-left light direction" aesthetic from your docs.

### Step 8: The player

1. Drag a Universal Base Character mesh from `addons/quaternius/universalbasecharacters/` into the scene. Use one of the pre-composed character .gltf files (look for something like `Character_Male_01.gltf`).
2. Wrap it in a `CharacterBody3D` node: right-click the character mesh node → `Change Type` doesn't work here, so instead: add a new `CharacterBody3D` to the scene, reparent the mesh under it.
3. Add a `CollisionShape3D` to the CharacterBody3D. Use a `CapsuleShape3D` sized roughly 0.8m tall, 0.3m radius.
4. Attach your existing player movement script from `src/player/` to the CharacterBody3D.
5. Set the IsoCamera's `target` property (in the Inspector) to the CharacterBody3D. The camera will now follow the player.

### Step 9: Animations

The character mesh imports with a skeleton but no animations. To attach UAL animations:

1. Open `UAL1.glb` in FileSystem — double-click. Godot opens the import preview.
2. In the import tab, under `Animation > Import`, the library of animations is listed.
3. Create an `AnimationLibrary` resource from the import (Godot 4.3+ has a button for this in the import tab).
4. On your Player scene, add an `AnimationPlayer` node. In its inspector, load the AnimationLibrary you just created. You'll see all UAL clips (walk, idle, run, etc.).
5. In your player movement script, call `animation_player.play("Walk")` when moving, `"Idle"` when stationary.

Quaternius character skeletons are standardized, so the UAL animations drop in without retargeting.

## Troubleshooting

**Camera looks down at the floor correctly but the player walks "sideways" across the screen.**
Your player movement uses world axes, but iso view rotates everything 45°. Either rotate the player's movement input to match the camera yaw, or rotate the entire scene 45° so player N/S/E/W align with screen diagonals. The former is cleaner.

**Shadows are jagged / pixelated.**
Project Settings > Rendering > Shadows > bump `Directional Shadow / Size` and `Positional Shadow / Size` to 4096 or higher.

**Everything is black or washed out.**
Check WorldEnvironment > Environment > Tonemap mode (try `Filmic`) and ambient light energy. Godot 4's default tonemap is linear which makes everything look flat.

**MegaKit meshes look untextured / pink.**
The `.gltf` uses external texture references that should resolve automatically. If not, select the .gltf in FileSystem, check the Import tab for errors, and confirm the referenced .png files are in the same folder (they should be, all 272 meshes share the trim textures at the top level of the MegaKit folder).

**Grid snap doesn't work.**
Press `Y` in the viewport to toggle snap. Or enable via `View > Use Snap`. The icon is in the toolbar as a magnet.

## What's next after the Workshop boots

1. Door animation (the MegaKit has sliding-door meshes — animate position with a Tween or AnimationPlayer).
2. Decal placement for floor grime (use `Decal` nodes, drag decal textures from `scifi_megakit/Decals/` onto them).
3. Expand to the next train car (Bunks, Infirmary, etc.) using the same modular approach.
4. Enemy/NPC — use Universal Base Characters again with different outfit meshes.
