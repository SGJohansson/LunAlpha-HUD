<img src="lunahud.png" alt="LunaHUD" width="64" align="left" style="margin-right: 15px;">

**Minimalism. Precision. Stability.** *A professional-grade interface overhaul for Payday 2.*

<br clear="left"/>

---

# LunAlpha HUD — Precision Interface
Designed by S.G.Johansson, **LunAlpha HUD** (LunaHUD) is a high-performance interface designed for competitive play and minimalist purists. It isn't just about removing features—it's about **removing clutter**. 
Every UI element is engineered to reduce cognitive load: players focus on the heist, not reading HUD text.
<br>
<br>

## 🎯 The Minimalism Philosophy
Unlike stripped-down HUDs that sacrifice functionality, LunAlpha delivers essential tactical data cleanly:
* **Contextual Awareness**: Non-intrusive panels that activate only when relevant to your current state.
* **Visual Clarity**: Aggressive filtering of intrusive engine effects like bloom and chromatic aberration to improve target acquisition.
* **Spatial Optimization**: Elements are positioned to maximize screen real estate, perfectly adapted for standard, ultrawide, and high-refresh-rate setups (144Hz+).
<br>

## ⚡ Performance-First Architecture
* **Event-Driven Updates**: Elements only refresh when the game state changes, eliminating unnecessary frame-by-frame polling.
* **LunaCore Kernel**: A centralized lifecycle manager that prevents hook conflicts and ensures engine-level stability.
* **Zero-Impact Logic**: Optimized Lua backend designed to preserve FPS even during high-intensity police assaults.

<br>
<br>

## ✨ Key Modules

### 🛡 The Investigator (v3.0)
Advanced security suite for proactive lobby management. 
* **Peer Validation**: Real-time scanning for cheated skill points (e.g., 644-builds) and invalid equipment.
* **Mod Blacklisting**: Cross-references peer mod lists to flag known cheat-mods and griefing tools.
* **Automated Logging**: Comprehensive session logging for administrative review.

### 🧪 CleanCooker
Specialized module for chemical-based heists (e.g., Cook Off).
* Provides clear, non-intrusive ingredient prompts.
* Synchronizes state data between host and clients to prevent "wrong ingredient" desync errors.

### ⚔️ Combat & Feedback
* **Buff & Cooldown Tracking**: Consolidated real-time monitoring of perk deck procs and skill durations.
* **Joker Management**: Dedicated tracking for converted enemies, including health scaling and active status.
* **Smart Crosshair**: A precision-focused system for instant hit confirmation without visual bloat.

---

## ⚖️ License & Usage Policy
Licensed under **GNU GPLv3** with mandatory additional terms under Section 7:

1.  **Non-Commercial**: This mod and its derivatives MAY NOT be sold or monetized in any way.
2.  **Brand Protection**: Redistribution under the name "LunaHUD", "LunAlpha HUD", or "LunAlpha" is strictly prohibited.
3.  **Mandatory Attribution**: You MUST credit **S.G.Johansson** and link back to this repository.
4.  **Distinct Identity**: Modified versions (forks) must use a distinctively different name to avoid brand confusion.
5.  **Professional Integrity**: You may not use the LunAlpha brand to promote "troll-modding" or offensive content.

---

## 📦 Installation
1.  Requirement: [SuperBLT](https://superblt.znix.xyz/)
2.  Download this repository and place the `LunAlpha_MinimalHUD` folder into your `PAYDAY 2/mods/` directory.
