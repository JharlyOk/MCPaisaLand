# ==============================================================================================
# PaisaLand Installer v8.0.0 - COMPLETE EDITION
# Automatiza: Deteccion Java/MC/Forge, instalacion de mods, shaders, resourcepacks
# ==============================================================================================

$script:Config = @{
    Version = "8.0.0"
    Port = 8199
    MinecraftVersion = "1.20.1"
    ForgeVersion = "47.2.0"
    DownloadUrlLow = "https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=1"
    DownloadUrlHigh = "https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=1"
    ForgeInstallerUrl = "https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.2.0/forge-1.20.1-47.2.0-installer.jar"
    JavaDownloadUrl = "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe"
    ServerIP = "play.paisaland.com"
    ServerPort = 25565
    MinecraftPath = "$env:APPDATA\.minecraft"
    TempDir = "$env:TEMP\PaisaLandInstaller"
    ManagedFolders = @("mods", "config", "shaderpacks", "resourcepacks", "emotes", "options.txt", "servers.dat")
}

$script:Status = @{ 
    Message = "Iniciando..."; 
    Progress = 0; 
    Log = @(); 
    Complete = $false;
    Phase = "init"
}
$script:SystemCheck = @{
    Java = @{ OK = $false; Version = ""; Path = "" }
    Minecraft = @{ OK = $false; Path = "" }
    Forge = @{ OK = $false; Version = "" }
    RAM = @{ OK = $false; Total = 0; Available = 0 }
    Disk = @{ OK = $false; Free = 0 }
}
$script:Installing = $false

# ==================== DETECTION FUNCTIONS ====================

function Test-JavaInstalled {
    try {
        $javaPath = Get-Command java -ErrorAction SilentlyContinue
        if ($javaPath) {
            $versionOutput = & java -version 2>&1 | Out-String
            if ($versionOutput -match '(\d+\.\d+\.\d+|\d+)') {
                $script:SystemCheck.Java.OK = $true
                $script:SystemCheck.Java.Version = $matches[1]
                $script:SystemCheck.Java.Path = $javaPath.Source
                return $true
            }
        }
    } catch {}
    $script:SystemCheck.Java.OK = $false
    return $false
}

function Test-MinecraftInstalled {
    $mcPath = $script:Config.MinecraftPath
    if (Test-Path $mcPath) {
        $script:SystemCheck.Minecraft.OK = $true
        $script:SystemCheck.Minecraft.Path = $mcPath
        return $true
    }
    $script:SystemCheck.Minecraft.OK = $false
    return $false
}

function Test-ForgeInstalled {
    $versionsPath = "$($script:Config.MinecraftPath)\versions"
    if (Test-Path $versionsPath) {
        $forgeVersions = Get-ChildItem -Path $versionsPath -Directory | Where-Object { $_.Name -like "*forge*" -or $_.Name -like "*Forge*" }
        if ($forgeVersions.Count -gt 0) {
            $script:SystemCheck.Forge.OK = $true
            $script:SystemCheck.Forge.Version = $forgeVersions[0].Name
            return $true
        }
    }
    $script:SystemCheck.Forge.OK = $false
    return $false
}

function Test-SystemRAM {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $script:SystemCheck.RAM.Total = $totalRAM
        $script:SystemCheck.RAM.Available = $freeRAM
        $script:SystemCheck.RAM.OK = $totalRAM -ge 6
        return $script:SystemCheck.RAM.OK
    } catch {
        $script:SystemCheck.RAM.OK = $true
        return $true
    }
}

function Test-DiskSpace {
    try {
        $drive = (Get-Item $env:APPDATA).PSDrive.Name
        $freeGB = [math]::Round((Get-PSDrive $drive).Free / 1GB, 1)
        $script:SystemCheck.Disk.Free = $freeGB
        $script:SystemCheck.Disk.OK = $freeGB -ge 2
        return $script:SystemCheck.Disk.OK
    } catch {
        $script:SystemCheck.Disk.OK = $true
        return $true
    }
}

