# Naves Arcade

Demo jugable de **arcade espacial 2D** multiplataforma (iOS / Android / Web / escritorio), hecha con **Flutter + Flame**.

Motor: **Flame** (`HasCollisionDetection`, componentes procedurales, ~60 FPS).

## Características

- Nave del jugador con **joystick virtual** y **arrastre táctil**
- Disparo por **toque / mantener** en el lado derecho
- Enemigos (scout, zig-zag, tanque) con dificultad progresiva
- Colisiones: balas ↔ enemigos, enemigos ↔ jugador
- **Puntos**, **vidas**, **combo / multiplicador**, **game over** y reinicio
- Power-ups: **ráfaga**, **escudo**, **multi-disparo**
- Partículas / explosiones, **screen shake** y tema neón espacial
- **Pausa**, récord con `shared_preferences`, hápticos en móvil
- **Gameplay sincronizado** con BGM (actos, energía, patrones de fuego)

## Cómo ejecutar

```bash
flutter pub get
flutter run
```

Opciones útiles:

```bash
flutter run -d chrome      # web
flutter run -d linux       # escritorio (requiere toolchain)
flutter build web          # build de producción web
```

## Controles

| Acción | Cómo |
|--------|------|
| Mover | Arrastra en la mitad izquierda o usa el joystick |
| Disparar | Toca / mantén en la mitad derecha |
| Escudo lento (A) | Mantén el botón **N** (derecha) — carga acumulativa |
| Onda destructiva (B) | Mantén el botón **M** (derecha) — gasta munición |
| Pausar | Botón ⏸ en el HUD |
| Mover (web) | **WASD** (A izquierda, D derecha, W arriba, S abajo) |
| Disparar (web) | **Espacio** (mantener) |
| Escudo / Onda (web) | Mantén **N** / **M** |

En web, teclado y arrastre/toque funcionan a la vez. El joystick táctil se mantiene en móvil.


## Sincronía con la banda sonora

El gameplay sigue la BGM (`bgm_01`–`bgm_04`) por **actos** y ritmo.

**Enfoque:** pre-análisis offline (RMS + BPM/beats con ffmpeg/python) → JSON en `assets/audio/analysis/`. En runtime, `MusicDirector` lee el índice de pista y la posición de `AudioPlayer` (sin FFT en vivo; más fiable en Flutter web).

| Acto | Pista | Sensación |
|------|-------|-----------|
| 1 | `bgm_01` | Apertura: energía media, disparos enemigos en abanico/recto; densifica en picos |
| 2 | `bgm_02` | Pulso corto y agresivo: scouts rápidos, espirales en beats fuertes |
| 3 | `bgm_03` | Contraste: tramos lentos disparan al beat; estallidos densos |
| 4 | `bgm_04` | Clímax largo: más tanques, abanico/espiral, spawn alto en crestas |

Al terminar una pista: pausa breve de spawn, limpieza parcial de enemigos y “juice”; al empezar la siguiente, nuevo acto (spawn, patrones, velocidad).

Patrones de fuego enemigo: `straight`, `fan`, `spiral` (paramétrico). Controles WASD+espacio+N/M (escudo lento / onda destructiva), táctiles y SFX aislados del BGM.

Re-generar análisis (opcional): `python3 tool/analyze_bgm.py`

## Estructura

```
lib/
  main.dart
  ui/          # pantallas y overlays (bienvenida, HUD, pausa, game over)
  game/        # Flame: NavesGame, componentes y spawn
  audio/       # GameAudio, MusicDirector, análisis BGM
```

## Requisitos

- Flutter estable (3.22+ recomendado)
- Chrome para prueba web rápida

## Licencia

Demo educativa. Sin secretos ni backends.

## Descargas móviles (Android / iOS)

En la pantalla de bienvenida, debajo de **¡JUGAR!**:

| Botón | Qué hace |
|-------|----------|
| **APK Android** | Descarga `naves-arcade.apk` (en web: same-origin `/downloads/` con `<a download>`; nativo: GitHub Releases). |
| **ZIP Android** | Descarga `naves-arcade-android.zip` (APK + README de instalación). |
| **ZIP iOS** | No hay IPA firmado. El ZIP solo trae instrucciones; el diálogo lo explica. |

Ayuda bajo los botones Android: *Si se pausa: abre el link en Chrome → Descargas → permitir instalar apps desconocidas*.

URLs en `lib/config/download_urls.dart`. En Railway, Express sirve:

- `/downloads/naves-arcade.apk`
- `/downloads/naves-arcade-android.zip`
- `/downloads/naves-arcade-ios.zip`

con `Content-Disposition: attachment`. El APK/ZIP se obtienen en el **Docker build** desde GitHub Releases (no se committean binarios ~66MB).

### Android APK

- Build: `flutter build apk --release` (Android SDK + JDK).
- Release asset: tag `v1.0.1-mobile`, `naves-arcade.apk`.
- Mirror Railway: curl en imagen Docker → `/downloads/`.

### iOS (limitaciones)

Sin Mac/firma Apple **no** hay IPA instalable. El ZIP iOS es solo texto de instrucciones.


## Desplegar en Railway (web)

Despliegue **solo web** con Docker. Las carpetas `android/`, `ios/` y escritorio se mantienen en el repo; no se usan en el build de Railway.

1. Entra a [Railway](https://railway.app) → **New Project** → **Deploy from GitHub repo**.
2. Autoriza GitHub si hace falta y selecciona **`GerardoRosas-27/naves-arcade`**.
3. Railway detecta el `Dockerfile` (o `railway.toml`), construye Flutter web y sirve con Express (estáticos + APK/ZIP en `/downloads/`).
4. Cuando termine el deploy, abre la URL pública del servicio (dominio `*.up.railway.app` o el que configures).

**Base href:** en Railway se usa `--base-href /` (raíz del dominio). Si publicas en GitHub Pages bajo `/naves-arcade/`, usa `--base-href /naves-arcade/` en ese flujo; no mezclar ambos builds.

Variables: Railway inyecta `PORT`; el contenedor ya escucha en `$PORT`. No hace falta configurar puerto a mano.
