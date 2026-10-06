# Berser King

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Godot Engine](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Version](https://img.shields.io/badge/Version-0.0.1V-brightgreen.svg)](#)

A fast-paced 2D rogue-like survivor action game built with **Godot Engine 4**. Battle against ever-growing hordes of fantasy monsters, master high-speed dash mechanics, unlock powerful weapons and procedural upgrades, and conquer varied arenas from ancient castles to perilous dungeons.

---

## 🎮 Features

### ⚔️ Playable Characters
- **Wind Warrior**: Master of swift movement with customized fluid walking and dash animations.
- **Knight (Berserker)**: Heavy-hitting warrior designed for frontline melee durability.
- **Bandit**: Cunning rogue specializing in agility and hit-and-run tactics.
- **Character Select Menu**: Interactive character selection screen featuring previews, statistics, and real-time selection feedback.

### 🗺️ Dynamic Levels & Procedural World
- **Castle (Default Arena)**: Sprawling stone stronghold packed with obstacle layouts, defensive corridors, and room for open combat.
- **Dungeon**: Underground labyrinth with claustrophobic halls and dense enemy clusters.
- **Infinite Procedural Chunk Generator**: Noise-driven terrain generator that loads and unloads tile chunks seamlessly around the player.
- **Level Select & Memory**: Selected level persists across gameplay sessions, ensuring both *Play* and *Play Again* launch the intended stage.

### 👹 Horde & Wave Spawner
- **Smart FOV Spawning**: Enemies spawn exclusively outside the player's visible camera viewport, preventing unfair close spawns.
- **Diverse Bestiary**: Face over 18 enemy variants including Worms, Goblins, Spiders, Skeletons, Golems, Cultists, Ghosts, Flying Eyes, Reapers, and Slimes.
- **Wave Progression System**: Wave sequences scale up in density and variety as survival time increases.

### 🗡️ Weapons & Reflection Upgrade Engine
- **Autonomous Weapons**: Equip Ninja Stars (Shuriken), Orbiting Chainsaws, Bows, and damaging touch mechanics.
- **Dynamic Reflection Upgrades**: Procedurally spawned items across chunks dynamically enhance player attributes (attack damage, speed, max health).
- **Interactive Pickups & Chests**: In-game modal popups for acquiring relics and chest rewards with game-pausing inspection.

### 🖥️ Polished Interface & Audio
- **Survival HUD**: Dedicated elapsed survival timer and health bar positioned beneath the timer.
- **Main Menu**: Comprehensive menu supporting Level Select, Character Select, Audio Options, and Volume controls.
- **Smooth Scene Transitions**: Fade-in and fade-out scene transitions.

---

## 🕹️ Controls

| Action | Primary Input | Alternative Input |
| :--- | :--- | :--- |
| **Move Up** | <kbd>W</kbd> | <kbd>↑</kbd> |
| **Move Down** | <kbd>S</kbd> | <kbd>↓</kbd> |
| **Move Left** | <kbd>A</kbd> | <kbd>←</kbd> |
| **Move Right** | <kbd>D</kbd> | <kbd>→</kbd> |
| **Dash / Roll** | <kbd>Space</kbd> | Action Button |
| **Interact / Door** | <kbd>E</kbd> | <kbd>Enter</kbd> / Left Click |
| **Pause Menu** | <kbd>Esc</kbd> | Cancel Button |

---

## 📁 Project Structure

```text
BerserKing-Godot/
├── assets/
│   ├── levels/              # Level scenes (castle.tscn, dungeon.tscn)
│   ├── objects/
│   │   ├── entities/        # Player, enemies, items, and chest prefabs
│   │   ├── menus/           # Popup dialogs, character info cards, game over UI
│   │   └── weapons/         # Weapon instances (shuriken, chainsaw, bow)
│   ├── scripts/
│   │   ├── classes/         # Core game systems (EntityManager, ItemManager, Generator, MenuHandler)
│   │   ├── globals/         # Global autoload singletons and scene transitions
│   │   ├── objects/         # Entity, player, enemy, and weapon scripts
│   │   └── scenes/          # Menu controllers and level select logic
│   └── textures/            # Spritesheets, animations, tilemaps, fonts, and UI assets
├── data/
│   ├── entities/            # EntityResource definitions
│   ├── items/               # ItemResource definitions
│   └── waves/               # WaveResource and WaveEntry configurations
├── scenes/
│   ├── character_select.tscn# Character selection menu
│   ├── game.tscn            # Primary gameplay arena runner
│   ├── game_ui.tscn         # HUD (health bar, survival timer, stats)
│   ├── levels.tscn          # Level selection screen
│   ├── main_menu.tscn       # Initial intro screen
│   ├── main_menu_old.tscn   # Main menu hub
│   └── options_menu.tscn    # Settings & audio adjustments
└── project.godot            # Godot Engine project configuration
```

---

## 🚀 Getting Started

### Prerequisites
- **[Godot Engine 4.2+](https://godotengine.org/download)** (Godot 4.2 to 4.7 supported).

### Running the Project
1. Clone the repository:
   ```bash
   git clone git@github.com:Oxydome/BerserKing-Godot.git
   cd BerserKing-Godot
   ```
2. Open **Godot Engine** and select **Import**.
3. Choose the `project.godot` file in the cloned repository directory.
4. Press **Run Project** (<kbd>F5</kbd>) or launch `scenes/main_menu.tscn`.

---

## 📜 License

This project is licensed under the **Apache License, Version 2.0**.

See the [LICENSE](LICENSE) file for details or visit [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0).

```text
Copyright 2026 BerserKing Contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
