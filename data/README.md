# data/ — Resource .tres RFA (GDD v2.0 §6)

Data statis terpisah dari logika. `fighter.gd` membaca
`data/characters/<id>.tres` di `set_character()` dan jatuh kembali ke
dict `CHARACTERS` bila file tidak ada (frame/anim_fix/sprite_scale
tetap di `CHARACTERS`).

## File

- `character_data.gd` — `class_name CharacterData extends Resource`:
  `id, display_name, country, style, bio, hp, dmg, spd, trait_id,
  trait_desc, portrait_anim="idle", folder`.
- `chapter_data.gd` — `class_name ChapterData extends Resource`:
  `id, title, arena_bg, stages: Array[String], boss_id`.
- `characters/` — 21 `.tres`: 12 protagonis + 6 musuh
  (`buruh_bayaran, penyelundup, geng_jalanan, akrobat, murid_dojo,
  pengawal_elit`) + 3 boss (`kapten_brak, ular_neon, guru_sunyi`).
  Alaric Voss TIDAK dibuat.
- `chapters/` — 3 `.tres`: `ch1` Dermaga (buruh_bayaran,
  penyelundup, buruh_bayaran → kapten_brak), `ch2` Lorong Neon
  (geng_jalanan, akrobat, geng_jalanan → ular_neon), `ch3` Dojo
  Bayangan (murid_dojo, pengawal_elit, murid_dojo → guru_sunyi).

## Catatan

- Stat protagonis di `.tres` SAMA PERSIS dengan dict `CHARACTERS`
  di `fighter.gd` (jangan ubah satu sisi saja).
- `trait_id` dikenali `fighter.gd`: `none, shinobi_swift,
  arga_stance, marco_lowkick, dmitri_throw, lin_combo, nok_close,
  sora_counter, tyrone_jab, han_longkick, valeria_air, anika_flex`;
  musuh pakai `generic` (tanpa efek), boss pakai `boss_charge /
  boss_hitrun / boss_counter` (deskriptif saja — perilaku boss
  diatur `ai_controller.boss_pattern`).
- Folder musuh = palette swap (GDD v2.0 §7): memakai ulang folder
  karakter yang sudah ada; sprite asli musuh/boss belum ada
  (boss saat ini jatuh ke sprite samurai).
- `arena_bg` chapter masih kosong — background chapter belum ada
  di `assets/` (diisi subagent arena saat asetnya tersedia).
- Regenerasi: `godot --headless --path . --script /tmp/gen_data.gd`
  (skrip generator disimpan di luar repo, di `/tmp`).
