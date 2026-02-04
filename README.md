# 🎮 PaisaLand - Instalador de Mods v9.0

![Windows](https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/Built%20With-PowerShell%20%2B%20HTML-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Version](https://img.shields.io/badge/Version-9.0.0-green?style=for-the-badge)

> **Instalador oficial del servidor de Minecraft "PaisaLand".**  
> Descarga e instala automáticamente mods, shaders y texturas con una interfaz moderna y profesional.

---

## ✨ Características v9.0

| Característica | Descripción |
|----------------|-------------|
| 🎨 **UI Moderna** | Interfaz HTML con glassmorphism, animaciones y tema oscuro/claro |
| 🌐 **Estado del Servidor** | Indicador en tiempo real (Online/Offline) |
| ✅ **Verificación del Sistema** | Detecta Java, Minecraft, Forge y RAM automáticamente |
| 📊 **Progreso en Tiempo Real** | Barra de progreso que se actualiza durante la descarga |
| 📁 **Backup Inteligente** | Guarda todos tus mods actuales antes de instalar |
| 🗑️ **Limpieza Completa** | Elimina mods, configs, shaders y resourcepacks |
| 🎯 **Guía de Instalación** | Banner de bienvenida con instrucciones paso a paso |
| ⚡ **Dos Versiones** | Gama Baja (FPS) y Gama Alta (Shaders + HD) |
| 🌙 **Tema Oscuro/Claro** | Toggle de tema integrado |

---

## 🚀 Instalación Rápida

Abre PowerShell y ejecuta:
```powershell
irm https://raw.githubusercontent.com/JharlyOk/MCPaisaLand/main/Installer.ps1 | iex
```

O ejecuta `Jugar_PaisaLand.bat` si ya tienes los archivos descargados.

---

## 🛠️ Requisitos

- **Windows**: Windows 10/11 con PowerShell 5.1+
- **Java**: Java 17 o superior
- **Minecraft**: Instalado y ejecutado al menos una vez
- **Forge**: Forge 1.20.1 (el instalador te guía si no lo tienes)
- **Espacio**: Mínimo 500MB libres

---

## 📂 Estructura del Proyecto

```
📁 MCPaisaLand/
├── 📄 Installer.ps1       → Instalador principal
├── 📄 Jugar_PaisaLand.bat → Launcher rápido
├── 📄 version.txt         → Control de versiones
├── 📄 README.md           → Este archivo
├── 📄 CHANGELOG.md        → Historial de cambios
└── 📄 LICENSE             → MIT License
```

---

## 🔧 Configuración (Administradores)

Edita las URLs en `Installer.ps1`:
```powershell
$script:Config = @{
    DownloadUrlLow = "TU_URL_GAMA_BAJA"
    DownloadUrlHigh = "TU_URL_GAMA_ALTA"
    ServerIP = "tu.servidor.com"
    ServerPort = 25565
}
```

---

Hecho con ❤️ por **JharlyOk** para la comunidad de **PaisaLand**.
