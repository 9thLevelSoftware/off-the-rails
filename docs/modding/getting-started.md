# Getting Started with Off The Rails Modding

This guide walks you through creating your first mod for Off The Rails.

## Prerequisites

Before creating a mod, you should:

1. Have a working installation of Off The Rails
2. Basic familiarity with JSON format
3. (Optional) Basic GDScript knowledge for scripted mods

## Creating Your First Mod

### Step 1: Create the Mod Folder

Mods are stored in the `user://mods/` directory. The actual location depends on your operating system:

| Platform | Location |
|----------|----------|
| Windows | `%APPDATA%\Godot\app_userdata\Off The Rails\mods\` |
| Linux | `~/.local/share/godot/app_userdata/Off The Rails/mods/` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Off The Rails/mods/` |

Create a new folder for your mod. The folder name should match your mod's ID:

```
mods/
  my_first_mod/
```

### Step 2: Create mod.json

Every mod requires a `mod.json` manifest file. Create this file in your mod folder:

```json
{
  "id": "my_first_mod",
  "version": "1.0.0",
  "name": "My First Mod",
  "description": "My first mod for Off The Rails!",
  "author": "Your Name",
  "dependencies": [],
  "content_files": [],
  "scripts": []
}
```

**Important rules for the `id` field:**
- Must start with a lowercase letter
- Can only contain lowercase letters, numbers, and underscores
- Examples: `my_mod`, `awesome_items_v2`, `train_expansion`

### Step 3: Add Custom Items

Create a `data` folder and add an `items.json` file:

```
my_first_mod/
  mod.json
  data/
    items.json
```

Add your items to `items.json`:

```json
{
  "items": [
    {
      "id": "power_crystal",
      "name": "Power Crystal",
      "description": "A glowing crystal that hums with energy.",
      "category": "common",
      "type": "material",
      "stack_size": 10
    },
    {
      "id": "crystal_shard",
      "name": "Crystal Shard",
      "description": "A fragment of a larger power crystal.",
      "category": "common",
      "type": "component",
      "stack_size": 20
    }
  ]
}
```

Update your `mod.json` to include the content file:

```json
{
  "id": "my_first_mod",
  "version": "1.0.0",
  "name": "My First Mod",
  "description": "My first mod for Off The Rails!",
  "author": "Your Name",
  "dependencies": [],
  "content_files": [
    "data/items.json"
  ],
  "scripts": []
}
```

### Step 4: Add Custom Recipes

Create a `recipes.json` file in your `data` folder:

```json
{
  "recipes": [
    {
      "id": "refined_crystal",
      "name": "Refined Crystal",
      "description": "A purified power crystal with enhanced properties.",
      "station": "workshop",
      "inputs": [
        {"item_id": "my_first_mod:power_crystal", "quantity": 2},
        {"item_id": "my_first_mod:crystal_shard", "quantity": 5}
      ],
      "output": {"item_id": "my_first_mod:refined_crystal", "quantity": 1},
      "craft_time": 120
    }
  ]
}
```

**Note:** When referencing your mod's items in recipes, use the full prefixed ID (`my_first_mod:power_crystal`). Base game items don't need a prefix (`scrap_metal`).

Update `mod.json`:

```json
{
  "id": "my_first_mod",
  "version": "1.0.0",
  "name": "My First Mod",
  "description": "My first mod for Off The Rails!",
  "author": "Your Name",
  "dependencies": [],
  "content_files": [
    "data/items.json",
    "data/recipes.json"
  ],
  "scripts": []
}
```

### Step 5: Add Scripts (Optional)

For more advanced functionality, you can add GDScript files that run when your mod loads.

Create a `scripts` folder and add `on_init.gd`:

```
my_first_mod/
  mod.json
  data/
    items.json
    recipes.json
  scripts/
    on_init.gd
```

Create your initialization script:

