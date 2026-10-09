# RogueFightersArena

Game fighting 2D (Godot 4.7): duel samurai vs shinobi di arena, best-of-3 ronde.

## Cara main

1. Buka project ini di Godot 4.x, tekan **F5** (atau tombol Play).
2. Di menu utama pilih:
   - **1 PLAYER** — melawan AI (pilih kesulitan: MUDAH / NORMAL / SUSAH)
   - **2 PLAYERS** — versus 2 orang di keyboard yang sama
   - Pilih karakter **SAMURAI** / **SHINOBI** untuk tiap pemain
3. Menangkan **2 ronde** untuk jadi juara. Tiap ronde 60 detik; kalau waktu habis,
   petarung dengan nyawa terbanyak menang ronde itu.

### Kontrol Pemain 1

| Tombol | Aksi |
|---|---|
| A / D | Gerak kiri-kanan |
| Spasi | Lompat |
| S | Block / nangkis (tahan) |
| J / K / L | Serangan 1 / 2 / 3 |

### Kontrol Pemain 2 (mode versus)

| Tombol | Aksi |
|---|---|
| Panah kiri / kanan | Gerak |
| Panah atas | Lompat |
| Panah bawah | Block / nangkis (tahan) |
| , / . / / | Serangan 1 / 2 / 3 |

**ESC** = pause.

## Fitur

- Menu utama + layar "Cara Main"
- Pilih karakter (Samurai / Shinobi) dan kesulitan AI
- Mode 1 pemain (vs AI) dan 2 pemain (versus lokal)
- Sistem ronde best-of-3, timer 60 detik, dan aturan seri
- Efek: partikel pukulan, screen shake, hit-stop, slow-motion K.O.
- Musik latar + efek suara (dibuat prosedural, lihat `tools/gen_audio.py`)
- Background arena berganti tiap ronde

## Struktur kode

- `fighters/fighter.gd` — fisik, nyawa, serangan, dan ganti karakter
- `HumanController.gd` — input keyboard (prefix `p1` / `p2`)
- `ai_controller.gd` — otak musuh (agresivitas, reaksi, tangkis)
- `arenas/arena_test.gd` — aturan ronde, timer, pause, game over, efek
- `scripts/game_state.gd` — (autoload) pilihan dari menu utama
- `scripts/audio_manager.gd` — (autoload) SFX & musik
- `scripts/main_menu.gd`, `scripts/how_to_play.gd` — UI menu
- `tests/smoke.gd` — smoke test headless (`godot --headless --path . --script res://tests/smoke.gd`)