function Get-ServerStatus {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ar = $tcp.BeginConnect($script:Config.ServerIP, $script:Config.ServerPort, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne(2000, $false) -and $tcp.Connected) { 
            $tcp.Close()
            return @{ Online = $true; Message = "Online" } 
        }
        return @{ Online = $false; Message = "Offline" }
    } catch { return @{ Online = $false; Message = "Error" } }
}

function Invoke-SystemCheck {
    Add-Log "Verificando sistema..."
    Test-JavaInstalled | Out-Null
    Test-MinecraftInstalled | Out-Null
    Test-ForgeInstalled | Out-Null
    Test-SystemRAM | Out-Null
    Test-DiskSpace | Out-Null
    
    if ($script:SystemCheck.Java.OK) { Add-Log "Java detectado: v$($script:SystemCheck.Java.Version)" }
    else { Add-Log "AVISO: Java no detectado" }
    
    if ($script:SystemCheck.Minecraft.OK) { Add-Log "Minecraft detectado" }
    else { Add-Log "ERROR: Minecraft no instalado" }
    
    if ($script:SystemCheck.Forge.OK) { Add-Log "Forge detectado: $($script:SystemCheck.Forge.Version)" }
    else { Add-Log "AVISO: Forge no detectado" }
    
    Add-Log "RAM: $($script:SystemCheck.RAM.Total)GB | Disco libre: $($script:SystemCheck.Disk.Free)GB"
    Add-Log "Sistema verificado"
}

# ==================== UTILITY FUNCTIONS ====================

function Add-Log { 
    param($msg)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $script:Status.Log += "[$timestamp] $msg"
    if ($script:Status.Log.Count -gt 100) {
        $script:Status.Log = $script:Status.Log[-50..-1]
    }
}

function Install-Modpack {
    param([bool]$HighSpec = $false)
    
    $script:Installing = $true
    $script:Status.Complete = $false
    $script:Status.Phase = "installing"
    
    $modeName = if($HighSpec) { "GAMA ALTA" } else { "GAMA BAJA" }
    Add-Log "=== Iniciando instalacion: $modeName ==="
    $script:Status.Message = "Preparando instalacion..."; $script:Status.Progress = 5
    
    # Verificaciones
    if (-not $script:SystemCheck.Minecraft.OK) {
        Add-Log "ERROR: Minecraft no esta instalado"
        $script:Status.Message = "Error: Instala Minecraft primero"
        $script:Installing = $false
        return $false
    }
    
    if (-not $script:SystemCheck.Disk.OK) {
        Add-Log "ERROR: Espacio en disco insuficiente"
        $script:Status.Message = "Error: Necesitas al menos 2GB libres"
        $script:Installing = $false
        return $false
    }
    
    $script:Status.Progress = 10
    
    # Preparar directorio temporal
    if (-not (Test-Path $script:Config.TempDir)) { 
        New-Item -ItemType Directory -Path $script:Config.TempDir -Force | Out-Null 
    }
    
    # Descarga
    $url = if ($HighSpec) { $script:Config.DownloadUrlHigh } else { $script:Config.DownloadUrlLow }
    $zip = "$($script:Config.TempDir)\modpack.zip"
    
    $script:Status.Message = "Descargando modpack..."; $script:Status.Progress = 15
    Add-Log "Conectando al servidor de descarga..."
    
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $zip)
        Add-Log "Descarga completada"
    } catch {
        Add-Log "ERROR: Fallo en descarga - $($_.Exception.Message)"
        $script:Status.Message = "Error de descarga"
        $script:Installing = $false
        return $false
    }
    
    $script:Status.Progress = 50
    $script:Status.Message = "Preparando archivos..."
    
    # Backup de mods existentes
    $modsPath = "$($script:Config.MinecraftPath)\mods"
    if (Test-Path $modsPath) {
        $existingMods = Get-ChildItem $modsPath -ErrorAction SilentlyContinue
        if ($existingMods.Count -gt 0) {
            Add-Log "Limpiando mods anteriores ($($existingMods.Count) archivos)..."
            Remove-Item "$modsPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    $script:Status.Progress = 60
    $script:Status.Message = "Extrayendo archivos..."
    Add-Log "Extrayendo modpack..."
    
    # Extraccion
    $extract = "$($script:Config.TempDir)\extracted"
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    
    $items = Get-ChildItem -Path $extract
    $src = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $extract }
    
    $script:Status.Progress = 75
    $script:Status.Message = "Instalando mods..."
    
    # Copiar archivos
    $filesToCopy = Get-ChildItem -Path $src -Recurse -File
    Add-Log "Copiando $($filesToCopy.Count) archivos..."
    Copy-Item -Path "$src\*" -Destination $script:Config.MinecraftPath -Recurse -Force
    
    $script:Status.Progress = 90
    $script:Status.Message = "Limpiando..."
    
    # Limpiar temporales
    if (Test-Path $script:Config.TempDir) { 
        Remove-Item $script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue 
    }
    
    $script:Status.Progress = 100
    $script:Status.Message = "Instalacion completada!"
    $script:Status.Complete = $true
    $script:Status.Phase = "complete"
    Add-Log "=== INSTALACION EXITOSA ==="
    Add-Log "Puedes cerrar esta ventana y abrir Minecraft"
    
    $script:Installing = $false
    return $true
}

