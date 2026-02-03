# 🎮 PaisaLand - Instalador de Mods

![Windows](https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/Built%20With-PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

> **Instalador automático y optimizado para el servidor de Minecraft "PaisaLand".**  
> Diseñado para simplificar la vida de los jugadores, gestionando la descarga, instalación y configuración de mods, shaders y texturas con un solo clic.

---

## ✨ Características

*   **⚡ Instalación en un Clic**: Olvídate de copiar carpetas manualmente. El script hace todo por ti.
*   **🖥️ Detección Automática**: Encuentra tu carpeta `.minecraft` sin que tengas que buscarla.
*   **⚙️ Selección de Rendimiento**:
    *   **Modo Gama Baja**: Optimizado para máximo rendimiento y FPS.
    *   **Modo Gama Alta**: Incluye Shaders y mejoras visuales para equipos potentes.
*   **🛡️ Sistema de Backup**: Crea automáticamente una copia de seguridad de tus mods y configuraciones anteriores antes de instalar nada.
*   **🎨 Interfaz Moderna**: Una GUI oscura y elegante, fácil de usar.
*   **🚀 Launcher Amigable**: Incluye un archivo `.bat` para iniciar sin complicaciones técnicas.

## 📥 Instalación y Uso

1.  **Descargar**: Baja la última versión del repositorio (o el `.zip` proporcionado por el administrador).
2.  **Ejecutar**: Haz doble clic en el archivo `Jugar_PaisaLand.bat`.
3.  **Seleccionar**: Elige tu versión ("Gama Baja" o "Gama Alta") en la ventana que aparece.
4.  **Instalar**: Presiona el botón "INSTALAR MODPACK" y espera a que termine la barra de progreso.
5.  **¡Jugar!**: Abre tu launcher de Minecraft y disfruta.

## 🛠️ Requisitos Técnicos

*   **Sistema Operativo**: Windows 10 o Windows 11.
*   **Minecraft**: Tener el juego instalado y ejecutado al menos una vez (versión Vanilla).
*   **Conexión a Internet**: Necesaria para descargar los paquetes de mods.

## 📝 Notas para el Administrador

Para configurar los enlaces de descarga de los modpacks:
1.  Abre el archivo `Installer.ps1` con un editor de texto o IDE.
2.  Modifica las variables `$DownloadUrlLow` y `$DownloadUrlHigh` con tus enlaces directos (Dropbox, Drive, etc).

```powershell
$DownloadUrlLow = "TU_LINK_DIRECTO_GAMA_BAJA"
$DownloadUrlHigh = "TU_LINK_DIRECTO_GAMA_ALTA"
```

---

Hecho con ❤️ por **JharlyOk** para la comunidad de **PaisaLand**.
