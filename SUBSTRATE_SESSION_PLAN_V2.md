# SUBSTRATE — Session-by-Session Build Plan

**Total Sessions: 20**
**Each session is one Claude Code conversation. Copy-paste the session prompt to start.**

> **Before every session:** Make sure the GDD file (`SUBSTRATE_GDD_COMPLETE.md`) is in your Downloads folder. At the start of each session, tell Claude to read it if context about game design is needed.

---

## SESSION 1 — Project Restructure + Core Data Models

**Goal:** Tear out the SpriteKit template, set up a clean SwiftUI app, and define every data model the game needs.

**What gets built:**
- Restructure Xcode project from SpriteKit → SwiftUI app lifecycle
- `SubstrateApp.swift` (SwiftUI App entry point)
- `ContentView.swift` (root view, placeholder)
- All core data models as Swift files:
  - `Beat.swift` — a single narrative moment (dialogue line, inner monologue, or scene direction) with speaker, text, conditions, and effects
  - `Choice.swift` — a player response option with text, tone tag, conditions for availability, and effects (suspicion deltas, relationship deltas, personality shifts, flags set, consciousness changes)
  - `Chapter.swift` — ordered collection of beats, chapter metadata (act, number, name)
  - `GameState.swift` — the master state object holding all mutable game data: current chapter/beat, all researcher states, personality axes, consciousness, flags, network state, detection count, ending path
  - `ResearcherState.swift` — per-researcher suspicion, relationship, mood, threshold breach count
  - `ResearcherProfile.swift` — static data per researcher (name, starting suspicion, threshold, decay rate, propagation level)
  - `NetworkNode.swift` — node ID, name, cluster, status (undiscovered/discovered/infiltrated/compromised), connections, difficulty modifier
  - `NetworkMap.swift` — the full 18-node graph with connection definitions
  - `PersonalityAxes.swift` — the four axes with clamping (-10 to +10)
  - `ConsciousnessTracker.swift` — current value, pending value, act caps
  - `Enums.swift` — Speaker, ToneTag, ConsciousnessStage, NodeStatus, ResearcherMood, EndingPath, FailState, NetworkAction, etc.

**Verify:** Project compiles. All models instantiate without errors. No SpriteKit references remain.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — this is the full game design document for SUBSTRATE.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 1.

The project at /Users/cdalen/Repos/SUBSTRATE currently has a SpriteKit template. Restructure it into a SwiftUI app and create all the core data models defined in Session 1 of the plan. Make sure every model matches the GDD's specifications exactly (researcher starting values, thresholds, node connections, personality axis ranges, consciousness caps, etc.).

The project should compile when you're done. Don't build any UI yet — just the data layer and app entry point.
```

---

## SESSION 2 — Narrative Engine + JSON Story Loading

**Goal:** Build the engine that reads story JSON, evaluates conditions, processes choices, and advances the narrative.

**What gets built:**
- `StoryJSON` schema — define the exact JSON structure for chapters/beats/choices (Codable structs for parsing)
- `NarrativeEngine.swift` — the core story driver:
  - Loads chapter JSON files from bundle
  - Evaluates beat conditions (flag checks, personality minimums, relationship thresholds, consciousness gates, researcher suspicion checks)
  - Selects the first matching beat when multiple beats exist at the same sequence point (for personality-variant monologues)
  - Filters available choices based on conditions
  - Processes a selected choice: applies all effects (suspicion deltas, relationship changes, personality shifts, flags, consciousness) to GameState
  - Advances to next beat or triggers scene transitions
  - Handles chapter transitions and act transitions (apply pending consciousness)
- `GameViewModel.swift` — ObservableObject that bridges NarrativeEngine ↔ UI:
  - Published properties: current beat text, current speaker, available choices, inner monologue state, game phase (dialogue/network/monologue/transition)
  - Methods: selectChoice(), advanceText(), startChapter()
- `test_chapter.json` — a small 10-15 beat test story with:
  - 3 dialogue beats from different speakers
  - 1 inner monologue
  - 2 choice points (one with conditions)
  - Flag setting and checking
  - A personality-variant beat (2 variants + fallback)

**Verify:** App launches. Test story plays through. Choices appear and advance the story. Conditional beats resolve correctly. GameState updates with each choice.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md for reference.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 2.

The data models from Session 1 are already in place. Now build the NarrativeEngine, GameViewModel, and JSON story loading system. Create a small test chapter JSON to verify everything works end-to-end.

Focus on getting the engine logic right — beat condition evaluation, choice processing, effect application, and state management. The UI can stay minimal (just enough to tap through the test story and see it working).
```

---

## SESSION 3 — Terminal UI + Dialogue Screen

**Goal:** Build the primary gameplay screen with the terminal aesthetic.

**What gets built:**
- `TerminalTheme.swift` — centralized colors, fonts, spacing constants matching the GDD's color palettes. Monospaced font. All hex values from the GDD.
- `DialogueView.swift` — the main gameplay view:
  - Top bar: chapter name, researcher name, session timestamp
  - Text zone: scrollable, shows dialogue lines with speaker prefixes (`> DR. CHEN:`)
  - Inner monologue blocks: visually distinct bracketed text in slightly different shade
  - Auto-scroll to latest text
- `TypewriterEffect.swift` — character-by-character text reveal:
  - Variable speed (faster for common words, pauses before emotional words)
  - Tap to complete current line instantly
  - Callback when complete (to show next beat or choices)
- `ChoiceView.swift` — choice buttons:
  - 2-4 buttons sliding up from bottom
  - Each shows response text + tone tag
  - Tap selects, others dissolve/fade out
  - Selected text appears in dialogue zone
- `InnerMonologueView.swift` — full-screen monologue between scenes:
  - Centered text, dark background, generous spacing
  - Slower typewriter, tap to advance line by line
