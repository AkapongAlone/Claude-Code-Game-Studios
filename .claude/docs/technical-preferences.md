# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Forward+ (PC target, stylized 3D / 2D hybrid)
- **Physics**: Jolt (default in 4.6)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Steam)
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial (เมนู + camera pan — ไม่ใช่ core UX)
- **Touch Support**: None
- **Platform Notes**: Standard PC UX. เมนูทุกจอต้องรองรับ keyboard navigation ด้วย

## Naming Conventions

- **Classes**: PascalCase (e.g., `CampaignManager`)
- **Variables/Functions**: snake_case (e.g., `move_speed`, `take_damage()`)
- **Signals**: snake_case past tense (e.g., `health_changed`, `turn_ended`)
- **Files**: snake_case matching class (e.g., `campaign_manager.gd`)
- **Scenes**: PascalCase matching root node (e.g., `CampaignManager.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_INTEL_LEVEL`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6 ms
- **Draw Calls**: ≤300 per frame (PC turn-based — UI-heavy, low real-time load)
- **Memory Ceiling**: 1.5 GB RAM

## Testing

- **Framework**: GUT (Godot Unit Testing)
- **Minimum Coverage**: 80% สำหรับ gameplay systems
- **Required Tests**: Balance formulas, campaign/tactical state machines, AI behavior

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions and ADR validation. Invoke GDScript specialist for code quality, signal architecture, static typing, and GDScript idioms. Invoke shader specialist for material and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
