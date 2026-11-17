# Status Story Mode & Mekanik GDD v2.0 — 11 Nov 2026

Ringkasan jujur apa yang jadi, apa yang placeholder, dan apa yang TIDAK jadi
beserta alasannya. Jangan klaim lebih dari yang tertulis di sini.

## Yang JADI (teruji)

- **Story Mode bisa dimainkan penuh (commit terbaru).** Alur: Menu Utama
  (tombol MODE CERITA + gambar main menu baru) -> Peta Chapter (4 kartu
  dengan thumbnail latar, nama musuh & boss, status terkunci/terbuka) ->
  Pilih Karakter (potret, bio, gaya, statistik HP/DMG/SPD dari .tres) ->
  Arena: 4 stage per chapter (stage 1-3 musuh biasa 1 ronde, stage 4 boss
  2 fase dengan banner FASE 2 saat HP <= 50%). Menang stage -> lanjut
  stage berikutnya; kalah -> ulangi stage yang sama; kalahkan boss ->
  "CHAPTER SELESAI!", chapter berikutnya terbuka, boss & musuh yang
  dikalahkan terbuka sebagai karakter playable. Progres tersimpan di
  user://progress.save (ProgressManager): chapter selesai, karakter
  terbuka, volume.
- **Pola AI boss akhirnya aktif.** Sebelumnya tidak ada yang menyetel
  `boss_pattern` di AIController, jadi pola charge/hitrun/counter tidak
  pernah jalan. Sekarang arena menyetelnya dari trait_id .tres boss
  (Kapten Brak = charge, Ular Neon = hitrun, Guru Sunyi = counter,
  Alaric Voss = charge di fase 1, ganti hitrun + sering menangkis di
  fase 2).
- **Layar Pengaturan:** volume musik & SFX (langsung diterapkan ke Audio
  dan disimpan) + hapus progres (tekan 2x). Menu lama ui/main_menu.tscn
  yang tadinya rusak (nama node tidak cocok dengan script: StoryModeButton
  vs %StoryButton, FreeBattleButton vs %FreeFightButton, ToastLabel tidak
  ada) sudah diperbaiki namanya.
- **Aset musuh (palette-swap, sesuai GDD §7) & boss (badan asli).**
  6 musuh × 10 animasi hue-shift dari sprite yang sudah ada. 4 boss kini
  punya badan sendiri — Ular Neon, Guru Sunyi, Alaric Voss dari gambar
  AI full-body; Kapten Brak dari frame 0 idle aslinya — dengan 10
  animasi prosedural per boss (`tools/build_boss_strips.py`).
  Manifest musuh: `tools/enemy_manifest.json`.
  Detail aset & basis: `docs/ASSET_NOTES.md`.
- **Wiring musuh & boss ke game.** 10 id baru di `CHARACTERS`
  (`fighters/fighter.gd`): buruh_bayaran, penyelundup, geng_jalanan,
  akrobat, murid_dojo, pengawal_elit, kapten_brak, ular_neon, guru_sunyi,
  alaric_voss. Masing-masing 10 animasi, `dead` tidak looping, skala
  badan ~240 px di layar. Data stat di `data/characters/*.tres`
  (22 karakter) + `data/chapters/*.tres` (4 chapter).
- **Mekanik GDD v2.0** (`fighters/fighter.gd`, `HumanController.gd`,
  `ai_controller.gd`): hitstun + knockback, blockstun + chip damage
  (attack_3 yang ditangkis = 2 HP, tidak bisa membunuh), kombo dengan
  damage scaling, meter + jurus spesial, throw (menembus block),
  jongkok (state terpisah dari block), 12 trait protagonis
  (termasuk dua kuda-kuda Arga yang berganti tiap berhasil menangkis),
  pola AI boss (`boss_pattern`: charge/hitrun/counter, `phase2`).
- **Input action baru** di `project.godot`: `p1_special` (U),
  `p2_special` (N), `p1_throw` (I), `p2_throw` (M),
  `p1_crouch` (Panah Bawah), `p2_crouch` (Numpad 0).
  Crouch P1 TIDAK bisa S karena S sudah `p1_block`.
- **Background chapter (AI).** `assets/backgrounds/dermaga.png`,
  `lorong_neon.png`, `dojo_bayangan.png`, `menara_voss.png` (3840x2160,
  upscale dari 2048x1152), ter-wire via `data/chapters/*.tres` arena_bg.
- **Gambar menu utama (AI) + perintilan.** `assets/backgrounds/main_menu.png`
  (pesilat selendang merah vs samurai bayangan, ungu/emas, 3840x2160),
  thumbnail chapter `assets/ui/thumbs/ch1-ch4.png` (640x360, crop latar),
  potret karakter `assets/ui/portraits/<id>.png` (22 file, crop frame 0
  animasi idle, tinggi 200 px) untuk layar pilih karakter.
- **Tes baru** `tests/story_mode.gd`: ~99 cek (ProgressManager save/load +
  unlock, menu utama, peta chapter, pilih karakter, pengaturan, arena
  Story stage 1 & boss, maju stage, boss -> chapter selesai, Ch4 + Voss,
  scaling stage) — SEMUA LOLOS. Tes lama tetap lolos:
  sprite_sync 144, smoke ~535, mechanics 134+, chapter_bg 21,
  dead_no_loop 156, ai_battle exit 0.

## Placeholder (jujur, butuh artis tim / kerja lanjutan)

- Musuh biasa tetap palette-swap (sesuai GDD v2.0 §7: palette swap
  memang cara yang diminta dokumen untuk musuh biasa). Boss SUDAH punya
  badan sendiri (lihat ASSET_NOTES.md § Chapter 4) — tapi animasinya
  prosedural, bukan gambar-tangan per frame. Jongkok memakai pose
  `shield` (belum ada strip jongkok). Tidak ada BGM baru (2 BGM lama
  dipakai ulang). SFX baru belum dibuat. Gambar latar & menu utama
  adalah gambar AI (bukan artis tim), gaya tidak 100% sama dengan
  sprite pixel-art.

## Yang TIDAK jadi — dan kenapa

- **Dialog/cutscene cerita** sebelum & sesudah duel belum ada (baru judul
  chapter + nama musuh/boss di kartu). **Kontrol sentuh** belum ada
  (keyboard saja). **export_presets.cfg Android** belum dibuat (butuh
  template Android yang tidak ada di VM ini). **Mode 2P** masih
  disembunyikan dari menu lama (kodenya ada, tombolnya tidak ditampilkan).
