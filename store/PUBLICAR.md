# Publicar Contador de Truco en Google Play

Guía paso a paso. Lo que está **listo en el repo**: el build firmado en formato `.aab`,
los textos y gráficos de la ficha (`store/`) y la política de privacidad (`docs/`).
Lo que **solo puede hacer el dueño de la cuenta** está marcado con 👤.

> Google cambia seguido los requisitos y los nombres de los menús. Ante cualquier duda,
> mandá lo que diga la [ayuda de Play Console](https://support.google.com/googleplay/android-developer).

## Antes de empezar: decisiones ya tomadas

- **Nombre de paquete:** `com.contadortruco.contador_truco`. Es **permanente** una vez subida la app.
- **App gratuita y sin anuncios:** en Play Console se elige *Gratuita*. Una app publicada como
  gratuita **no se puede pasar después a paga**, lo que coincide con que sea libre para siempre.
- **Cuenta personal** (todavía no creada), por lo que aplica el paso 8.

## 1. 👤 Crear la cuenta de desarrollador

1. Entrá a <https://play.google.com/console/signup> con la cuenta de Google que quieras usar.
2. Elegí cuenta **personal**, pagá el registro (USD 25, una sola vez) y completá la verificación
   de identidad que te pidan.

## 2. 👤 Crear la clave de subida

Es la llave con la que firmás lo que subís a Play. Google guarda aparte la clave final de la app
(*Play App Signing*), así que si perdés la de subida se puede restablecer, pero conviene guardarla bien.

```sh
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Guardá `upload-keystore.jks` y las contraseñas en un lugar seguro (gestor de contraseñas + copia de respaldo).
- **Nunca** la subas al repositorio (el `.gitignore` ya la ignora).

## 3. 👤 Cargar la clave en GitHub

En el repositorio: *Settings → Secrets and variables → Actions → New repository secret*. Creá estos 4:

| Secreto | Valor |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | el archivo `.jks` en base64 (ver abajo) |
| `ANDROID_KEYSTORE_PASSWORD` | la contraseña del almacén de claves |
| `ANDROID_KEY_ALIAS` | `upload` (el alias que usaste) |
| `ANDROID_KEY_PASSWORD` | la contraseña de la clave |

Para obtener el base64:

```sh
base64 -w0 upload-keystore.jks              # Linux
base64 -i upload-keystore.jks | tr -d '\n'  # macOS
# Windows (PowerShell):
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

## 4. Generar el `.aab`

*Actions → Build APK y AAB → Run workflow* (dejá `test_signing` sin marcar). Al terminar, bajá el
artefacto **`contador-truco-aab`** (zip con `app-release.aab`).

En el log, el paso *Mostrar con qué clave quedó firmado el .aab* tiene que mostrar tu clave de
subida, **no** `CN=Android Debug`. Si dice Android Debug, faltan los secretos del paso 3 y Play
va a rechazar el archivo.

El número de versión (`versionCode`) sube solo en cada ejecución; Play exige uno mayor en cada subida.

## 5. 👤 Política de privacidad (GitHub Pages)

La página ya está en `docs/index.html`. Cuando esté en `main`: *Settings → Pages → Deploy from a
branch → `main` / `/docs`*. La URL queda:

```
https://juanmahumeniuk.github.io/contador_truco/
```

## 6. 👤 Crear la app en Play Console

*Crear app* → nombre **Contador de Truco**, idioma español, tipo *App*, **Gratuita**, y aceptá las
declaraciones. La categoría que mejor encaja es *Herramientas* (es un anotador, no tiene partida
en sí), pero podés elegir otra.

## 7. 👤 Completar la ficha y las declaraciones

- **Ficha de Play Store:** textos y gráficos listos en [`ficha-es.md`](ficha-es.md) y `assets/`.
  Además hay que cargar un correo de contacto.
- **Política de privacidad:** la URL del paso 5.
- **Anuncios:** *No contiene anuncios*.
- **Seguridad de los datos:** la app no recopila ni comparte ningún dato. El APK no declara el
  permiso de internet (el workflow lista los permisos reales en cada compilación).
- **Clasificación de contenido:** cuestionario IARC. La app no tiene violencia, apuestas con dinero
  real ni contenido de usuarios.
- **Público objetivo:** conviene elegir uno que no incluya menores de 13 años, para no entrar en
  los requisitos adicionales de la política Familias (revisalo en la ayuda).
- **Plataforma de firma:** al subir el primer `.aab`, aceptá **Play App Signing**.

## 8. 👤 Prueba cerrada (cuentas personales nuevas)

Según lo que publican varias fuentes, las cuentas **personales creadas después del 13/11/2023**
tienen que hacer una **prueba cerrada con al menos 12 testers durante 14 días seguidos** antes de
poder pedir el acceso a producción (las cuentas de organización no). Estos números no salen de la
documentación de Google, así que **confirmalos en Play Console** antes de organizar nada.

1. *Pruebas → Prueba cerrada → Crear versión*: subí el `.aab` y armá una lista de correos de testers.
2. Pasale a los testers el link de opt-in y pedí que se mantengan inscriptos los 14 días.
3. Pasado el plazo, desde el panel de Play Console: **Solicitar acceso a producción**.

## 9. 👤 Producción

*Producción → Crear versión*: subí el `.aab` (el mismo o uno más nuevo), agregá las notas de versión y
enviá a revisión. La primera revisión puede tardar varios días.

## Cosas para tener en cuenta

- **El APK de GitHub y el de Play no se pisan:** están firmados con claves distintas. Si ya tenés
  instalado el APK de GitHub, desinstalalo antes de instalar la versión de Play (se pierde el marcador guardado).
- Google exige que las apps nuevas apunten a Android 16 (API 36) desde el 31/8/2026. El proyecto
  ya apunta a esa versión (`flutter.targetSdkVersion`); si Flutter cambia ese valor, se actualiza solo
  al subir la versión de Flutter.
