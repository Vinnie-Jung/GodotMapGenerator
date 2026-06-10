#  Map Generator (Godot 4 Plugin)

A procedural 3D map generator for Godot 4 that lets you quickly create cave-like environments with navigation, props, and multiple rendering styles.

Designed for fast prototyping and flexible level generation directly inside the editor.

---

##  What you can do with it

- Generate procedural 3D maps with a single click
- Control map shape (open or closed layouts)
- Add navigation mesh automatically
- Place props using rule-based logic
- Reproduce maps using seeds
- Customize visuals with mesh libraries

---

##  Quick Start

1. Open the Map Generator dock inside the editor  
2. Set your map parameters:
   - Size (X / Y / Z)
   - Seed (optional)
   - Closed or open map
   - Prop density
   - Navigation toggle

3. Click **Generate**

That’s it.

The system will:
- Build the map
- Optionally place props
- Optionally bake navigation
- Spawn everything into your scene

---

##  Seed System

Every map can be reproduced using a seed.

Example:

```
seed = 12345
```

Using the same seed will always generate the same map layout.

---

##  Map Types

### Closed Map
- Fully enclosed environment
- Walls on all borders

### Open Map
- Edges can be open
- Useful for terrain / outdoor levels

---

##  Props System

Props are generated using rule-based logic.

You can define:
- Where a prop can spawn (floor, wall, ceiling)
- How rare it is
- Required conditions (empty space, adjacency, etc.)
- The scene that will be spawned

Example:
- Rocks scattered on the floor
- Torches attached to walls
- Props with random variation

---

##  Navigation (Optional)

You can enable automatic navigation mesh generation.

When enabled:
- A NavigationRegion is created automatically
- A navigation mesh is baked after generation
- AI agents can immediately navigate the map

---

##  Rendering Modes

### GridMap Mode
- Fast and optimized
- Good for large maps
- Voxel-style rendering

### Node Mode
- More flexible
- Allows full scene-based props
- Better for gameplay-heavy levels

---

##  Customization

You can customize:
- Floor and wall meshes
- Prop rules and density
- Map size and seed
- Navigation settings
- Open/closed map behavior

---

##  Tips

- Use seeds to iterate quickly on level designs
- Start with low prop density for readability
- Closed maps are better for dungeon gameplay
- Open maps work better for exploration / terrain

---


##  How to Install

### Option 1: Copy into your project

1. Download or clone this repository
2. Copy the folder into your Godot project:

```
res://addons/map_generator/
```

3. Enable the plugin:
   - Go to `Project > Project Settings > Plugins`
   - Find **Map Generator**
   - Set it to **Active**

---


##  Notes

- This tool is meant for procedural generation and prototyping
- Large maps may take longer to generate depending on settings
- Navigation baking may vary depending on mesh complexity

---

##  Example Use Cases

- Dungeon generation
- Roguelike levels
- Procedural prototypes
- Level design blocking
- AI navigation testing environments

---

##  Requirements

- Godot 4.x

---

## 🎮 Enjoy!

Build, generate, and iterate your worlds quickly.
