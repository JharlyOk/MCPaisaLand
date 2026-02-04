# ==============================================================================================
# PaisaLand Installer - Configuration Module
# v4.0.0
# ==============================================================================================

$script:Config = @{
    # --- Versión ---
    Version = "4.0.0"
    VersionUrl = "https://raw.githubusercontent.com/JharlyOk/MCPaisaLand/main/version.txt"
    
    # --- URLs de Descarga (Dropbox) ---
    DownloadUrlLow = "https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=1"
    DownloadUrlHigh = "https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=1"
    
    # --- Servidor ---
    ServerIP = "play.paisaland.com"
    ServerPort = 25565
    
    # --- Rutas ---
    MinecraftPath = "$env:APPDATA\.minecraft"
    TempDir = "$env:TEMP\PaisaLandInstaller"
    PrefsFile = "$env:APPDATA\PaisaLand\preferences.json"
    
    # --- Carpetas a Respaldar/Instalar ---
    ManagedFolders = @("mods", "config", "shaderpacks", "resourcepacks", "emotes", "options.txt", "servers.dat")
    
    # --- Requisitos ---
    MinDiskSpaceMB = 500
}

# Exportar configuración
$script:Config
