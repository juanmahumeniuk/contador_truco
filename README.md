# Contador de Truco

App de Android (hecha con Flutter) para llevar el tanteador del truco con tus amigos.

> **Código abierto, sin anuncios y sin monetización de ningún tipo.**
> Es libre para todos, para siempre.
>
> Licencia: [GNU GPL v3](LICENSE). Podés usarla, estudiarla, modificarla y compartirla;
> las versiones derivadas también tienen que seguir siendo libres.

## Qué hace

- **Dos equipos** ("Nosotros" y "Ellos"); tocá el nombre para ponerle el que quieras.
- **Fósforos de verdad**: cada cuadrado son 5 puntos (4 lados + la diagonal), con las
  filas de **malas** (1 a 15) y **buenas** (16 a 30) como en la mesa.
- **Botones +1, +2, +3 y +4** para anotar truco, envido, vale cuatro, etc., y **−1** para
  corregir un error.
- **Partida a 30 o a 15 puntos** (menú ⋮).
- Cuando alguien llega al objetivo aparece el cartel de ganador; **"Nueva partida"** suma
  la victoria y limpia el marcador. Las **partidas ganadas** quedan contadas en cada equipo.
- El marcador **se guarda solo**: si se cierra la app o se apaga el celular, la partida
  sigue donde estaba.
- Funciona sin internet, no pide permisos y no recopila ningún dato.

## Conseguir el APK

La forma más fácil: entrá a la sección **Releases** del repositorio (columna derecha de la
página principal), abrí la última versión y bajá el archivo `.apk` directo al celular.

Otra opción, un APK de cualquier commit: se compila en GitHub con el workflow [`Build APK y AAB`](.github/workflows/build-apk.yml)
(corre solo en cada push, y también a mano desde la pestaña *Actions → Build APK y AAB → Run workflow*):

1. Entrá a la pestaña **Actions** del repositorio y abrí la última ejecución en verde.
2. Al final de la página, en **Artifacts**, bajá `contador-truco-apk` (es un zip con `app-release.apk`).
3. Pasalo al celular, abrilo y, si Android lo pide, permití *"Instalar apps desconocidas"*
   para el navegador o el gestor de archivos que estés usando.

Para publicar una versión nueva como Release, subí un tag (`git tag v0.2.0 && git push origin v0.2.0`) o corré el workflow a mano desde *Actions → Build APK y AAB → Run workflow* escribiendo el tag en `release_tag`.

> El APK sale firmado con una clave de depuración distinta en cada compilación. Para
> instalar una versión nueva, desinstalá primero la anterior (se pierde el marcador guardado).

## Publicar en Google Play

La guía completa (cuenta de desarrollador, clave de firma, `.aab`, ficha y pruebas) está en
[`store/PUBLICAR.md`](store/PUBLICAR.md). Los textos y gráficos de la ficha están en
[`store/`](store/) y la política de privacidad en [`docs/`](docs/index.html).

## Desarrollo

Requiere [Flutter](https://docs.flutter.dev/get-started/install) (probado con 3.47.7).

```sh
flutter pub get
flutter analyze
flutter test
flutter run                      # en un celular o emulador conectado
flutter build apk --release      # genera build/app/outputs/flutter-apk/app-release.apk
```

Estructura:

- `lib/models/truco_game.dart`: reglas y estado de la partida (puro Dart, sin UI).
- `lib/state/game_controller.dart`: estado observable + guardado en el teléfono.
- `lib/widgets/`: dibujo de los fósforos y tarjeta de cada equipo.
- `lib/screens/scoreboard_screen.dart`: pantalla principal y diálogos.
- `test/`: tests de la lógica y de la pantalla.

## Licencia

Copyright (C) 2026 juanmahumeniuk. Este programa es software libre: podés redistribuirlo y/o
modificarlo bajo los términos de la Licencia Pública General de GNU, versión 3, tal como la
publica la Free Software Foundation. Se distribuye con la esperanza de que sea útil, pero
**sin ninguna garantía**. Ver el archivo [`LICENSE`](LICENSE).
