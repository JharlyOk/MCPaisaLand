# 🎮 PaisaLand - Instalador de Mods v4.0

![Windows](https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Linux](https://img.shields.io/badge/Platform-Linux%2FmacOS-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![PowerShell](https://img.shields.io/badge/Built%20With-PowerShell%20%2B%20WPF-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Version](https://img.shields.io/badge/Version-4.0.0-green?style=for-the-badge)

> **Instalador oficial del servidor de Minecraft "PaisaLand".**  
> Descarga e instala automáticamente mods, shaders y texturas con una interfaz moderna y profesional.

---

## ✨ Características v4.0

| Característica | Descripción |
|----------------|-------------|
| 🎨 **UI Premium** | Interfaz WPF moderna con efectos de sombra, animaciones y tema oscuro |
| 🌐 **Estado del Servidor** | Indicador en tiempo real (Online/Offline) |
| 🔄 **Verificación de Versión** | Detecta automáticamente si hay actualizaciones disponibles |
| 💾 **Verificación de Espacio** | Comprueba que tengas suficiente espacio en disco antes de instalar |
| 📁 **Backup Inteligente** | Guarda todos tus mods actuales antes de instalar |
| 🗑️ **Desinstalador** | Elimina todos los mods de PaisaLand con un clic |
| 💭 **Recordar Preferencia** | Guarda tu última selección (Gama Alta/Baja) |
| ⚡ **Dos Versiones** | Gama Baja (FPS) y Gama Alta (Visual) |

---

## 🚀 Instalación Rápida

### 🪟 Windows (PowerShell)
Abre PowerShell y ejecuta:
```powershell
irm https://raw.githubusercontent.com/JharlyOk/MCPaisaLand/main/Installer.ps1 | iex
```

### 🐧 Linux / macOS (Terminal)
```bash
curl -sL https://raw.githubusercontent.com/JharlyOk/MCPaisaLand/main/install.sh | bash
```

---

## 📸 Vista Previa

La interfaz incluye:
- ✅ Ventana sin bordes con esquinas redondeadas
- ✅ Efectos de sombra (Drop Shadow)
- ✅ Botones con animaciones al hover
- ✅ Tarjetas de selección interactivas
- ✅ Barra de progreso moderna
- ✅ Terminal de logs en tiempo real

---

## 📥 Instalación Manual

1. Descarga el repositorio como ZIP
2. Extrae los archivos
3. Ejecuta `Jugar_PaisaLand.bat` (Windows) o `./install.sh` (Linux/Mac)

---

## 🛠️ Requisitos

- **Windows**: Windows 10/11 con PowerShell 5.1+
- **Linux/Mac**: Bash, curl, unzip
- **Minecraft**: Instalado y ejecutado al menos una vez
- **Espacio**: Mínimo 500MB libres

---

## 📂 Estructura del Proyecto

```
📁 MCPaisaLand/
├── 📄 Installer.ps1      → Instalador principal (Windows)
├── 📄 install.sh         → Instalador Linux/Mac
├── 📄 Jugar_PaisaLand.bat → Launcher rápido
├── 📄 version.txt        → Control de versiones
├── 📄 README.md          → Este archivo
├── 📄 CHANGELOG.md       → Historial de cambios
└── 📁 src/               → Módulos (para desarrollo)
    ├── config.ps1
    ├── functions.ps1
    ├── styles.xaml
    └── ui.xaml
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
