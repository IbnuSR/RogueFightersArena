# Catatan Aset — Musuh & Boss RFA (placeholder palette-swap)

Tanggal: 2026-11-11. Repo: `github-latest` (commit 964c7be).
Data registrasi lengkap: `tools/enemy_manifest.json`.
Generator (tidak disimpan di repo, hanya di /tmp): hue-shift HSV deterministik
per tipe, alpha dipertahankan persis — geometri, bbox, dan flip basis utuh.

## Yang PLACEHOLDER (palette-swap, butuh artis tim)

Semua 9 karakter baru di bawah ini adalah gambar karakter lama yang
warnanya digeser. Siluet, pose, dan gerakan = karakter basisnya.
**Hue-shift menggeser SEMUA warna termasuk kulit** (mis. Ular Neon
kulitnya ikut hijau) — itu ciri placeholder, bukan art final.

| id | Basis | Hue | Folder |
|---|---|---|---|
| buruh_bayaran | Dmitri (besar/berat) | +30° | `assets/fighters/fighter_buruh/` |
| penyelundup | Marco (cepat) | +150° | `assets/fighters/fighter_penyelundup/` |
| geng_jalanan | Tyrone | +200° | `assets/fighters/fighter_geng/` |
| akrobat | Han — dipilih karena tendangan akrobatiknya paling lebar (attack_2 267px, attack_3 228px), bukan Lin | +90° | `assets/fighters/fighter_akrobat/` |
| murid_dojo | Sora | −50° | `assets/fighters/fighter_murid/` |
| pengawal_elit | Samurai (frame_h 128, bukan 256) | +180° | `assets/fighters/fighter_pengawal/` |
| kapten_brak | Dmitri (9 animasi); idle ASLI, lihat bawah | +210° | `assets/bosses/boss_kapten_brak/` |
| ular_neon | Anika | +100°, sat ×1.35, val ×1.08 | `assets/bosses/boss_ular_neon/` |
| guru_sunyi | Lin | 0°, sat ×0.25, val ×0.72 (abu-abu gelap) | `assets/bosses/boss_guru_sunyi/` |

Alaric Voss (Chapter 4) **TIDAK dibuat** — sesuai penugasan.

Masing-masing 10 animasi lengkap (idle, walk, run, jump, attack_1/2/3,
shield, hurt, dead), satu strip PNG horizontal per animasi, latar transparan.
Skala diukur dari bbox alpha tiap frame (tinggi badan median idle → ~240px
di layar, kaki menapak di feet_y median idle). `anim_fix` di manifest
dihitung dengan rumus `tools/normalize_anim_size.py` / `process_arga_v2.py`
(faktor tinggi & luas vs idle, clamp [0.75, 1.35], run [0.90, 1.15]).

Flip lama yang dipertahankan (file basis disalin apa adanya, tidak diubah):
Marco shield, Tyrone hurt, Han attack_3 frame 5–10 — tetap benar di
penyelundup, geng_jalanan, dan akrobat.

## Yang ASLI (bukan palette-swap)

### Kapten Brak — idle asli, 9 animasi lain swap
- `assets/bosses/boss_kapten_brak/kapten_brak_idle.png` **COCOK dan DIPAKAI**
  sebagai `idle.png` (disalin, file aslinya tidak diubah): strip 2560×256,
  10 frame × 256px, latar transparan, satu karakter utuh per frame
  (kapten botak berotot, mantel hijau, memegang jangkar), kaki konsisten
  di y=256 semua frame, tinggi badan median 121px (kecil di dalam frame —
  makanya `sprite_scale` idle 1.983, bukan ~1.13).
- 9 animasi lain (walk/run/jump/attack_1-3/shield/hurt/dead) = palette-swap
  Dmitri hue +210° (navy, senada mantel kapten). Konsekuensi placeholder:
  animasi lain TIDAK memegang jangkar, dan `anim_fix`-nya dihitung terhadap
  idle Dmitri (bukan idle Kapten) karena skala kedua art itu berbeda jauh.
- `assets/bosses/boss_kapten_brak/kapten b idle.png` **TIDAK dipakai**:
  file 768×325 itu BUKAN strip horizontal melainkan sheet grid 5×2
  (10 pose), tinggi 325px ≠ frame_h 256, dan sel grid ~153,6px (bukan
  bilangan bulat — frame akan berdarah ke tetangga). Isinya karakter yang
  sama dengan `kapten_brak_idle.png`, jadi tidak ada yang hilang.

## Yang masih ASLI dari sebelum tugas ini (jangan tertukar)
- Semua strip di `assets/fighters/fighter_*` (12 karakter pemain) dan file
  `kapten_brak_idle.png` / `kapten b idle.png` di atas — TIDAK ada satu pun
  file basis yang diubah (dicek `git status`: hanya file baru, 0 file
  termodifikasi).
- Scene boss `fighters/Boss*.tscn` masih placeholder sprite samurai —
  wiring aset baru ke game BUKAN bagian tugas ini.