function New-Backup {
    Add-Log "Creando backup..."
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $dir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$timestamp"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    
    $copied = 0
    foreach ($item in $script:Config.ManagedFolders) {
        $p = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $p) { 
            Copy-Item -Path $p -Destination $dir -Recurse -ErrorAction SilentlyContinue
            $copied++
        }
    }
    
    Add-Log "Backup creado: $dir ($copied items)"
    return $dir
}

function Remove-Modpack {
    Add-Log "Eliminando mods de PaisaLand..."
    $removed = 0
    foreach ($item in $script:Config.ManagedFolders) {
        $p = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $p) { 
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
            $removed++
        }
    }
    Add-Log "Eliminados $removed elementos"
    $script:Status.Message = "Mods eliminados"
}

function Open-MinecraftLauncher {
    Add-Log "Abriendo Minecraft Launcher..."
    $launcherPaths = @(
        "$env:ProgramFiles\Minecraft Launcher\MinecraftLauncher.exe",
        "$env:ProgramFiles(x86)\Minecraft Launcher\MinecraftLauncher.exe",
        "$env:LOCALAPPDATA\Packages\Microsoft.4297127D64EC6_8wekyb3d8bbwe\LocalCache\Local\runtime\java-runtime-gamma\windows-x64\java-runtime-gamma\bin\javaw.exe"
    )
    
    foreach ($path in $launcherPaths) {
        if (Test-Path $path) {
            Start-Process $path
            Add-Log "Launcher iniciado"
            return $true
        }
    }
    
    # Intentar via protocolo
    try {
        Start-Process "minecraft://"
        Add-Log "Launcher iniciado via protocolo"
        return $true
    } catch {
        Add-Log "No se pudo abrir el launcher automaticamente"
        return $false
    }
}

# ==================== HTML ====================