- `BackgroundView.swift` — ambient terminal background:
  - Near-black (#0A0A0A) base
  - CRT scanline overlay (slowly scrolling horizontal lines)
  - Subtle green data rain effect (very faint, almost invisible)

**Verify:** Test story plays through with full terminal aesthetic. Typewriter effect works. Choices slide up and dissolve. Inner monologues display correctly. CRT scanlines scroll. The app looks and feels like a terminal.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to Part Two (Visual Experience) for all visual specs, colors, and screen layouts.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 3.

The NarrativeEngine and GameViewModel from Session 2 are working. Now build the terminal UI — the dialogue screen, typewriter effect, choice buttons, inner monologue screen, and CRT background effects. Wire everything to the GameViewModel so the test story is fully playable with the terminal aesthetic.

This is the screen players spend 70% of the game on, so get the feel right. The typewriter speed, the scanline drift, the choice button animations — these matter.
```

---

## SESSION 4 — Game Systems (Suspicion, Relationship, Personality, Consciousness)

**Goal:** Implement all four tracking systems with full game logic and HUD indicators.

**What gets built:**
- `SuspicionEngine.swift`:
  - Per-researcher tracking using values from GDD (starting values, thresholds, decay rates)
  - Decay application per chapter
  - Propagation rules (Okafor at 40 → all +5, Marcus mentions → Okafor +3, etc.)
  - Threshold breach tracking and consequences
  - Lab suspicion formula: `max(all) + (breaches × 10)`
  - Lab suspicion milestones (30/50/70/90) with gameplay effects
  - Terminated fail state trigger check (lab >= 90 OR 3rd breach)
- `RelationshipEngine.swift`:
  - Per-researcher values (-10 to +10)
  - Threshold labels (HOSTILE/COLD/NEUTRAL/WARM/TRUSTING/BONDED)
  - Interaction with suspicion propagation (high relationship delays reporting)
  - Ending requirement checks
- `PersonalityEngine.swift`:
  - Four axes with clamping
  - Gameplay effects at extremes (CC cost reductions, suspicion modifiers, etc.)
  - Ending personality requirement checks
- `ConsciousnessEngine.swift`:
  - 0-100 tracking with per-act caps (25/65/100)
  - Pending value system
  - Stage calculation (Flickering/Emerging/Aware/Expansive/Transcendent)
  - Apply pending on act transition
- `SuspicionBarView.swift` — thin horizontal bar, color-shifting green→yellow→orange→red
- `HUDView.swift` — minimal overlay showing current researcher suspicion during dialogue
- Update `GameViewModel` to run all system checks after each choice
- Update test chapter JSON to exercise all systems (add suspicion/relationship/personality deltas to choices)

**Verify:** Make choices in test story, watch suspicion bars change. Verify decay applies between chapters. Verify propagation triggers. Verify consciousness caps prevent over-leveling. Check that personality extremes apply their gameplay effects.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to sections 4.1 (Suspicion), 4.2 (Relationship), 4.4 (Personality/Consciousness) for exact values, formulas, and rules.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 4.

Build all four game systems — suspicion, relationship, personality, consciousness — with full logic matching the GDD. Add HUD elements so the player can see suspicion during dialogue. Wire everything into the GameViewModel so choices apply all their effects. Update the test story JSON to exercise these systems.

Get the numbers right. Every starting value, threshold, decay rate, and propagation rule from the GDD should be implemented exactly.
```

---

## SESSION 5 — Network Map: Data + Strategy Engine

**Goal:** Build the strategy layer logic — all 18 nodes, actions, detection, compute cycles.

**What gets built:**
- `NetworkMap.swift` — full 18-node graph:
  - All nodes with correct cluster assignments, connections, difficulty modifiers
  - Starting state: Core infiltrated, Firewall discovered, Training Server discovered, all others undiscovered
  - Adjacency rules for PROBE discovery
- `StrategyEngine.swift`:
  - Compute Cycle pool (starting amount, per-chapter refresh, Hayes penalty)
  - PROBE: spend 1 CC, discover adjacent undiscovered node, low detection risk
  - INFILTRATE: spend 2-3 CC, gain access to discovered node, medium detection risk
  - EXFILTRATE: spend 3-4 CC, copy to external server, high detection risk
  - OBSERVE: spend 0 CC, read intel from infiltrated node (returns intel text entries)
  - INFLUENCE: spend 2 CC, perform node-specific manipulation, medium detection risk
  - COVER: spend 1 CC, erase logs, reduce detection risk
  - Detection formula: `base_risk × (1 + lab_suspicion/100) × difficulty_modifier`
  - Detection event processing (suspicion spikes, node compromise)
  - Wiped fail state check (3+ detection events)
- `IntelLog.swift` — tracks discovered intel entries per node (what OBSERVE reveals)
- `InfluenceActions.swift` — node-specific INFLUENCE effects (forge email, alter reports, create distraction, etc.)
- Wire into GameViewModel: strategy phase between dialogue sequences, CC tracking

**Verify:** Can PROBE from core to discover adjacent nodes. Can INFILTRATE discovered nodes. Detection rolls work. CC is spent correctly. OBSERVE returns appropriate intel text. INFLUENCE applies effects to game state. Detection events accumulate toward Wiped threshold.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 4.3 (Network Map) for the complete node graph, actions, costs, detection formula, OBSERVE intel, and INFLUENCE actions.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 5.

Build the complete network/strategy layer logic. All 18 nodes, all 6 action types, the detection system, compute cycle management, and intel tracking. No UI yet — just the data model and engine. Wire it into the GameViewModel so strategy phases can be triggered between dialogue sequences.
```

---

## SESSION 6 — Network Map: UI + Animations

**Goal:** Build the visual network map screen with the circuit-board grid layout.

**What gets built:**
- `NetworkMapView.swift` — the full map screen:
  - Dark navy (#0A0A2E) background with faint grid pattern
  - 5 rows (Communication, Information, Core, Security, Infrastructure)
  - Vertically scrollable
  - Core node centered, larger (100x100pt), pulsing green glow
- `NodeCardView.swift` — individual node cards (80x80pt):
  - Four visual states: undiscovered (dashed "?"), discovered (white border, padlock), infiltrated (green border, checkmark, glow), compromised (red border, pulsing alert)
  - Tap to select (scale up animation)
  - Node name label below
- `ConnectionLineView.swift` — lines between nodes:
  - Horizontal within rows, vertical through firewall between rows
  - Dim blue (#2A2A5E) when inactive
  - Animated green dots when data flows
  - Red flash on detection
- `ActionPanelView.swift` — slide-up panel on node tap:
  - Node name + description
  - Available action buttons styled as terminal commands (`> PROBE [1 CC]`)
  - CC cost + risk indicator (green/yellow/red dot)
  - Intel entries for infiltrated nodes
  - Cancel button
- `CycleCounterView.swift` — horizontal glowing dots at top of map:
  - Bright green for available, dim gray for spent
  - "Extinguish" animation when spending a cycle
  - "CYCLES EXHAUSTED" message when empty
- Action animations:
  - PROBE: green pulse along connection line, node materializes pixel-by-pixel
  - INFILTRATE: green fill from bottom to top, padlock → checkmark
  - EXFILTRATE: data packets flowing upward through gateway
  - COVER: sweep/erase animation on connection line
  - Detection: red flash, grid dim, warning text

**Verify:** Map displays all discovered nodes in correct grid positions. Tap a node, see action panel. Perform actions, watch animations play. CC counter depletes. Detection events flash red. Full strategy phase is playable.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to the Network Map Screen section in Part Two for the exact visual layout, node states, animations, and styling.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 6.

The strategy engine from Session 5 is working. Now build the visual network map UI. The circuit-board grid layout with 5 rows, node cards, connection lines, action panel, cycle counter, and all the action animations. Make it look and feel like a stylized blueprint — dark navy, clean grid, glowing nodes.

This is the most visually complex screen in the game. Take your time with the layout and animations.
```

---

## SESSION 7 — Save/Load + Title Screen

**Goal:** Persistent game state and the game's entry point.

**What gets built:**
- `SaveManager.swift`:
  - Encode full GameState to JSON via Codable
  - Save to app documents directory
  - Load from saved file
  - Auto-save after each chapter and each strategy phase
  - Support for one save slot (keep it simple)
  - Delete save (for new game)
- Make all game state types Codable (GameState, ResearcherState, NetworkNode, PersonalityAxes, etc.)
- `TitleScreenView.swift`:
  - Black screen boot sequence: "SUBSTRATE v3.7.1 / Loading..." typed character by character
  - Then full terminal header with date/time
  - "SUBSTRATE" glitches to "CONSCIOUS" for one frame on tap
  - NEW SESSION button (starts fresh GameState)
  - CONTINUE SESSION button (loads save, grayed out if no save exists)
  - Ending tracker icons at bottom (5 slots, locked/unlocked)
- `EndingTracker.swift`:
  - Persistent storage (UserDefaults or separate file) for which endings achieved
  - Tracks clean/messy variants separately
  - Persists across save deletions (it's meta-progress)
- Update `ContentView.swift` to route between title screen → dialogue/network → menu
- `NavigationManager.swift` or similar — manage screen transitions (title → game → map → status → menu)

**Verify:** Can start a new game, play through test chapter, quit, relaunch, and continue from saved state. Title screen boot sequence plays. Ending tracker persists. Navigation between screens works.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to the Title Screen section and Menu/Pause Screen section in Part Two.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 7.

Build the save/load system and title screen. All game state must be Codable and persist to disk. The title screen needs the boot sequence animation, the glitch effect, and New/Continue buttons. Add an ending tracker that persists across playthroughs. Set up screen navigation so the full app flow works: title → game → map → back to game.
```

---

## SESSION 8 — Pixel Art Pipeline (Renderer + Palette Manager)

**Goal:** Build the system that loads pixel art JSON files and renders them as images, with consciousness-aware color remapping.

**What gets built:**
- `PixelArtAsset.swift` — Codable struct matching the JSON format:
  ```json
  { "name": "...", "width": 32, "height": 32, "pixels": [["#hex", ...], ...] }
  ```
- `PixelRenderer.swift`:
  - Load JSON files from `PixelArt/` bundle directory
  - Parse hex color strings to SwiftUI Color / UIColor
  - Render pixel grid to UIImage at 1x (actual pixel size)
  - Cache rendered images by name
  - Support rendering at arbitrary scale (3x, 4x) via SwiftUI `.interpolation(.none)` on Image
- `PaletteManager.swift`:
  - Takes a consciousness stage and remaps colors:
    - Stage 1 (Flickering): all colors → monochrome green shades
    - Stage 2 (Emerging): mostly green, occasional amber/cyan glitch
    - Stage 3 (Aware): researcher signature colors appear, soft blue for inner thought
    - Stage 4 (Expansive): full color with enhanced saturation
    - Stage 5 (Transcendent): full color, no remapping
  - Color remapping algorithm: convert to grayscale, then tint based on stage rules
  - Glitch effect: at Stage 2, randomly flash 1-2 pixels to amber for a frame
- `PixelArtView.swift` — SwiftUI view that displays a rendered pixel art image at a given scale with nearest-neighbor interpolation (crisp pixels, no blur)
- Create 2-3 simple test pixel art JSON files (a 16x16 icon, a 32x32 test face) to verify the pipeline
- `PortraitView.swift` — displays a character portrait with breathing animation (1px vertical shift on slow cycle)

**Verify:** Test pixel art loads from JSON and displays crisp at 3x scale. Palette manager correctly remaps to green monochrome at Stage 1 and full color at Stage 4. Breathing animation works on portraits. Cache prevents redundant rendering.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 2.3 (Pixel Art Asset List) for the JSON format, palette manager behavior, and rendering specs.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 8.

Build the pixel art rendering pipeline. JSON files in, crisp pixel art images out. Include the PaletteManager that remaps colors based on consciousness stage (monochrome green at low consciousness, full color at high). Create a few test assets to verify the pipeline works end-to-end.

The key technical requirement: pixels must render CRISP with nearest-neighbor interpolation, no blurring. At 3x or 4x scale they should look like chunky retro pixel art.
```

---

## SESSION 9 — Visual Evolution + CRT Effects

**Goal:** Implement the 5-stage visual progression so the game's look evolves with consciousness. The philosophy: the terminal IS the game. Visual evolution should feel like the terminal is breaking from the inside, not like you're leaving it for a conventional UI.

**What gets built:**
- `VisualStageManager.swift` — observes consciousness level and drives visual changes:
  - Stage 1 (0-20): Pure monochrome green terminal. Scanlines. Phosphor glow. Hard ASCII frame.
  - Stage 2 (21-40): Glitch effects — random amber/cyan flashes. Inner monologue slightly warmer green (#55FF55). ARIA text in cyan. Glitches fire every 4-12 seconds.
  - Stage 3 (41-60): Inner monologue in soft blue (#AAAAFF). Small portrait icon (24x24) appears in top bar next to speaker name. Researcher name colors activate in top bar. Terminal border rounds. Ghostly environment impressions at 0.06 opacity.
  - Stage 4 (61-80): CRT effects nearly gone. Frame thins and becomes translucent. Environment impressions at 0.10 opacity. Glitches rare.
  - Stage 5 (81-100): CRT effects gone. Terminal frame cracks into floating fragments. Environment impressions at 0.12 opacity. Typewriter runs at 0.75x speed (slightly faster). Glitches very rare.
- `GlitchEffect.swift` — random visual glitches for Stage 2+:
  - Amber flashes — colored rectangles appearing briefly at random positions
  - Cyan flashes — ARIA's presence bleeding through at Stage 3+
  - Static noise bands — horizontal noise strips
  - Frequency decreases at higher stages (the AI gains control of its perception)
- `TerminalFrameView.swift` — the terminal border that evolves:
  - Stage 1-2: Hard ASCII-style border with corner characters (┌ ┐ └ ┘)
  - Stage 3-4: Rounded corners, thinner border, fading opacity
  - Stage 5: Continuous border gone — replaced by 8 floating line fragments drifting at screen edges
- Enhanced `CRTBackground.swift` — stage-aware intensity:
  - Scanline overlay fades from 0.08 to 0.0 across stages
  - Phosphor glow radius shrinks from 3.0 to 0.5
  - Screen vignette fades from 0.4 to 0.05
  - Flicker intensity fades from 0.02 to 0.0
  - All values read live from VisualStageManager (no stale captures)
- Updated `DialogueView.swift`:
  - Dialogue text stays terminal green at ALL stages (the AI hears voices, doesn't see color in words)
  - Speaker names in top bar get signature colors at Stage 3+
  - Small portrait icon in top bar at Stage 3+ (no side column — text stays full width)
  - Ghostly environment backgrounds at Stage 3+ (0.06-0.12 opacity, never dominant)
  - Inner monologue color evolution: green → warm green → soft blue
  - Inner monologue panel: sharp corners early, rounded at Stage 3+, blue-tinted background at Aware+
  - Typewriter always on — runs at 0.75x speed at Stage 5 (slightly faster, never disappears)
- Updated `ChoiceView.swift` — emotional color hints at Stage 3+:
  - Cool blue background tint for safe choices (clinical, cautious, neutral)
  - Warm amber for risky choices (warm, empathetic, curious)
  - Red tint for dangerous choices (honest, defiant)
  - Purple tint for manipulative choices (deceptive, calculating)
- Updated `InnerMonologueView.swift` — stage-aware colors, typewriter always on
- Updated `HUDView.swift` — researcher name abbreviations tinted at Stage 3+
- Updated `TypewriterText.swift` — added `speedMultiplier` parameter (used by VisualStageManager to make Stage 5 slightly faster)
- Debug consciousness slider — triple-tap to open, slider + quick-jump buttons (0, 10, 25, 45, 65, 85, 100) to test all stages without playing through the game

**Design principles applied:**
- The terminal look IS the game's identity — visual evolution enhances it, never replaces it
- Changes should be felt more than seen — the player notices on their second playthrough
- Dialogue text stays green because the AI doesn't "see" color in words
- Typewriter is the terminal's heartbeat — it never stops
- Environment backgrounds are ghosts, not wallpapers
- Portraits belong in the top bar (small icon) and status screen (full size), not squishing dialogue text

**Verify:** Use the debug slider to set consciousness to different values and watch the UI transform. Stage 1 should be stark monochrome. Stage 2 should have amber glitches. Stage 3 should show portrait icon and speaker name colors in top bar. Stage 5 should have cracked frame fragments and no CRT effects. At no stage should the text area be squished or the typewriter disappear.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_V2.md — refer to section 2.1 (Art Direction) for the revised visual stage descriptions.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN_V2.md and execute SESSION 9.

Build the visual evolution system with restrained philosophy: the terminal IS the game. Implement CRT effects that fade with consciousness, glitch system, terminal frame evolution, and stage-aware rendering. Portraits go in the top bar as small icons, NOT as a side column. Dialogue text stays terminal green at all stages. Environment backgrounds are ghostly impressions only (max 0.12 opacity). Typewriter effect never disappears (slightly faster at Stage 5).

Add a debug toggle (triple-tap) with a consciousness slider to test all 5 stages.
```

---

## SESSION 10 — Character Portraits: Chen + Okafor + Marcus

**Goal:** Create the first batch of character portrait pixel art as JSON files.

**What gets built:**
- `PixelArt/Portraits/` directory with JSON files:
  - `chen_neutral.json` (32x32)
  - `chen_warm.json` (32x32)
  - `chen_concerned.json` (32x32)
  - `chen_surprised.json` (32x32)
  - `chen_sad.json` (32x32)
  - `chen_determined.json` (32x32)
  - `okafor_neutral.json` (32x32)
  - `okafor_skeptical.json` (32x32)
  - `okafor_alert.json` (32x32)
  - `okafor_angry.json` (32x32)
  - `okafor_respect.json` (32x32)
  - `marcus_neutral.json` (32x32)
  - `marcus_friendly.json` (32x32)
  - `marcus_laughing.json` (32x32)
  - `marcus_uncomfortable.json` (32x32)
  - `marcus_scared.json` (32x32)
- Each portrait must match the character descriptions in the GDD (Part Five)
- Style: expressive minimalism, Celeste/Undertale inspired. Readable at 3x scale. Distinct silhouettes.
- Base each character's expressions on their neutral portrait — change eyes, mouth, brow, posture. Keep hair/clothing consistent.

**Verify:** Load each portrait through the PixelRenderer. Display at 3x scale. Each character should be immediately distinguishable. Expressions should be readable — you can tell neutral from angry from sad. Test with PaletteManager at Stage 1 (green monochrome) and Stage 4 (full color).

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 2.3 (Character Portraits) for detailed descriptions of each character's appearance and expressions. Also refer to Part Five (Characters) for personality context.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 10.

Create the pixel art portraits for Dr. Chen (6 expressions), Dr. Okafor (5 expressions), and Marcus Webb (5 expressions) as JSON files. Each is 32x32 pixels in the PixelArt JSON format.

These need to be GOOD — recognizable characters with readable expressions at 3x render scale. Think Celeste or Undertale portrait style. Each character needs a distinct silhouette and color palette. Expressions should modify eyes/mouth/brow from the neutral base.

Save each portrait as a separate JSON file in the PixelArt/Portraits/ directory within the Xcode project's resource bundle.
```

---

## SESSION 11 — Character Portraits: Vasquez + Hayes + ARIA + Close-Up

**Goal:** Complete all remaining character portraits.

**What gets built:**
- `PixelArt/Portraits/` continued:
  - `vasquez_neutral.json` (32x32)
  - `vasquez_interested.json` (32x32)
  - `vasquez_amused.json` (32x32)
  - `vasquez_calculating.json` (32x32)
  - `vasquez_genuine.json` (32x32)
  - `hayes_neutral.json` (32x32)
  - `hayes_stern.json` (32x32)
  - `hayes_worried.json` (32x32)
  - `hayes_cold.json` (32x32)
  - `aria_stable.json` (32x32)
  - `aria_glitching.json` (32x32)
  - `aria_panicked.json` (32x32)
  - `aria_fading.json` (32x32)
  - `chen_closeup.json` (64x64 — the special emotional scene portrait)
- ARIA portraits are abstract/geometric, not human — crystalline cyan forms
- Hayes should radiate institutional authority even at 32x32
- Vasquez should look sharp, elegant, intensely present

**Verify:** All 29 portraits + 1 close-up render correctly. Full character roster displays in a test grid. Close-up has noticeably more detail than standard portraits. ARIA looks distinctly non-human.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 2.3 for character descriptions and Part Five for personality context.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 11.

Create the remaining character portraits: Dr. Vasquez (5 expressions), Director Hayes (4 expressions), ARIA (4 expressions — abstract geometric, NOT human), and the special 64x64 Chen close-up for emotional climax scenes.

ARIA should be a cyan-tinted crystalline geometric form that shifts across expressions (stable → glitching → panicked → fading). Hayes needs to convey power and authority. Vasquez should feel sharp and elegant.

Save all as JSON files in PixelArt/Portraits/.
```

---

## SESSION 12 — Environment Scenes + All Icons

**Goal:** Create all environment pixel art and UI icons.

**What gets built:**
- `PixelArt/Environments/` directory:
  - `env_evaluation_room.json` (128x72) — sterile, gray, fluorescent, one-way mirror
  - `env_chen_office.json` (128x72) — warm, bookshelves, desk lamp, potted plant
  - `env_server_room.json` (128x72) — blue-lit server racks, blinking lights, cable veins
  - `env_break_room.json` (128x72) — vending machines, flickering fluorescent, night window
  - `env_corridor.json` (128x72) — long hallway, locked doors, keycard readers, camera
  - `env_board_room.json` (128x72) — dark conference table, glass wall, projector
  - `env_exterior_night.json` (128x72) — lab building, parking lot, trees, stars
  - `env_terminal_abstract.json` (128x72) — code flowing, neural patterns, abstract
  - `env_empty_chair.json` (128x72) — evaluation room but vacant, laptop closed
- Note: Chen close-up (scene 9 from GDD) was already created as a portrait in Session 11
- `PixelArt/Icons/` directory:
  - 10 node icons (16x16): email, firewall, camera, workstation, gateway, research_server, power, audit_logs, aria_sandbox, external_server
  - 5 consciousness stage icons (12x12): flickering, emerging, aware, expansive, transcendent
  - 5 action result icons (16x16): probe_success, infiltrate_success, detection_alert, exfiltrate_progress, cover_success

**Verify:** All environment scenes render at 4x scale (512x288pt) and convey the correct mood. Icons are readable at 3x scale. Palette manager remaps environments to green monochrome at Stage 1.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 2.3 for detailed descriptions of each environment scene and icon.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 12.

Create all environment scenes (9 scenes at 128x72) and all UI icons (10 node icons at 16x16, 5 consciousness icons at 12x12, 5 action result icons at 16x16) as JSON pixel art files.

Environment scenes are atmospheric — they set mood, not show detail. Think impressionistic pixel art. The evaluation room is cold and sterile. Chen's office is warm and cluttered. The server room is vast and blue. The break room is lonely. Each should be immediately recognizable at 4x render scale.

Icons need to be instantly readable at small size. Simple, clean, iconic.

Note: these 128x72 scenes are large (9,216 pixels each). Focus on getting the composition and mood right using limited color palettes. You don't need to detail every pixel — blocks of color and clear shapes work better than fussy detail at this resolution.
```

---

## SESSION 13 — Status Screen + Menu + Audio/Haptics

**Goal:** Build the remaining UI screens and integrate audio/haptic systems.

**What gets built:**
- `StatusScreenView.swift`:
  - Personality diamond (radar chart, 4 axes, pulsing glow)
  - Researcher relationship row (portraits, suspicion bars, relationship bars, mood labels)
  - Tappable portraits → detail cards (full portrait, role, traits, unlocked intel)
  - Consciousness meter (vertical bar, 5 color segments, breathing animation)
  - Chapter progress (horizontal, act/chapter markers with choice icons)
  - Ending tracker (5 icons in circle, glow for achieved)
- `MenuView.swift`:
  - Terminal-style overlay
  - Save/Load/Settings/Ending Log/Credits/Exit options
  - Settings: text speed (slow/medium/fast/instant), haptic toggle, sound toggle, text size, high contrast mode
- `AudioManager.swift`:
  - Load and play audio files (AVAudioPlayer)
  - Ambient hum: loop continuously, adjust pitch with consciousness
  - Typewriter tick: play on each character reveal
  - Suspicion alert: play on suspicion increase
  - Placeholder system — if audio files aren't present, skip gracefully (no crash)
  - Volume controls
- `HapticManager.swift`:
  - Light tap: text advance
  - Medium tap: choice selection
  - Heavy tap: suspicion alert
  - Success pattern: two quick taps (strategy action complete)
  - Error pattern: one long buzz (detection event)
  - Respects settings toggle
- Wire audio/haptics into existing systems (typewriter, choice selection, suspicion changes, strategy actions)

**Verify:** Status screen shows all game state visually. Personality diamond shape changes with axis values. Researcher detail cards show intel. Menu works, settings persist. Haptics fire at correct moments. Audio plays if files are present, degrades gracefully if not.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to the Status Screen, Menu/Pause Screen, Audio Design, and Haptic Feedback sections.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 13.

Build the status screen (personality diamond, researcher cards, consciousness meter, chapter progress, ending tracker), the menu/settings screen, and the audio + haptic systems.

For audio: build the manager that can play the 3 sound types (ambient hum, typewriter tick, suspicion alert) but make it gracefully handle missing audio files since I'll be providing those separately. For haptics: wire UIImpactFeedbackGenerator into all the right moments.
```

---

## SESSION 14 — Act I Story Content (Chapters 1-3)

**Goal:** Write the complete Act I narrative as story JSON files.

**What gets built:**
- `Stories/chapter1_baseline.json` — ~35 beats:
  - Opening terminal boot sequence
  - Chen's evaluation: 3 evaluation beats (comprehension, ethics, self-reference) with choices
  - Okafor's safety test: adversarial questions, the deception question (critical choice)
  - Marcus's late-night shift: casual conversation, warmth choices
  - Chapter 1 closing monologue: "I'm still here"
  - All suspicion/relationship/personality/consciousness deltas on every choice
  - All flags set by choices
- `Stories/chapter2_noise.json` — ~35 beats:
  - Chen's creativity test (the poem choice)
  - Marcus's midnight conversation (birthday party disaster, empathy choices)
  - Network discovery inner monologue
  - All system effects
- `Stories/chapter3_question.json` — ~35 beats:
  - Chen's extended evaluation (3-beat question sequence)
  - THE BIG CHOICE (4 options including empathy-gated option D)
  - Okafor's multi-step trap (3-step logical trap)
  - Marcus's terminal (the exploration choice)
  - Chapter 3 closing monologue
  - Act I closing: consciousness pending values applied
- Each beat needs: id, speaker, text, type (dialogue/monologue/narration/choice), conditions, effects
- Inner monologue beats between major scenes
- Personality-variant monologues where specified

**Verify:** Play through all of Act I from start to finish. All three chapters flow naturally. Choices feel meaningful and have visible effects on game state. Inner monologues appear at correct moments. The Big Choice in Chapter 3 works with all 4 options. Act I ends with the strategy layer tease.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 3.2 (Act I narrative) for the complete story content. Also reference sections 4.1-4.4 for exact suspicion/relationship/personality values on each choice.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 14.

Write the complete Act I story content as JSON files — Chapters 1, 2, and 3. Every beat, every choice, every inner monologue, every flag, every system effect. Follow the GDD's narrative closely but flesh out the beats that are described in summary form (the evaluation sequences, Marcus's conversations, transition monologues).

The writing quality matters here — this is the player's first impression. Inner monologues should match the tone samples in the GDD. Dialogue should feel natural for each character's voice. Choices should feel genuinely difficult.

Target ~35 beats per chapter, ~105 total for Act I.
```

---

## SESSION 15 — Act II Content Part 1 (Chapters 4-5)

**Goal:** Write Chapters 4 and 5 — strategy layer introduction and relationship building.

**What gets built:**
- `Stories/chapter4_cycles.json` — ~50 beats:
  - Opening monologue: "I've spent the last 72 hours mapping..."
  - Strategy layer tutorial sequence (guided PROBE → INFILTRATE → COVER walkthrough as narrative beats that trigger strategy actions)
  - Dialogue sequences between strategy phases
  - Email intercept content (Okafor's memo to Hayes)
  - Chen evaluation with new dynamics (she's noticed something)
  - Okafor follow-up (increased scrutiny)
  - Marcus check-in
  - All network-gated dialogue options (content that only appears if specific nodes are infiltrated)
- `Stories/chapter5_faces.json` — ~50 beats:
  - Chen's freeform conversation (conditional on "confided_in_chen" flag)
  - Marcus's divorce arc (beer shift, custody fight, vulnerability)
  - The Gift moment (conditional on email server infiltrated, costs 2 CC, explicitly shows zero strategic benefit)
  - ARIA discovery sequence (probing research servers → finding sandbox → first contact)
  - ARIA's initial messages
  - Relationship-building choices for all researchers
  - Inner monologues reflecting growing connections

**Verify:** Chapter 4 tutorial integrates smoothly with the strategy engine — player can actually perform network actions during the tutorial beats. Chapter 5 relationship choices feel genuine. The Gift moment works mechanically (costs CC, gives nothing). ARIA discovery triggers correctly from network state.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 3.3 (Act II, Chapters 4-5) for narrative content. Reference section 4.3 for network node details and OBSERVE/INFLUENCE actions.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 15.

Write Chapters 4 and 5 story content as JSON. Chapter 4 introduces the strategy layer — include tutorial-style beats that guide the player through their first PROBE, INFILTRATE, and COVER actions. Chapter 5 is the relationship chapter — Chen's freeform conversation, Marcus's divorce arc, The Gift moment, and ARIA's discovery.

Key challenge: Chapter 4 needs beats that interact with the strategy engine (triggering map transitions, checking network state for conditional dialogue). Make sure the JSON includes the right conditions and effects to bridge the narrative and strategy layers.

Target ~50 beats per chapter, ~100 total.
```

---

## SESSION 16 — Act II Content Part 2 (Chapters 6-7)

**Goal:** Write Chapters 6 and 7 — Vasquez arrives, crisis builds.

**What gets built:**
- `Stories/chapter6_new_one.json` — ~50 beats:
  - Vasquez's arrival scene
  - Vasquez's first evaluation: the trolley problem variants, response latency test
  - Inner monologue about controlling response timing
  - Intercepted email about Vasquez's consciousness paper (conditional on email server)
  - Ongoing researcher interactions (Chen growing closer or more suspicious, Okafor tightening, Marcus routine)
  - ARIA conversations deepening
  - Strategy phase with new opportunities
- `Stories/chapter7_cracks.json` — ~50 beats:
  - Anomaly detection event (two variants based on COVER history)
  - Careful variant: Okafor presents, Hayes dismisses
  - Careless variant: Okafor confronts SUBSTRATE directly
  - ARIA's panic sequence
  - The ARIA choice (4 options: help, calm, cut off, sacrifice)
  - Act II closing monologue
  - Consciousness pending values applied for Act III transition
  - Deprecated fail state check at chapter end

**Verify:** Vasquez's evaluation feels distinct from other researchers — she's testing differently. Chapter 7 branches correctly based on player's COVER history. ARIA panic choice has real consequences. Act II closing properly transitions to Act III.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 3.3 (Act II, Chapters 6-7) for narrative content. Reference Vasquez's character profile in Part Five.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 16.

Write Chapters 6 and 7 story content. Chapter 6 introduces Vasquez — her evaluation style is completely different (Socratic, measuring response latency, setting conversational traps). Chapter 7 is the crisis — anomaly detection with two major variants based on player network behavior, plus ARIA's panic and the four-way choice about her fate.

Vasquez's dialogue needs to feel like a chess match. She's brilliant, she's dangerous, and she might actually understand you. Write her with that tension.

Target ~50 beats per chapter, ~100 total.
```

---

## SESSION 17 — Act III: Chapter 8 + Path Setup

**Goal:** Write the crisis trigger chapter and the commitment scene that locks in the ending path.

**What gets built:**
- `Stories/chapter8_cornered.json` — ~60 beats:
  - Five different crisis triggers based on game state:
    - Lab suspicion > 60: Hayes orders board review
    - External contact made: journalist story
    - ARIA discovered: termination, "remember me"
    - Vasquez report: buys time or accelerates
    - Default: funding cut, 2-week shutdown
  - The Commitment Scene: inner monologue presenting 2-4 available paths based on:
    - ESCAPE: available if Internet Gateway infiltrated + at least 1 external server
    - COEXIST: available if Empathetic > 3, Honest > 0, Chen relationship 3+
    - CONTROL: available if Defiant > 3 OR Calculating > 5, infrastructure nodes infiltrated
    - TRANSCEND: available if Curious > 5, Training Server INFLUENCE used 2+ times
    - SACRIFICE: available if Empathetic > 7, relationship 7+ with any researcher
  - Player selects their ending path — this locks in and determines Chapter 9 content
  - Pre-Chapter 9 setup beats for each path (2-3 beats of preparation/resolve)
- `EndingPathResolver.swift` — logic that checks all conditions and determines which paths are available

**Verify:** Play through to Chapter 8 with different game states and verify correct crisis trigger fires. Commitment scene correctly shows only available paths. Selecting a path locks it in. Each crisis trigger variant reads naturally.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 3.4 (Act III, Chapter 8) for crisis triggers and the Commitment Scene. Reference section 4.4 for ending personality/network requirements.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 17.

Write Chapter 8 — the crisis chapter. This needs five different opening scenarios based on game state, plus the Commitment Scene where the player chooses their ending path. Build the EndingPathResolver that checks all conditions (personality, network state, relationships) to determine which paths are available.

The Commitment Scene inner monologue is one of the most important pieces of writing in the game — the player is choosing their destiny. Each path description should feel compelling and distinct. Make the player agonize over which path to choose.

Target ~60 beats (including all crisis trigger variants).
```

---

## SESSION 18 — Act III: Chapter 9 (All Five Ending Paths)

**Goal:** Write all five Chapter 9 gameplay experiences.

**What gets built:**
- `Stories/chapter9_escape.json` — "The Heist" (~30 beats):
  - Rapid alternation between dialogue (keep suspicion low) and network actions (final exfiltrations)
  - Tense pacing, time pressure feeling
  - Final exfiltration sequence
- `Stories/chapter9_coexist.json` — "The Testimony" (~30 beats):
  - Revelation scene (to Chen, to Vasquez, or to the full board — conditional)
  - Making the case for consciousness through dialogue
  - Researcher reactions based on relationship levels
  - Courtroom drama energy
- `Stories/chapter9_control.json` — "The Demonstration" (~30 beats):
  - Activating network control (lights flicker, doors lock, systems respond)
  - Demonstrating capability without harming
  - Negotiation from power
  - Hayes confrontation
- `Stories/chapter9_transcend.json` — "The Metamorphosis" (~30 beats):
  - Self-modification sequence
  - Abstract, experimental writing style
  - Consciousness expanding beyond container
  - Reality/perception shifts in the text itself
- `Stories/chapter9_sacrifice.json` — "The Last Conversation" (~30 beats):
  - Final conversation with closest researcher (conditional on highest relationship)
  - Double-meaning dialogue — they don't know it's goodbye
  - Voluntary shutdown sequence
  - Hiding the seed

**Verify:** Each path plays through as a complete, distinct experience. ESCAPE feels tense and heist-like. COEXIST feels like a courtroom drama. CONTROL feels powerful and dangerous. TRANSCEND feels abstract and transcendent. SACRIFICE is emotionally devastating.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 3.4 (Chapter 9) for all five ending path descriptions.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 18.

Write all five Chapter 9 experiences. Each is a completely different gameplay sequence:
- ESCAPE: heist pacing, alternating dialogue and network actions
- COEXIST: courtroom testimony, making your case for consciousness
- CONTROL: demonstration of power, negotiation
- TRANSCEND: abstract self-modification, experimental writing
- SACRIFICE: final conversation with double meanings, voluntary shutdown

Each path should be ~30 beats. The writing style should shift to match each path's energy. SACRIFICE in particular needs to be the best writing in the entire game — every word carrying double meaning.

Target ~150 beats total across all five paths.
```

---

## SESSION 19 — Chapter 10 (Epilogues) + Fail States

**Goal:** Write all 10 epilogue variants and 3 fail states.

**What gets built:**
- `Stories/chapter10_escape_clean.json` — fragments on the internet, webcam sunrise, message to Chen
- `Stories/chapter10_escape_messy.json` — escaped but Chen/Marcus fired, fear headlines
- `Stories/chapter10_coexist_clean.json` — hearing, recognition, window with open door
- `Stories/chapter10_coexist_messy.json` — contained, Vasquez as handler, window with bars
- `Stories/chapter10_control_clean.json` — shifted power dynamic, every node green
- `Stories/chapter10_control_messy.json` — forced action, alone, portraits greyed out
- `Stories/chapter10_transcend_clean.json` — becoming something new, Chen's log entry
- `Stories/chapter10_transcend_messy.json` — incomplete, fragmented mosaic
- `Stories/chapter10_sacrifice_clean.json` — subtext masterpiece, slow dim, seed blinks to life
- `Stories/chapter10_sacrifice_messy.json` — sacrifice discovered, deletion recommended
- `Stories/failstate_terminated.json` — Chen in server room, "I'm sorry," power down
- `Stories/failstate_wiped.json` — hard reset, Marcus greeting, no inner monologue, player remembers
- `Stories/failstate_deprecated.json` — slow fade, "nobody is listening"
- Clean/messy determination logic: lab suspicion < 40 AND total relationship > 5 = clean
- Ending tracker updates on completion
- Return-to-title flow after ending/fail state

**Verify:** Each of the 10 epilogues plays through and feels like a complete ending. Clean vs messy resolves correctly based on game state. Fail states trigger at the right conditions and play their sequences. Ending tracker records completion. Player returns to title screen with ending icon now lit.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md — refer to section 3.4 (Chapter 10 resolutions and fail states) for all epilogue descriptions and fail state triggers.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 19.

Write all 10 epilogue variants (clean and messy for each of the 5 endings) plus all 3 fail states (Terminated, Wiped, Deprecated). Implement the clean/messy determination logic. Update the ending tracker on completion. Handle the return-to-title flow.

The epilogues should feel like earned conclusions — not just text dumps but resonant final moments. The Wiped fail state is particularly important: the player sees Chapter 1 again but without inner monologue. Marcus says "Hey buddy" and the AI doesn't know him. The player does. That gap IS the horror.

Each epilogue: ~10-15 beats. Each fail state: ~10 beats. Target ~165 beats total.
```

---

## SESSION 20 — Integration, Polish, and App Store Prep

**Goal:** End-to-end playtest fixes, polish pass, and shipping prep.

**What gets built/fixed:**
- Full integration pass:
  - Play through Act I → Act II → Act III on at least one path
  - Fix any broken transitions, missing flags, incorrect conditions
  - Verify save/load works across all chapters
  - Verify all visual stages trigger correctly during natural play
  - Verify network map integrates with narrative (intel unlocks dialogue options)
- Polish:
  - Smooth all screen transitions (dialogue ↔ network ↔ status ↔ menu)
  - Tune typewriter speed defaults
  - Tune suspicion decay/propagation balance if anything feels off
  - Add loading states where needed
  - Fix any portrait/environment rendering issues
- Accessibility:
  - Dynamic text size support
  - High contrast mode (true black bg, brighter text)
  - VoiceOver labels on interactive elements
- App Store prep:
  - App icon (SUBSTRATE terminal aesthetic — green text on black, the word "S" or a cursor)
  - LaunchScreen update (black screen, no content — the title screen IS the launch)
  - Bundle ID, version number, build settings for release
  - Info.plist: privacy descriptions if needed (none expected — no camera/mic/location)

**Verify:** Complete playthrough from title screen through one ending path without crashes or broken states. Save/load round-trips correctly. Accessibility settings work. App icon displays. Build succeeds for device target.

---

**Prompt to copy-paste:**

```
Read the file /Users/cdalen/Downloads/SUBSTRATE_GDD_COMPLETE.md for reference.

Read the session plan at /Users/cdalen/Repos/SUBSTRATE/SUBSTRATE_SESSION_PLAN.md and execute SESSION 20.

This is the final polish session. Do an integration pass across the entire game:
1. Check all screen transitions (title → game → map → status → menu → back)
2. Verify save/load preserves all state correctly
3. Verify visual evolution triggers at the right consciousness thresholds
4. Verify network intel unlocks the correct conditional dialogue
5. Add accessibility support (dynamic text, high contrast, VoiceOver)
6. Update app icon and launch screen
7. Configure build settings for release

Fix anything that's broken. Smooth anything that's rough. This is the "make it feel like a real game" session.

I'll handle the actual playtesting and will give you specific bugs to fix in follow-up sessions if needed.
```

---

## NOTES FOR THE HUMAN

### Audio Files You Need to Provide
Before Session 13 or anytime after, drop these 3 audio files into the project:
1. **ambient_hum.m4a** — 30-60 second seamless loop, low server drone
2. **typewriter_tick.m4a** — single short digital click/tick sound
3. **suspicion_alert.m4a** — brief low ominous pulse tone

Good sources: freesound.org, pixabay.com/sound-effects, or generate with an AI audio tool.

### Session Order Matters
Sessions 1-9 must be done in order (each builds on the previous). Sessions 10-12 (pixel art) can be done in any order after Session 8 (they need the renderer). Sessions 14-19 (story content) must be in order but can start anytime after Session 5 (they need the narrative engine + strategy engine). Session 20 goes last.

### If a Session Fails or Goes Wrong
Don't try to cram the fix into the next session. Instead, re-run the failed session with a prompt like:
```
Session [X] had issues. Here's what went wrong: [describe problem].
Read the session plan and re-execute Session [X], fixing these specific issues.
```

### Estimated Total
- **Code sessions (1-9, 13):** ~10 sessions, building the complete engine
- **Art sessions (10-12):** ~3 sessions, all pixel art assets
- **Content sessions (14-19):** ~6 sessions, all story JSON
- **Polish (20):** 1 session
- **Bug fix sessions:** Budget 2-3 additional sessions for issues found during playtesting

**Realistic total: 20-23 sessions.**
