# Character Portraits — Kaster's War

วางไฟล์ portrait ตัวละครในโฟลเดอร์นี้ GDD (`design/gdd/kasters-war-gdd.md` §8.2–8.3)
ลิงก์มาที่นี่ด้วย path ตายตัว — ชื่อไฟล์ต้องตรงตามตารางด้านล่าง

## Naming Convention

Art Bible §8.2 naming convention (supersedes this file if there is any conflict):

- Base portrait: `char_[officer-slug]_base_portrait.png`
- Defeat portrait: `char_[officer-slug]_defeat_portrait.png`
- Campaign icon: `char_[officer-slug]_icon.png`
- Tactical hex sprite: `char_[officer-slug]_sprite_hex.png`

`[officer-slug]` = lowercase, hyphen-separated. Must match the slug column below exactly.

## Expected Files — Named Officers

| Officer slug | ตัวละคร | ฝ่าย | Base portrait | Defeat portrait |
|---|---|---|---|---|
| `kaster` | Kaster | Kaster | ⬜ รอรูป | ⬜ รอรูป |
| `bon-shi-hai` | Bon shi hai | Kaster | ⬜ รอรูป | ⬜ รอรูป |
| `alexsen` | Alexsen | Kaster | ⬜ รอรูป | ⬜ รอรูป |
| `thane` | Thane | Kaster | ⬜ รอรูป | ⬜ รอรูป |
| `zhuge-jian` | Zhuge Jian | Kaster | ⬜ รอรูป | ⬜ รอรูป |
| `jin-tao` | Jin Tao | Kaster | ⬜ รอรูป | ⬜ รอรูป |
| `sander` | Sander | Kaster | ⬜ รอรูป | ⬜ รอรูป |
| `king-lycurse` | King Lycurse | ศัตรู | ⬜ รอรูป | ⬜ รอรูป |
| `boreas` | Boreas (แม่ทัพผู้ทรยศ) | ศัตรู | ⬜ รอรูป | ⬜ รอรูป |

Generic officers (~25–30 คน) ใช้ pattern: `char_generic_[archetype]_[variant]_portrait.png`
— โครงสร้างรอกำหนดหลังออกแบบระบบ generic officer archetype (~8–10 archetypes, 2–4 variants each)

## Image Spec (from Art Bible §5, §8.3)

**Canvas:** 512×640px — non-negotiable. Portrait frame aspect ratio must be maintained across all LODs.

**Format (deliverable):** PNG, sRGB, 8-bit, no alpha channel. Background SW-04 Pale Administrative (`#D4C9B0`) is authored into the texture — not transparent. `premult_alpha=true` set in Godot `.import` to eliminate fringing.

**Style:** RoTK13 semi-realistic painterly. Textured brushwork with legible form. Edges hard where form competes for read (face, identifying costume element, silhouette interruption), soft where receding. Not photorealistic, not cartoon.

**Composition:** Bust-up, three-quarter facing. Officer attends to something off-screen — never facing viewer directly. SW-04 Pale Administrative background at consistent low contrast. No vignette, no gradient, no environmental backdrop.

**Class signal:** SW-05 Sash Crimson (`#8B2635`) must appear somewhere on every player officer (placement varies by character). Enemy officers carry SW-06 Burnt Sienna (`#6B3D2E`) as structural anchor instead.

**Defeat state:** Same canvas, same composition, same lighting as base. Expression: post-action recognition — eyes not focused on viewer; focused on the fact of the loss.

**Engine compression:** BC7 (BPTC), mip maps OFF. `compress/high_quality=true` required — BC1/BC3 produces visible blocking on painterly brush edges.

**Reference:** [Art Bible §5](../../design/art/art-bible.md#section-5-character-design-direction-) (character direction) · [Art Bible §8.3](../../design/art/art-bible.md#83-texture-resolution-and-compression) (compression spec)