## Verifikasi (2026-11-11)
- 90 PNG baru dicek dengan PIL: lebar = jumlah_frame × lebar_frame,
  tinggi = frame_h, tiap frame punya piksel non-transparan → 0 masalah.
- Tinggi badan layar idle semua karakter: 239,9–240,0px (target ~240px).

## Background chapter (11 Nov 2026, aset AI)
- `assets/backgrounds/dermaga.png` (Ch1 Dermaga), `lorong_neon.png` (Ch2 Lorong Neon),
  `dojo_bayangan.png` (Ch3 Dojo Bayangan). Dihasilkan dengan generator gambar AI
  (2048x1152), lalu di-upscale Lanczos ke 3840x2160 agar sama dengan 4 latar lama.
- Ter-wire: `data/chapters/ch1-ch3.tres` -> `arena_bg`; `arenas/arena_test.gd`
  `_set_background()` memakai background chapter saat `GameSession.arena_id`
  diisi (mode Story), dan TIDAK lagi memutar latar tiap ronde di Story Mode.
  Mode bebas tetap memakai 4 latar lama yang berputar.
- Tes: `tests/chapter_bg.gd` (17 cek) + render xvfb 3 chapter, kaki petarung
  menapak di lantai latar. Catatan: latar ini gambar AI (bukan artis tim),
  dan petarung tetap sprite pixel-art — gaya keduanya tidak 100% sama.

## Gambar menu utama & perintilan (11 Nov 2026, aset AI + crop)
- `assets/backgrounds/main_menu.png` — key art menu utama (pesilat
  selendang merah vs samurai bayangan, ungu/emas), generator gambar AI
  (2048x1152) lalu upscale Lanczos ke 3840x2160. Dipakai sebagai BG
  `scenes/main_menu.tscn` (skala sprite 0.3334 = 1280 px lebar).
- `assets/ui/thumbs/ch1.png` (Dermaga), `ch2.png` (Lorong Neon),
  `ch3.png` (Dojo Bayangan) — 640x360, resize langsung dari latar chapter
  (sudah 16:9), dipakai di kartu peta chapter.
- `assets/ui/portraits/<id>.png` — 22 potret (12 protagonis + 6 musuh +
  4 boss), crop frame 0 strip idle lalu trim transparan dan resize ke
  tinggi 200 px, dipakai di layar pilih karakter.

## Chapter 4 + aset boss asli (11 Nov 2026, disesuaikan ulang ke GDD v2.0 §4)
- GDD Master v2.0 §4: 4 chapter — Dermaga, Lorong Neon, Dojo Bayangan,
  **Menara Voss** (boss Alaric Voss, "mengkombinasi jurus 3 boss
  sebelumnya"). Musuh biasa per chapter: Ch1 Buruh/Penyelundup, Ch2
  Geng/Akrobat, Ch3 Murid Dojo saja (counter), Ch4 Pengawal Elit saja.
  Sebelumnya Ch3 salah menaruh Pengawal Elit & Ch4 belum ada — diperbaiki.
- `assets/backgrounds/menara_voss.png` (Ch4, atap menara badai + petir,
  AI 2048x1152 -> upscale 3840x2160) + `assets/ui/thumbs/ch4.png`.
- **Boss bukan lagi palette-swap.** 4 boss kini punya badan sendiri:
  - Ular Neon, Guru Sunyi, Alaric Voss: gambar AI full-body (pixel-art,
	green-screen) di-key jadi transparan, lalu 10 animasi per boss
	dibangun prosedural dari 1 gambar badan itu
	(`tools/build_boss_strips.py`: bob idle, lunge serang, lompat,
	rebah mati). Badan 220 px di frame 320x256, sprite_scale 1.091.
  - Kapten Brak: idle tetap strip ASLI 10 frame miliknya; 9 animasi lain
	dibangun prosedural dari frame 0 idle itu (badan 115 px,
	sprite_scale 1.983, sama seperti idle aslinya).
  - Karena geometri tiap boss seragam di semua animasinya, entri boss di
	`fighters/fighter.gd` TIDAK lagi memakai `anim_fix` (pakai
	base_scale/base_pos_y). Frame baru: idle 6 (Brak 10), walk 8, run 8,
	jump 12, attack_1 7, attack_2 5, attack_3 3, shield 2, hurt 2,
	dead 3 — semua frame_w 320 (idle Brak 256).
  - Potret 4 boss di-regenerate dari idle frame 0 aset baru.
- JUJUR: animasi boss prosedural (badan utuh digeser/diputar) — bukan
  animasi gambar-tangan per frame. Kaki/tangan tidak bergerak sendiri
  seperti sprite protagonis. Ini selangkah di atas palette-swap (badan
  & siluet kini beda tiap boss), tapi artis tim tetap bisa mengganti
  tiap strip dengan gambar tangan kapan saja (format strip sama).
- Voss di arena: fase 1 pola charge (Brak); saat HP <= 50% (FASE 2)
  pola ganti hit & run (Ular) + peluang menangkis naik 0.5 (Guru).
- Musuh biasa yang sama 3x per chapter kini makin kuat: +10% HP per
  stage (`_apply_stage_scaling`, berlaku juga saat Rematch).