$HTML = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PaisaLand Installer</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/feather-icons"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --bg: #0f0f23;
            --bg2: #1a1a2e;
            --card: rgba(255,255,255,0.03);
            --card-border: rgba(255,255,255,0.08);
            --text: #ffffff;
            --text2: rgba(255,255,255,0.6);
            --text3: rgba(255,255,255,0.4);
            --accent: #10b981;
            --accent2: #059669;
            --danger: #ef4444;
            --warning: #f59e0b;
            --info: #3b82f6;
        }
        body.light {
            --bg: #f0f4f8;
            --bg2: #e2e8f0;
            --card: rgba(255,255,255,0.8);
            --card-border: rgba(0,0,0,0.1);
            --text: #1e293b;
            --text2: rgba(30,41,59,0.7);
            --text3: rgba(30,41,59,0.5);
        }
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, var(--bg) 0%, var(--bg2) 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        body::before {
            content: '';
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: radial-gradient(circle at 20% 80%, rgba(16,185,129,0.1) 0%, transparent 50%),
                        radial-gradient(circle at 80% 20%, rgba(59,130,246,0.1) 0%, transparent 50%);
            pointer-events: none;
            z-index: -1;
        }
        .app {
            width: 100%;
            max-width: 520px;
            background: var(--card);
            backdrop-filter: blur(20px);
            border: 1px solid var(--card-border);
            border-radius: 24px;
            overflow: hidden;
            box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5);
            animation: slideUp 0.5s ease;
        }
        @keyframes slideUp {
            from { opacity: 0; transform: translateY(30px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        /* Header */
        .header {
            padding: 20px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--card-border);
        }
        .brand { display: flex; align-items: center; gap: 12px; }
        .brand-icon {
            width: 48px; height: 48px;
            background: linear-gradient(135deg, var(--accent) 0%, var(--accent2) 100%);
            border-radius: 14px;
            display: flex; align-items: center; justify-content: center;
            font-size: 24px; font-weight: 800; color: white;
            box-shadow: 0 4px 15px rgba(16,185,129,0.4);
        }
        .brand-text { font-size: 22px; font-weight: 700; color: var(--text); }
        .brand-text span { color: var(--accent); }
        .header-actions { display: flex; gap: 8px; }
        .icon-btn {
            width: 40px; height: 40px;
            border: 1px solid var(--card-border);
            background: var(--card);
            color: var(--text2);
            border-radius: 12px;
            cursor: pointer;
            transition: all 0.2s;
            display: flex; align-items: center; justify-content: center;
        }
        .icon-btn:hover { background: var(--card-border); color: var(--text); }
        
        /* Content */
        .content { padding: 24px; }
        
        /* System Status */
        .system-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 12px;
            margin-bottom: 20px;
        }
        .status-card {
            padding: 14px;
            background: var(--card);
            border: 1px solid var(--card-border);
            border-radius: 12px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .status-icon {
            width: 36px; height: 36px;
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 18px;
        }
        .status-icon.ok { background: rgba(16,185,129,0.15); color: var(--accent); }
        .status-icon.warn { background: rgba(245,158,11,0.15); color: var(--warning); }
        .status-icon.error { background: rgba(239,68,68,0.15); color: var(--danger); }
        .status-icon.loading { background: rgba(59,130,246,0.15); color: var(--info); }
        .status-info h4 { font-size: 13px; font-weight: 600; color: var(--text); }
        .status-info p { font-size: 11px; color: var(--text3); margin-top: 2px; }
        
        /* Server Status Bar */
        .server-bar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 12px 16px;
            background: var(--card);
            border: 1px solid var(--card-border);
            border-radius: 12px;
            margin-bottom: 20px;
        }
        .server-dot {
            width: 10px; height: 10px;
            border-radius: 50%;
            background: var(--danger);
            animation: pulse 2s infinite;
        }
        .server-dot.online { background: var(--accent); }
        @keyframes pulse { 50% { opacity: 0.5; } }
        .server-text { font-size: 13px; color: var(--text2); flex: 1; }
        .server-text strong { color: var(--text); }
        
        /* Mode Selector */
        .mode-section { margin-bottom: 20px; }
        .section-label {
            font-size: 11px; font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text3);
            margin-bottom: 12px;
        }
        .mode-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .mode-card {
            padding: 18px;
            background: var(--card);
            border: 2px solid var(--card-border);
            border-radius: 14px;
            cursor: pointer;
            transition: all 0.3s;
            text-align: center;
        }
        .mode-card:hover { border-color: var(--text3); }
        .mode-card.active { border-color: var(--accent); background: rgba(16,185,129,0.08); }
        .mode-card i { margin-bottom: 8px; color: var(--text2); }
        .mode-card.active i { color: var(--accent); }
        .mode-card h4 { font-size: 14px; font-weight: 600; color: var(--text); margin-bottom: 4px; }
        .mode-card.active h4 { color: var(--accent); }
        .mode-card p { font-size: 11px; color: var(--text3); }
        
        /* Progress */
        .progress-section {
            padding: 18px;
            background: var(--card);
            border: 1px solid var(--card-border);
            border-radius: 14px;
            margin-bottom: 20px;
        }
        .progress-header { display: flex; justify-content: space-between; margin-bottom: 10px; }
        .progress-status { font-size: 14px; font-weight: 600; color: var(--text); }
        .progress-percent { font-size: 14px; font-weight: 700; color: var(--accent); }
        .progress-bar { height: 8px; background: rgba(255,255,255,0.1); border-radius: 4px; overflow: hidden; }
        .progress-fill {
            height: 100%; width: 0%;
            background: linear-gradient(90deg, var(--accent), #34d399);
            border-radius: 4px;
            transition: width 0.4s ease;
        }
        .progress-fill.active { animation: shimmer 1.5s infinite; }
        @keyframes shimmer {
            0% { background-position: -200% 0; }
            100% { background-position: 200% 0; }
        }
        
        /* Buttons */
        .btn-primary {
            width: 100%;
            padding: 18px;
            background: linear-gradient(135deg, var(--accent), var(--accent2));
            border: none;
            border-radius: 14px;
            color: white;
            font-size: 15px; font-weight: 700;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            box-shadow: 0 4px 20px rgba(16,185,129,0.3);
            margin-bottom: 16px;
        }
        .btn-primary:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(16,185,129,0.4); }
        .btn-primary:disabled { background: var(--card-border); color: var(--text3); cursor: not-allowed; box-shadow: none; }
        
        .btn-success {
            background: linear-gradient(135deg, var(--info), #2563eb);
            box-shadow: 0 4px 20px rgba(59,130,246,0.3);
        }
        .btn-success:hover:not(:disabled) { box-shadow: 0 8px 30px rgba(59,130,246,0.4); }
        
        /* Log */
        .log-section {
            background: #0d0d14;
            border: 1px solid var(--card-border);
            border-radius: 12px;
            padding: 12px;
            height: 120px;
            overflow-y: auto;
            margin-bottom: 16px;
            font-family: 'Consolas', monospace;
        }
        body.light .log-section { background: #f1f5f9; }
        .log-line { font-size: 11px; color: var(--accent); line-height: 1.8; opacity: 0.9; }
        body.light .log-line { color: #059669; }
        
        /* Secondary Actions */
        .actions-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
        .btn-secondary {
            padding: 12px;
            background: var(--card);
            border: 1px solid var(--card-border);
            border-radius: 10px;
            color: var(--text2);
            font-size: 12px; font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 6px;
        }
        .btn-secondary:hover { background: var(--card-border); color: var(--text); }
        .btn-secondary.danger { border-color: rgba(239,68,68,0.3); color: var(--danger); }
        .btn-secondary.danger:hover { background: rgba(239,68,68,0.1); }
        
        /* Footer */
        .footer {
            padding: 16px 24px;
            border-top: 1px solid var(--card-border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .footer-text { font-size: 12px; color: var(--text3); }
        .footer-text a { color: var(--accent); text-decoration: none; }
        .version {
            font-size: 11px;
            color: var(--text3);
            padding: 4px 12px;
            background: var(--card);
            border: 1px solid var(--card-border);
            border-radius: 20px;
        }
        
        /* Toast */
        .toast {
            position: fixed;
            bottom: 30px;
            left: 50%;
            transform: translateX(-50%) translateY(100px);
            padding: 14px 24px;
            background: var(--text);
            color: var(--bg);
            border-radius: 12px;
            font-size: 14px;
            font-weight: 500;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            opacity: 0;
            transition: all 0.3s ease;
            z-index: 1000;
        }
        .toast.show { transform: translateX(-50%) translateY(0); opacity: 1; }
        .toast.success { background: var(--accent); color: white; }
        .toast.error { background: var(--danger); color: white; }
    </style>
</head>
<body>
    <div class="app">
        <div class="header">
            <div class="brand">
                <div class="brand-icon">P</div>
                <div class="brand-text">PAISA<span>LAND</span></div>
            </div>
            <div class="header-actions">
                <button class="icon-btn" id="themeBtn" title="Cambiar tema">
                    <i data-feather="moon"></i>
                </button>
            </div>
        </div>
        
        <div class="content">
            <!-- System Status -->
            <div class="system-grid" id="systemGrid">
                <div class="status-card">
                    <div class="status-icon loading" id="javaIcon"><i data-feather="coffee"></i></div>
                    <div class="status-info">
                        <h4>Java</h4>
                        <p id="javaStatus">Verificando...</p>
                    </div>
                </div>
                <div class="status-card">
                    <div class="status-icon loading" id="mcIcon"><i data-feather="box"></i></div>
                    <div class="status-info">
                        <h4>Minecraft</h4>
                        <p id="mcStatus">Verificando...</p>
                    </div>
                </div>
                <div class="status-card">
                    <div class="status-icon loading" id="forgeIcon"><i data-feather="tool"></i></div>
                    <div class="status-info">
                        <h4>Forge</h4>
                        <p id="forgeStatus">Verificando...</p>
                    </div>
                </div>
                <div class="status-card">
                    <div class="status-icon loading" id="ramIcon"><i data-feather="cpu"></i></div>
                    <div class="status-info">
                        <h4>Sistema</h4>
                        <p id="ramStatus">Verificando...</p>
                    </div>
                </div>
            </div>
            
            <!-- Server Status -->
            <div class="server-bar">
                <div class="server-dot" id="serverDot"></div>
                <span class="server-text">Servidor: <strong id="serverText">Verificando...</strong></span>
            </div>
            
            <!-- Mode Selection -->
            <div class="mode-section">
                <div class="section-label">Selecciona tu version</div>
                <div class="mode-grid">
                    <div class="mode-card active" id="modeLow" onclick="selectMode(false)">
                        <i data-feather="zap"></i>
                        <h4>Gama Baja</h4>
                        <p>Optimizado para FPS</p>
                    </div>
                    <div class="mode-card" id="modeHigh" onclick="selectMode(true)">
                        <i data-feather="star"></i>
                        <h4>Gama Alta</h4>
                        <p>Shaders + Texturas HD</p>
                    </div>
                </div>
            </div>
            
            <!-- Progress -->
            <div class="progress-section">
                <div class="progress-header">
                    <span class="progress-status" id="statusText">Listo para instalar</span>
                    <span class="progress-percent" id="progressPercent">0%</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" id="progressFill"></div>
                </div>
            </div>
            
            <!-- Main Button -->
            <button class="btn-primary" id="mainBtn" onclick="install()">
                <i data-feather="download"></i>
                <span>Instalar Modpack</span>
            </button>
            
            <!-- Log -->
            <div class="log-section" id="logBox"></div>
            
            <!-- Secondary Actions -->
            <div class="actions-grid">
                <button class="btn-secondary" onclick="backup()">
                    <i data-feather="save"></i>
                    <span>Backup</span>
                </button>
                <button class="btn-secondary" onclick="launch()">
                    <i data-feather="play"></i>
                    <span>Jugar</span>
                </button>
                <button class="btn-secondary danger" onclick="uninstall()">
                    <i data-feather="trash-2"></i>
                    <span>Eliminar</span>
                </button>
            </div>
        </div>
        
        <div class="footer">
            <span class="footer-text">Creado por <a href="#">JharlyOk</a></span>
            <span class="version">v8.0.0</span>
        </div>
    </div>
    
    <div class="toast" id="toast"></div>
    
    <script>
        var API = 'http://localhost:{{PORT}}';
        var isHighSpec = false;
        var isDark = true;
        
        // Init icons
        feather.replace();
        
        // Theme toggle
        document.getElementById('themeBtn').onclick = function() {
            isDark = !isDark;
            document.body.classList.toggle('light', !isDark);
            this.innerHTML = isDark ? '<i data-feather="moon"></i>' : '<i data-feather="sun"></i>';
            feather.replace();
        };
        
        // Mode selection
        function selectMode(high) {
            isHighSpec = high;
            document.getElementById('modeLow').classList.toggle('active', !high);
            document.getElementById('modeHigh').classList.toggle('active', high);
        }
        
        // Toast notification
        function showToast(msg, type) {
            var t = document.getElementById('toast');
            t.textContent = msg;
            t.className = 'toast ' + (type || '');
            t.classList.add('show');
            setTimeout(function() { t.classList.remove('show'); }, 3000);
        }
        
        // Update status
        function updateStatus() {
            fetch(API + '/status')
                .then(function(r) { return r.json(); })
                .then(function(d) {
                    // Progress
                    document.getElementById('statusText').textContent = d.message;
                    document.getElementById('progressPercent').textContent = d.progress + '%';
                    document.getElementById('progressFill').style.width = d.progress + '%';
                    
                    if (d.installing) {
                        document.getElementById('progressFill').classList.add('active');
                        document.getElementById('mainBtn').disabled = true;
                    } else {
                        document.getElementById('progressFill').classList.remove('active');
                        document.getElementById('mainBtn').disabled = false;
                    }
                    
                    // Complete state
                    if (d.complete) {
                        var btn = document.getElementById('mainBtn');
                        btn.className = 'btn-primary btn-success';
                        btn.innerHTML = '<i data-feather="check-circle"></i><span>Completado!</span>';
                        feather.replace();
                    }
                    
                    // Server
                    if (d.server) {
                        document.getElementById('serverDot').classList.toggle('online', d.server.online);
                        document.getElementById('serverText').textContent = d.server.msg;
                    }
                    
                    // System checks
                    if (d.system) {
                        updateSystemCard('java', d.system.java);
                        updateSystemCard('mc', d.system.minecraft);
                        updateSystemCard('forge', d.system.forge);
                        updateSystemCard('ram', d.system.ram);
                    }
                    
                    // Log
                    var logBox = document.getElementById('logBox');
                    if (d.log && d.log.length > 0) {
                        logBox.innerHTML = d.log.map(function(l) { 
                            return '<div class="log-line">' + l + '</div>'; 
                        }).join('');
                        logBox.scrollTop = logBox.scrollHeight;
                    }
                })
                .catch(function(e) {});
        }
        
        function updateSystemCard(type, data) {
            if (!data) return;
            var icon = document.getElementById(type + 'Icon');
            var status = document.getElementById(type + 'Status');
            if (!icon || !status) return;
            
            icon.classList.remove('ok', 'warn', 'error', 'loading');
            if (data.ok) {
                icon.classList.add('ok');
                status.textContent = data.info || 'OK';
            } else {
                icon.classList.add('error');
                status.textContent = data.info || 'No detectado';
            }
        }
        
        // Actions
        function install() {
            document.getElementById('mainBtn').disabled = true;
            fetch(API + '/install?high=' + isHighSpec, { method: 'POST' })
                .then(function() { showToast('Instalacion iniciada', 'success'); })
                .catch(function() { showToast('Error de conexion', 'error'); });
        }
        
        function backup() {
            fetch(API + '/backup', { method: 'POST' })
                .then(function() { showToast('Backup creado en el escritorio', 'success'); })
                .catch(function() {});
        }
        
        function launch() {
            fetch(API + '/launch', { method: 'POST' })
                .then(function() { showToast('Abriendo Minecraft...', 'success'); })
                .catch(function() {});
        }
        
        function uninstall() {
            if (confirm('Eliminar todos los mods de PaisaLand?')) {
                fetch(API + '/uninstall', { method: 'POST' })
                    .then(function() { showToast('Mods eliminados', 'success'); })
                    .catch(function() {});
            }
        }
        
        // Start polling
        setInterval(updateStatus, 1000);
        updateStatus();
    </script>
</body>
</html>
"@

# ==================== HTTP SERVER ====================

function Start-Installer {
    $port = $script:Config.Port
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    
    try { $listener.Start() } catch {
        Write-Host ""
        Write-Host "  [ERROR] Puerto $port en uso" -ForegroundColor Red
        Write-Host ""
        return
    }
    
    # Banner
    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host "       PaisaLand Installer v8.0.0        " -ForegroundColor White
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [OK] Servidor: http://localhost:$port" -ForegroundColor Green
    Write-Host "  [OK] Abriendo navegador..." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Presiona Ctrl+C para cerrar" -ForegroundColor Yellow
    Write-Host ""
    
    # Initial checks
    Invoke-SystemCheck
    $serverStatus = Get-ServerStatus
    
    # Open browser
    $htmlPath = "$env:TEMP\paisaland_v8.html"
    $HTML.Replace("{{PORT}}", $port) | Out-File -FilePath $htmlPath -Encoding UTF8
    Start-Process $htmlPath
    
    # Request loop
    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            # CORS
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "*")
            
            if ($request.HttpMethod -eq "OPTIONS") { 
                $response.StatusCode = 200
                $response.Close()
                continue 
            }
            
            $path = $request.Url.LocalPath
            $result = @{}
            
            switch ($path) {
                "/status" {
                    $result = @{
                        message = $script:Status.Message
                        progress = $script:Status.Progress
                        log = $script:Status.Log
                        installing = $script:Installing
                        complete = $script:Status.Complete
                        phase = $script:Status.Phase
                        server = @{ online = $serverStatus.Online; msg = $serverStatus.Message }
                        system = @{
                            java = @{ ok = $script:SystemCheck.Java.OK; info = if($script:SystemCheck.Java.OK) { "v$($script:SystemCheck.Java.Version)" } else { "No instalado" } }
                            minecraft = @{ ok = $script:SystemCheck.Minecraft.OK; info = if($script:SystemCheck.Minecraft.OK) { "Detectado" } else { "No encontrado" } }
                            forge = @{ ok = $script:SystemCheck.Forge.OK; info = if($script:SystemCheck.Forge.OK) { $script:SystemCheck.Forge.Version } else { "No instalado" } }
                            ram = @{ ok = $script:SystemCheck.RAM.OK; info = "$($script:SystemCheck.RAM.Total)GB RAM" }
                        }
                    }
                }
                "/install" {
                    if (-not $script:Installing) {
                        $high = $request.QueryString["high"] -eq "true"
                        Install-Modpack -HighSpec $high
                    }
                    $result = @{ ok = $true }
                }
                "/backup" {
                    $p = New-Backup
                    $result = @{ ok = $true; path = $p }
                }
                "/uninstall" {
                    Remove-Modpack
                    $result = @{ ok = $true }
                }
                "/launch" {
                    $ok = Open-MinecraftLauncher
                    $result = @{ ok = $ok }
                }
                "/check" {
                    Invoke-SystemCheck
                    $result = @{ ok = $true }
                }
                default { $result = @{ error = "404" } }
            }
            
            $json = $result | ConvertTo-Json -Compress -Depth 5
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            
        } catch { 
            if ($listener.IsListening) { } 
        }
    }
}

# ==================== START ====================
Start-Installer
