# LunAlpha HUD — Precision Interface
> **Minimalism. Precision. Stability.**
> Designed by S.G.Johansson.

LunAlpha HUD is a high-performance interface overhaul for Payday 2. Engineered to eliminate visual noise, it delivers critical tactical data and ensures lobby integrity without compromising system resources.

---

## 🛠 Technical Architecture
LunAlpha is more than just a visual layer; it is a modular framework built for stability:
* **LunaCore**: A centralized lifecycle manager ensuring hooks execute in the correct order to prevent engine-level crashes.
* **Dynamic Layout Engine**: Custom positioning logic that adapts to various aspect ratios and resolutions without distortion.
* **Event-Driven UI**: Designed to minimize polling. HUD elements update only when the game state changes, preserving CPU cycles for maximum FPS.

## ✨ Key Modules

### 🛡 The Investigator (v3.0)
Advanced security suite for proactive lobby management:
* **Peer Validation**: Scans for cheated skill points (e.g., 644-point builds) and invalid equipment.
* **Mod Blacklisting**: Cross-references peer mod lists against `luna_blacklist.json` to flag known cheat-mods and griefing tools.
* **Automated Logging**: Comprehensive session logging of suspicious activity for administrative review.

### 🧪 CleanCooker
Specialized module for chemical-based heists (e.g., Cook Off):
* Clear, non-intrusive ingredient prompts.
* Synchronizes state data between host and clients to prevent "wrong ingredient" desync errors.

### ⚔️ Combat & Visual Clarity
* **Buff & Cooldown Tracking**: Real-time monitoring of perk deck procs and skill durations.
* **Joker Management**: Dedicated tracking for converted enemies, including health scaling and active status.
* **Visual Clear**: Aggressive filtering of intrusive engine effects like bloom and chromatic aberration to maintain target focus.

---

## ⌨️ Chat Commands (ChatTrigger)
LunaHUD features a powerful command system to manage the HUD directly via chat (silent to other players).

| Command | Function |
| :--- | :--- |
| `/luna help` | Displays available commands in the console. |
| `/luna reload` | Hot-reloads the HUD configuration. |
| `/luna clean` | Clears the chat from system clutter and spam. |
| `/luna stats` | Toggles the visibility of extended session statistics. |
| `/luna secure` | Enables/Disables real-time Investigator scanning. |

---

## ⚖️ License & Usage Policy
Licensed under **GNU GPLv3** with mandatory additional terms under Section 7:

1. **Non-Commercial**: This mod and its derivatives MAY NOT be sold or monetized in any way.
2. **Brand Protection**: Redistribution under the name "LunaHUD", "LunAlpha HUD", or "LunAlpha" is strictly prohibited.
3. **Mandatory Attribution**: You MUST credit **S.G.Johansson** and link back to this repository if using any part of the source code.
4. **Distinct Identity**: Modified versions (forks) must use a distinctively different name to avoid brand confusion.

---

## 📦 Installation
1. Requirement: [SuperBLT](https://superblt.znix.xyz/)
2. Download this repository as a .zip or clone it.
3. Place the `LunAlpha_MinimalHUD` folder into your `PAYDAY 2/mods/` directory.