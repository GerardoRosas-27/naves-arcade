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
| Pausar | Botón ⏸ en el HUD |

## Estructura

```
lib/
  main.dart
  ui/          # pantallas y overlays (bienvenida, HUD, pausa, game over)
  game/        # Flame: NavesGame, componentes y spawn
```

## Requisitos

- Flutter estable (3.22+ recomendado)
- Chrome para prueba web rápida

## Licencia

Demo educativa. Sin secretos ni backends.

## Desplegar en Railway (web)

Despliegue **solo web** con Docker. Las carpetas `android/`, `ios/` y escritorio se mantienen en el repo; no se usan en el build de Railway.

1. Entra a [Railway](https://railway.app) → **New Project** → **Deploy from GitHub repo**.
2. Autoriza GitHub si hace falta y selecciona **`GerardoRosas-27/naves-arcade`**.
3. Railway detecta el `Dockerfile` (o `railway.toml`) y construye Flutter web + sirve estáticos.
4. Cuando termine el deploy, abre la URL pública del servicio (dominio `*.up.railway.app` o el que configures).

**Base href:** en Railway se usa `--base-href /` (raíz del dominio). Si publicas en GitHub Pages bajo `/naves-arcade/`, usa `--base-href /naves-arcade/` en ese flujo; no mezclar ambos builds.

Variables: Railway inyecta `PORT`; el contenedor ya escucha en `$PORT`. No hace falta configurar puerto a mano.