```gdscript
extends RefCounted

## My First Mod initialization script

func _mod_init(api: ModAPI) -> void:
    print("[MyFirstMod] Initializing...")
    
    # Connect to game events
    EventHooks.game_ready.connect(_on_game_ready)
    
    # You can also register items via script
    var bonus_item := {
        "id": "bonus_crystal",
        "name": "Bonus Crystal",
        "description": "A special crystal added via script.",
        "category": "common",
        "type": "material",
        "stack_size": 5
    }
    
    if api.register_item(bonus_item):
        print("[MyFirstMod] Registered bonus_crystal")
    
    print("[MyFirstMod] Initialization complete!")


func _on_game_ready() -> void:
    print("[MyFirstMod] Game is ready, mod is active!")
```

Update `mod.json`:

```json
{
  "id": "my_first_mod",
  "version": "1.0.0",
  "name": "My First Mod",
  "description": "My first mod for Off The Rails!",
  "author": "Your Name",
  "dependencies": [],
  "content_files": [
    "data/items.json",
    "data/recipes.json"
  ],
  "scripts": [
    "scripts/on_init.gd"
  ]
}
```

### Step 6: Test Your Mod

1. Launch Off The Rails
2. Check the console output for mod loading messages:
   ```
   [ModLoader] Discovered mod: my_first_mod v1.0.0
   [ModLoader] Loaded mod: my_first_mod
   [MyFirstMod] Initialization complete!
   ```
3. Verify your items appear in the game
4. Test crafting your recipes

## Final Folder Structure

Your completed mod should look like this:

```
my_first_mod/
  mod.json
  data/
    items.json
    recipes.json
  scripts/
    on_init.gd
```

## Common Errors and Solutions

### "No mod.json found in mod directory"

**Cause:** The `mod.json` file is missing or named incorrectly.

**Solution:** Ensure you have a file named exactly `mod.json` (lowercase) in your mod's root folder.

### "Invalid 'id' format"

**Cause:** Your mod ID doesn't follow the naming rules.

**Solution:** Change your ID to use only lowercase letters, numbers, and underscores. Must start with a letter.

```json
// Bad
"id": "My-Mod"
"id": "123mod"
"id": "MOD_NAME"

// Good
"id": "my_mod"
"id": "mod123"
"id": "awesome_mod_v2"
```

### "Invalid 'version' format"

**Cause:** Version doesn't follow semantic versioning (X.Y.Z).

**Solution:** Use three numbers separated by dots.

```json
// Bad
"version": "1.0"
"version": "v1.0.0"
"version": "1"

// Good
"version": "1.0.0"
"version": "2.1.3"
```

### "Content file not found"

**Cause:** A file listed in `content_files` doesn't exist.

**Solution:** Check that:
1. The file exists in the correct location
2. The path in `mod.json` matches the actual file path
3. Paths use forward slashes (`data/items.json`, not `data\items.json`)

### "Script file not found"

**Cause:** A script listed in `scripts` doesn't exist.

**Solution:** Same as content files - verify the file exists and the path is correct.

### "File is not a valid GDScript"

**Cause:** The script has syntax errors or isn't proper GDScript.

**Solution:** Check your script for:
1. Missing `extends` declaration
2. Syntax errors (missing colons, incorrect indentation)
3. Wrong file extension (must be `.gd`)

### "Required dependency not found"

**Cause:** Your mod requires another mod that isn't installed.

**Solution:** Either:
1. Install the required mod
2. Remove the dependency from `mod.json` if it's not actually needed

### Items/Recipes not appearing

**Cause:** Content registered but not visible in game.

**Possible solutions:**
1. Check console for registration errors
2. Verify JSON syntax is valid
3. Ensure `content_files` lists your data files
4. Check that item IDs are unique

## Next Steps

Now that you've created a basic mod, you can:

1. **Add more content types:** Check the [API Reference](mod-api-reference.md) for professions and train cars
2. **Use EventHooks:** React to game events like crafting, expeditions, and player actions
3. **Create complex logic:** Use GDScript for dynamic content registration
4. **Share your mod:** Package your mod folder and share with the community

## Getting Help

- Check the [API Reference](mod-api-reference.md) for detailed documentation
- Look at the `example_item_mod` in `src/mods/` for a working example
- Console output (`[ModLoader]` messages) helps diagnose issues
