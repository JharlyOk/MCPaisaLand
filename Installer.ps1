# ==============================================================================================
# PaisaLand Installer v9.0.0 - WIZARD EDITION
# Instalador paso a paso con guia completa para nuevos usuarios
# ==============================================================================================

$script:Config = @{
    Version = "9.0.0"
    Port = 8199
    MinecraftVersion = "1.20.1"
    ForgeVersion = "47.2.0"
    DownloadUrlLow = "https://www.dropbox.com/scl/fi/69wsenz4v9xqb8xh77zcn/PC-Gama-Baja.zip?rlkey=ww42naweab8jss8rc73sga2bo&st=489vgqes&dl=1"
    DownloadUrlHigh = "https://www.dropbox.com/scl/fi/xzpe3la212x3ezplvrvlm/PC-Gama-Alta.zip?rlkey=76u4pl3jt25mquqqq81aa8srs&st=jvacnabh&dl=1"
    ForgeInstallerUrl = "https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.2.0/forge-1.20.1-47.2.0-installer.jar"
    ServerIP = "199.127.62.118"
    ServerPort = 25610
    MinecraftPath = "$env:APPDATA\.minecraft"
    TempDir = "$env:TEMP\PaisaLandInstaller"
    ManagedFolders = @("mods", "config", "shaderpacks", "resourcepacks", "emotes")
}

$script:Status = @{ 
    Message = "Listo"
    Progress = 0
    Log = @()
    Phase = "ready"
    SubProgress = ""
}
$script:SystemCheck = @{
    Java = @{ OK = $null; Version = ""; Message = "Verificando..." }
    Minecraft = @{ OK = $null; Message = "Verificando..." }
    Forge = @{ OK = $null; Version = ""; Message = "Verificando..." }
    RAM = @{ OK = $null; Total = 0; Message = "Verificando..." }
    Disk = @{ OK = $null; Free = 0; Message = "Verificando..." }
}
$script:ServerStatus = $null  # null = loading, true = online, false = offline
$script:ChecksReady = $false
$script:Installing = $false

# ==================== DETECTION ====================

function Test-JavaInstalled {
    try {
        $javaCmd = Get-Command java -ErrorAction SilentlyContinue
        if ($javaCmd) {
            $ver = & java -version 2>&1 | Out-String
            if ($ver -match '(\d+)') {
                $script:SystemCheck.Java.OK = $true
                $script:SystemCheck.Java.Version = $matches[1]
                $script:SystemCheck.Java.Message = "Java $($matches[1]) instalado"
                return $true
            }
        }
    } catch {}
    $script:SystemCheck.Java.OK = $false
    $script:SystemCheck.Java.Message = "Java no encontrado"
    return $false
}

function Test-MinecraftInstalled {
    if (Test-Path $script:Config.MinecraftPath) {
        $script:SystemCheck.Minecraft.OK = $true
        $script:SystemCheck.Minecraft.Message = "Minecraft detectado"
        return $true
    }
    $script:SystemCheck.Minecraft.OK = $false
    $script:SystemCheck.Minecraft.Message = "No encontrado"
    return $false
}

function Test-ForgeInstalled {
    $versionsPath = "$($script:Config.MinecraftPath)\versions"
    if (Test-Path $versionsPath) {
        $forge = Get-ChildItem $versionsPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*forge*" -or $_.Name -like "*Forge*" } | Select-Object -First 1
        if ($forge) {
            $script:SystemCheck.Forge.OK = $true
            $script:SystemCheck.Forge.Version = $forge.Name
            $script:SystemCheck.Forge.Message = $forge.Name
            return $true
        }
    }
    $script:SystemCheck.Forge.OK = $false
    $script:SystemCheck.Forge.Message = "No instalado"
    return $false
}

function Test-SystemRAM {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $script:SystemCheck.RAM.Total = $totalGB
        $script:SystemCheck.RAM.OK = $totalGB -ge 4
        $script:SystemCheck.RAM.Message = "$totalGB GB RAM"
    } catch {
        $script:SystemCheck.RAM.OK = $true
        $script:SystemCheck.RAM.Message = "OK"
    }
}

function Test-DiskSpace {
    try {
        $mcPath = $script:Config.MinecraftPath
        $drive = (Split-Path $mcPath -Qualifier)
        $disk = Get-PSDrive -Name $drive.TrimEnd(':') -ErrorAction SilentlyContinue
        if ($disk) {
            $freeGB = [math]::Round($disk.Free / 1GB, 1)
            $script:SystemCheck.Disk.Free = $freeGB
            $script:SystemCheck.Disk.OK = $freeGB -ge 1
            $script:SystemCheck.Disk.Message = "$freeGB GB libres"
        } else {
            $script:SystemCheck.Disk.OK = $true
            $script:SystemCheck.Disk.Message = "OK"
        }
    } catch {
        $script:SystemCheck.Disk.OK = $true
        $script:SystemCheck.Disk.Message = "OK"
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
    Add-Log "Escaneando sistema..."
    Test-JavaInstalled | Out-Null
    Test-MinecraftInstalled | Out-Null
    Test-ForgeInstalled | Out-Null
    Test-SystemRAM
    Test-DiskSpace
    Add-Log "Escaneo completado"
}

# ==================== UTILITIES ====================

function Add-Log { 
    param($msg)
    $ts = Get-Date -Format "HH:mm:ss"
    $logLine = "[$ts] $msg"
    $script:Status.Log += $logLine
    if ($script:Status.Log.Count -gt 50) { $script:Status.Log = $script:Status.Log[-30..-1] }
    
    # File logging for debugging
    try {
        $logFile = "$env:TEMP\PaisaLand_Installer.log"
        Add-Content -Path $logFile -Value $logLine -ErrorAction SilentlyContinue
    } catch {}
}

function Install-Modpack {
    param([bool]$HighSpec = $false)
    
    $script:Installing = $true
    $script:Status.Phase = "installing"
    $script:Status.Progress = 0
    $modeName = if($HighSpec){"Gama Alta"}else{"Gama Baja"}
    
    Add-Log "=== INSTALANDO: $modeName ==="
    
    # Check Minecraft
    $script:Status.Message = "Verificando Minecraft..."
    $script:Status.SubProgress = "Comprobando instalacion"
    $script:Status.Progress = 5
    Start-Sleep -Milliseconds 300
    
    if (-not (Test-Path $script:Config.MinecraftPath)) {
        Add-Log "ERROR: Minecraft no instalado"
        $script:Status.Message = "Error: Instala Minecraft primero"
        $script:Status.Phase = "error"
        $script:Installing = $false
        return $false
    }
    Add-Log "Minecraft OK"
    $script:Status.Progress = 10
    
    # Prepare temp
    $script:Status.Message = "Preparando..."
    $script:Status.SubProgress = "Creando directorio temporal"
    if (-not (Test-Path $script:Config.TempDir)) { 
        New-Item -ItemType Directory -Path $script:Config.TempDir -Force | Out-Null 
    }
    $script:Status.Progress = 15
    
    # Download
    $url = if ($HighSpec) { $script:Config.DownloadUrlHigh } else { $script:Config.DownloadUrlLow }
    $zip = "$($script:Config.TempDir)\modpack.zip"
    
    $script:Status.Message = "Descargando..."
    $script:Status.SubProgress = "Conectando al servidor"
    Add-Log "Iniciando descarga..."
    $script:Status.Progress = 20
    
    try {
        # Start download in background job
        $script:Status.SubProgress = "Iniciando descarga..."
        $script:Status.Progress = 20
        
        $job = Start-Job -ScriptBlock {
            param($url, $zip)
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url, $zip)
        } -ArgumentList $url, $zip
        
        # Monitor file size and update progress continuously
        $estimatedSize = 150MB  # Approximate modpack size
        $lastSize = 0
        $dotCount = 0
        
        while ($job.State -eq 'Running') {
            Start-Sleep -Milliseconds 300
            
            if (Test-Path $zip) {
                $currentSize = (Get-Item $zip).Length
                if ($currentSize -gt $lastSize) {
                    $lastSize = $currentSize
                    # Map file progress (0-100%) to UI progress (20-55%)
                    $filePercent = [math]::Min(100, [int](($currentSize / $estimatedSize) * 100))
                    $script:Status.Progress = 20 + [int]($filePercent * 0.35)
                    $sizeMB = [math]::Round($currentSize / 1MB, 1)
                    $script:Status.SubProgress = "Descargando... $sizeMB MB"
                }
            } else {
                # Still connecting, show animation
                $dotCount = ($dotCount + 1) % 4
                $dots = "." * $dotCount
                $script:Status.SubProgress = "Conectando$dots"
            }
        }
        
        # Check for errors
        $result = Receive-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force
        
        if (-not (Test-Path $zip)) {
            throw "Descarga fallida"
        }
        
        Add-Log "Descarga completada"
        $script:Status.Progress = 55
    } catch {
        Add-Log "ERROR: $($_.Exception.Message)"
        $script:Status.Message = "Error de descarga"
        $script:Status.Phase = "error"
        $script:Installing = $false
        return $false
    }
    
    # Clean old mods
    $script:Status.Message = "Limpiando..."
    $script:Status.SubProgress = "Eliminando mods antiguos"
    $modsPath = "$($script:Config.MinecraftPath)\mods"
    if (Test-Path $modsPath) {
        $count = (Get-ChildItem $modsPath -ErrorAction SilentlyContinue).Count
        if ($count -gt 0) {
            Add-Log "Eliminando $count mods antiguos..."
            Remove-Item "$modsPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    $script:Status.Progress = 60
    
    # Extract
    $script:Status.Message = "Extrayendo..."
    $script:Status.SubProgress = "Descomprimiendo archivos"
    Add-Log "Extrayendo modpack..."
    
    $extract = "$($script:Config.TempDir)\extracted"
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue }
    
    try {
        Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    } catch {
        Add-Log "ERROR: No se pudo extraer"
        $script:Status.Message = "Error al extraer"
        $script:Status.Phase = "error"
        $script:Installing = $false
        return $false
    }
    $script:Status.Progress = 75
    
    # Find source folder
    $items = Get-ChildItem $extract
    $src = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $extract }
    
    # Copy files
    $script:Status.Message = "Instalando..."
    $script:Status.SubProgress = "Copiando archivos"
    Add-Log "Instalando archivos..."
    
    Copy-Item -Path "$src\*" -Destination $script:Config.MinecraftPath -Recurse -Force
    $script:Status.Progress = 90
    
    # Cleanup
    $script:Status.Message = "Finalizando..."
    $script:Status.SubProgress = "Limpiando temporales"
    if (Test-Path $script:Config.TempDir) { 
        Remove-Item $script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue 
    }
    $script:Status.Progress = 100
    
    $script:Status.Message = "Instalacion completada!"
    $script:Status.SubProgress = "Listo para jugar"
    $script:Status.Phase = "complete"
    Add-Log "=== INSTALACION EXITOSA ==="
    
    $script:Installing = $false
    return $true
}

function New-Backup {
    Add-Log "Creando backup..."
    $script:Status.Message = "Creando backup..."
    $script:Status.SubProgress = "Preparando"
    $script:Status.Progress = 10
    $script:Status.Phase = "backup"
    
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $dir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$ts"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    
    $total = $script:Config.ManagedFolders.Count
    $copied = 0
    $current = 0
    
    foreach ($item in $script:Config.ManagedFolders) {
        $current++
        $p = "$($script:Config.MinecraftPath)\$item"
        $script:Status.SubProgress = "Copiando $item..."
        $script:Status.Progress = [int](10 + (80 * $current / $total))
        
        if (Test-Path $p) { 
            Copy-Item -Path $p -Destination $dir -Recurse -ErrorAction SilentlyContinue
            $copied++
        }
        Start-Sleep -Milliseconds 100
    }
    
    $script:Status.Progress = 100
    Add-Log "Backup: $dir ($copied items)"
    $script:Status.Message = "Backup creado"
    $script:Status.SubProgress = "Guardado en Escritorio"
    $script:Status.Phase = "ready"
    return $dir
}

function Remove-Modpack {
    Add-Log "Eliminando mods..."
    $script:Status.Message = "Eliminando..."
    $script:Status.SubProgress = "Borrando archivos"
    $script:Status.Progress = 10
    $script:Status.Phase = "deleting"
    
    $total = $script:Config.ManagedFolders.Count
    $removed = 0
    $current = 0
    
    foreach ($item in $script:Config.ManagedFolders) {
        $current++
        $p = "$($script:Config.MinecraftPath)\$item"
        $script:Status.SubProgress = "Eliminando $item..."
        $script:Status.Progress = [int](10 + (80 * $current / $total))
        
        if (Test-Path $p) { 
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
            $removed++
        }
        Start-Sleep -Milliseconds 100
    }
    
    $script:Status.Progress = 100
    Add-Log "Eliminados: $removed elementos"
    $script:Status.Message = "Mods eliminados"
    $script:Status.SubProgress = "$removed elementos borrados"
    $script:Status.Phase = "ready"
}

function Open-MinecraftLauncher {
    Add-Log "Abriendo Minecraft..."
    $script:Status.Message = "Abriendo Minecraft..."
    
    # Official Minecraft Launcher paths
    $paths = @(
        "$env:ProgramFiles\Minecraft Launcher\MinecraftLauncher.exe",
        "${env:ProgramFiles(x86)}\Minecraft Launcher\MinecraftLauncher.exe",
        "$env:LOCALAPPDATA\Programs\Minecraft Launcher\MinecraftLauncher.exe"
    )
    
    # TLauncher paths (including inside .minecraft folder)
    $paths += @(
        "$env:APPDATA\.minecraft\TLauncher.exe",
        "$env:APPDATA\.minecraft\TLauncher32bit.exe",
        "$env:APPDATA\.tlauncher\TLauncher.exe",
        "$env:USERPROFILE\.tlauncher\TLauncher.exe",
        "$env:LOCALAPPDATA\TLauncher\TLauncher.exe",
        "$env:ProgramFiles\TLauncher\TLauncher.exe",
        "${env:ProgramFiles(x86)}\TLauncher\TLauncher.exe"
    )
    
    # SKLauncher paths
    $paths += @(
        "$env:APPDATA\SKLauncher\SKLauncher.exe",
        "$env:USERPROFILE\SKLauncher\SKLauncher.exe"
    )
    
    # Other popular launchers
    $paths += @(
        "$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe",
        "$env:ProgramFiles\PrismLauncher\prismlauncher.exe",
        "$env:APPDATA\MultiMC\MultiMC.exe",
        "$env:LOCALAPPDATA\ATLauncher\ATLauncher.exe"
    )
    
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Start-Process $p
            Add-Log "Launcher abierto: $p"
            return $true
        }
    }
    
    # Try Start Menu - search for any Minecraft or launcher shortcut
    $searchTerms = @("*Minecraft*", "*TLauncher*", "*SKLauncher*", "*Prism*", "*MultiMC*")
    foreach ($term in $searchTerms) {
        $link = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu" -Filter $term -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($link) {
            Start-Process $link.FullName
            Add-Log "Launcher abierto desde Start Menu: $($link.Name)"
            return $true
        }
    }
    
    # Also check Desktop for launcher shortcuts
    $desktop = [Environment]::GetFolderPath("Desktop")
    foreach ($term in $searchTerms) {
        $link = Get-ChildItem $desktop -Filter $term -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($link) {
            Start-Process $link.FullName
            Add-Log "Launcher abierto desde Escritorio: $($link.Name)"
            return $true
        }
    }
    
    # Try MS Store app
    try {
        Start-Process "shell:AppsFolder\Microsoft.4297127D64EC6_8wekyb3d8bbwe!Minecraft"
        Add-Log "Launcher abierto (MS Store)"
        return $true
    } catch {}
    
    Add-Log "No se encontro el launcher"
    $script:Status.Message = "Launcher no encontrado - Abrelo manualmente"
    return $false
}

# ==================== HTML ====================

$HTML = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PaisaLand Installer</title>
    <link rel="icon" type="image/png" href="https://i.imgur.com/12N1q3o.png">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/feather-icons"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --bg1: #0a0a0f;
            --bg2: #12121a;
            --bg3: #1a1a25;
            --card: rgba(255,255,255,0.02);
            --border: rgba(255,255,255,0.06);
            --text1: #ffffff;
            --text2: rgba(255,255,255,0.7);
            --text3: rgba(255,255,255,0.4);
            --green: #10b981;
            --green2: #059669;
            --red: #ef4444;
            --yellow: #f59e0b;
            --blue: #3b82f6;
            /* Tooltip vars: Inverted for high contrast */
            --tooltip-bg: rgba(255, 255, 255, 0.95);
            --tooltip-text: #111;
            --tooltip-border: rgba(0,0,0,0.1);
        }
        body.light {
            --bg1: #f8fafc;
            --bg2: #ffffff;
            --bg3: #f1f5f9;
            --card: rgba(0,0,0,0.02);
            --border: #e2e8f0;
            --text1: #0f172a;
            --text2: #475569;
            --text3: #94a3b8;
            /* Tooltip vars: Dark for light mode */
            --tooltip-bg: rgba(20, 20, 20, 0.95);
            --tooltip-text: #fff;
            --tooltip-border: rgba(255,255,255,0.1);
        }
        body {
            font-family: 'Inter', sans-serif;
            background: var(--bg1);
            min-height: 100vh;
            color: var(--text1);
            overflow-x: hidden;
            overflow-y: scroll; /* Force scrollbar to prevent layout shift */
        }
        
        /* Layout */
        .app {
            max-width: 900px;
            margin: 0 auto;
            padding: 30px 20px;
        }
        
        /* Header */
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid var(--border);
        }
        .brand {
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .brand-icon {
            width: 50px; height: 50px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            object-fit: contain;
        }
        .brand h1 {
            font-size: 26px;
            font-weight: 700;
        }
        .brand h1 span { color: var(--green); }
        .server-badge {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 16px;
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 10px;
            font-size: 13px;
            color: var(--text2);
            opacity: 0;
            opacity: 0;
            animation: fadeIn 0.5s ease forwards;
        }
        @keyframes fadeIn {
            to { opacity: 1; }
        }
        .server-dot {
            width: 8px; height: 8px;
            border-radius: 50%;
            background: var(--red);
        }
        .server-dot.online { background: var(--green); box-shadow: 0 0 10px var(--green); }
        
        .server-text {
            cursor: pointer;
            transition: all 0.3s ease;
        }
        .server-text.masked {
            filter: blur(5px);
            opacity: 0.7;
            user-select: none;
        }
        .server-text.masked:hover {
            opacity: 1;
            filter: blur(4px);
        }
        
        /* Main Grid */
        .main-grid {
            display: grid;
            grid-template-columns: 320px 1fr;
            gap: 24px;
        }
        
        /* Sidebar */
        .sidebar {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }
        .sidebar-card {
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 20px;
            opacity: 0;
            animation: fadeInUp 0.5s ease forwards;
        }
        /* Stagger for sidebar cards */
        .sidebar-card:nth-child(1) { animation-delay: 0.2s; }
        .sidebar-card:nth-child(2) { animation-delay: 0.3s; }
        
        /* Define fadeInUp globally if not already */
        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(15px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .sidebar-card h3 {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            color: var(--text3);
            margin-bottom: 16px;
        }
        
        /* Check items */
        .check-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .check-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            background: var(--bg3);
            border-radius: 10px;
            cursor: pointer;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s;
            animation: fadeInUp 0.4s ease forwards;
        }
        /* Removed item-level animations */
        /* .check-item:nth-child... */
        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .check-item:hover { background: rgba(255,255,255,0.05); }
        .check-icon {
            width: 32px; height: 32px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
        }
        .check-icon.ok { background: rgba(16,185,129,0.15); color: var(--green); }
        .check-icon.warn { background: rgba(245,158,11,0.15); color: var(--yellow); }
        .check-icon.error { background: rgba(239,68,68,0.15); color: var(--red); }
        .check-icon.loading { background: rgba(59,130,246,0.15); color: var(--blue); }
        .check-info { flex: 1; }
        .check-info h4 { font-size: 13px; font-weight: 600; margin-bottom: 2px; }
        .check-info p { font-size: 11px; color: var(--text3); }
        .check-arrow { color: var(--text3); }
        
        /* Main content */
        .main-content {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }
        
        /* Version selector */
        .version-section {
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 24px;
        }
        .version-section h3 {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 6px;
        }
        .version-section p {
            font-size: 13px;
            color: var(--text3);
            margin-bottom: 20px;
        }
        .version-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 14px;
        }
        .version-card {
            padding: 24px;
            background: var(--bg3);
            border: 2px solid transparent;
            border-radius: 14px;
            cursor: pointer;
            transition: all 0.3s;
            text-align: center;
        }
        .version-card:hover { border-color: var(--text3); }
        .version-card.active { border-color: var(--green); background: rgba(16,185,129,0.08); }
        .version-card i { color: var(--text3); margin-bottom: 12px; }
        .version-card.active i { color: var(--green); }
        .version-card h4 { font-size: 16px; font-weight: 600; margin-bottom: 6px; }
        .version-card.active h4 { color: var(--green); }
        .version-card span { font-size: 12px; color: var(--text3); }
        
        /* Progress section */
        .progress-section {
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 24px;
            opacity: 0;
            animation: fadeInUp 0.5s ease 0.3s forwards;
        }
        .version-section {
            opacity: 0;
            animation: fadeInUp 0.5s ease 0.2s forwards;
        }
        .main-content {
            /* No animation on container, let children animate */
        }
        /* Removed fadeSlideIn, using fadeInUp globally */
        .progress-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 16px;
        }
        .progress-info h3 { font-size: 16px; font-weight: 600; margin-bottom: 4px; }
        .progress-info p { font-size: 12px; color: var(--text3); }
        .progress-percent { font-size: 28px; font-weight: 700; color: var(--green); }
        .progress-bar {
            height: 10px;
            background: var(--bg3);
            border-radius: 5px;
            overflow: hidden;
            margin-bottom: 20px;
        }
        .progress-fill {
            height: 100%;
            width: 0%;
            background: linear-gradient(90deg, var(--green), #34d399);
            border-radius: 5px;
            transition: width 0.3s ease;
        }
        .progress-fill.active {
            background-size: 200% 100%;
            animation: shimmer 1.5s linear infinite;
        }
        @keyframes shimmer {
            0% { background-position: 100% 0; }
            100% { background-position: -100% 0; }
        }
        
        /* Action buttons */
        .action-row {
            display: flex;
            gap: 12px;
        }
        .btn-install {
            flex: 1;
            padding: 18px 24px;
            background: linear-gradient(135deg, var(--green), var(--green2));
            border: none;
            border-radius: 12px;
            color: white;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            transition: all 0.3s;
            box-shadow: 0 4px 20px rgba(16,185,129,0.25);
        }
        .btn-install:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(16,185,129,0.35); }
        .btn-install:disabled { background: var(--bg3); color: var(--text3); cursor: not-allowed; box-shadow: none; }
        .btn-install.complete { background: linear-gradient(135deg, #047857, #065f46); box-shadow: 0 4px 20px rgba(4,120,87,0.35); }
        
        .btn-action {
            padding: 18px;
            background: var(--bg3);
            border: 1px solid var(--border);
            border-radius: 12px;
            color: var(--text2);
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .btn-action:hover { background: rgba(255,255,255,0.08); color: var(--text1); }
        .btn-action.danger { border-color: rgba(239,68,68,0.3); color: var(--red); }
        .btn-action.danger:hover { background: rgba(239,68,68,0.1); }
        
        /* Log */
        .log-section {
            border: 1px solid var(--border);
            border-radius: 16px;
            overflow: hidden;
            opacity: 0;
            animation: fadeInUp 0.5s ease 0.4s forwards;
        }
        .log-header {
            padding: 14px 20px;
            background: var(--bg3);
            border-bottom: 1px solid var(--border);
            font-size: 12px;
            font-weight: 600;
            color: var(--text3);
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .log-content {
            padding: 16px;
            height: 150px;
            overflow-y: auto;
            font-family: 'Consolas', 'Monaco', monospace;
        }
        .log-line {
            font-size: 11px;
            color: var(--green);
            line-height: 1.8;
            opacity: 0.85;
        }
        
        /* Modal */
        .modal-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0,0,0,0.8);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s;
        }
        .modal-overlay.show { opacity: 1; visibility: visible; }
        .modal {
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 30px;
            max-width: 450px;
            width: 90%;
            transform: translateY(20px);
            transition: transform 0.3s;
        }
        .modal-overlay.show .modal { transform: translateY(0); }
        .modal-icon {
            width: 60px; height: 60px;
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 20px;
            font-size: 24px;
        }
        .modal-icon.error { background: rgba(239,68,68,0.15); color: var(--red); }
        .modal-icon.warn { background: rgba(245,158,11,0.15); color: var(--yellow); }
        .modal-icon.ok { background: rgba(16,185,129,0.15); color: var(--green); }
        .modal h2 { font-size: 20px; margin-bottom: 10px; }
        .modal p { font-size: 14px; color: var(--text2); line-height: 1.6; margin-bottom: 20px; }
        .modal-link {
            display: block;
            padding: 14px 20px;
            background: var(--green);
            border-radius: 10px;
            color: white;
            text-decoration: none;
            font-weight: 600;
            text-align: center;
            margin-bottom: 12px;
            transition: all 0.2s;
        }
        .modal-link:hover { background: var(--green2); }
        .modal-close {
            display: block;
            width: 100%;
            padding: 12px;
            background: transparent;
            border: 1px solid var(--border);
            border-radius: 10px;
            color: var(--text2);
            font-size: 14px;
            cursor: pointer;
            transition: all 0.2s;
        }
        .modal-close:hover { background: var(--bg3); }
        
        /* Custom Tooltip */
        #tooltip {
            position: fixed;
            background: var(--tooltip-bg);
            color: var(--tooltip-text);
            padding: 8px 12px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 500;
            pointer-events: none;
            opacity: 0;
            z-index: 99999;
            border: 1px solid var(--tooltip-border);
            white-space: nowrap;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            transform: translate(-50%, -10px) scale(0.95);
            transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        #tooltip.show { 
            opacity: 1; 
            transform: translate(-50%, -100%) scale(1);
        }
        /* Arrow */
        #tooltip::after {
            content: '';
            position: absolute;
            top: 100%;
            left: 50%;
            margin-left: -6px;
            border-width: 6px;
            border-style: solid;
            border-color: var(--tooltip-bg) transparent transparent transparent;
        }
        
        /* Mobile Repairs */
        @media (max-width: 600px) {
            .header { flex-direction: column; align-items: flex-start; gap: 20px; }
            .brand { width: 100%; justify-content: space-between; }
            .server-badge { width: 100%; justify-content: center; }
            /* Truncate IP on mobile or hide if too long */
            #serverIp { 
                max-width: 150px; 
                overflow: hidden; 
                text-overflow: ellipsis; 
                white-space: nowrap; 
                display: inline-block; 
                vertical-align: bottom;
            }
            .main-grid { grid-template-columns: 1fr; }
            .sidebar { order: 2; }
        }
        
        /* Toast */
        .toast {
            position: fixed;
            bottom: 30px;
            right: 30px;
            padding: 16px 24px;
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 12px;
            display: flex;
            align-items: center;
            gap: 12px;
            transform: translateY(100px);
            opacity: 0;
            transition: all 0.3s;
            z-index: 900;
        }
        .toast.show { transform: translateY(0); opacity: 1; }
        .toast.success { border-color: var(--green); }
        .toast.error { border-color: var(--red); }
        .toast-icon { font-size: 18px; }
        .toast.success .toast-icon { color: var(--green); }
        .toast.error .toast-icon { color: var(--red); }
        .toast-text { font-size: 14px; }
        
        /* Theme Button */
        .theme-btn {
            width: 40px; height: 40px;
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 10px;
            color: var(--text2);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s;
            opacity: 0;
            animation: fadeIn 0.5s ease forwards;
        }
        .theme-btn:hover { background: var(--bg3); color: var(--text1); }
        
        /* Welcome Banner */
        .welcome-banner {
            display: flex;
            align-items: center;
            gap: 16px;
            padding: 16px 20px;
            background: linear-gradient(135deg, rgba(16,185,129,0.1), rgba(59,130,246,0.1));
            border: 1px solid var(--border);
            border-radius: 14px;
            margin-bottom: 24px;
            position: relative; /* For absolute close button */
            align-items: flex-start; /* Align top for long text */
            opacity: 0;
            animation: fadeInUp 0.5s ease 0.1s forwards;
        }
        .welcome-banner.hidden { 
            animation: bannerClose 0.6s cubic-bezier(0.4, 0, 0.2, 1) forwards;
        }
        @keyframes bannerClose {
            0% { 
                opacity: 1; 
                transform: scale(1);
                max-height: 200px; 
                margin-bottom: 24px;
                padding: 16px 20px;
                border: 1px solid var(--border);
            }
            30% {
                opacity: 0;
                transform: scale(0.95);
            }
            100% { 
                opacity: 0; 
                transform: scale(0.9);
                max-height: 0; 
                margin-bottom: 0; 
                padding: 0 20px; /* Keep horizontal padding to prevent text squish, reduce vertical */
                padding-top: 0;
                padding-bottom: 0;
                border: 0 solid transparent;
                margin-top: 0;
            }
        }
        .welcome-icon {
            width: 40px; height: 40px;
            background: var(--green);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            flex-shrink: 0;
        }
        .welcome-content { flex: 1; }
        .welcome-content h3 { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
        .welcome-content p { font-size: 12px; color: var(--text2); line-height: 1.5; }
        .welcome-content strong { color: var(--green); }
        .welcome-close {
            width: 32px; height: 32px;
            background: transparent;
            border: none;
            color: var(--text3);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 8px;
            transition: all 0.2s;
        }
        .welcome-close:hover { background: var(--bg3); color: var(--text1); }
        
        /* Footer */
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .footer-left { font-size: 12px; color: var(--text3); }
        .footer-left a { color: var(--green); text-decoration: none; }
        .footer-right { display: flex; align-items: center; gap: 12px; }
        .footer-version {
            font-size: 11px;
            color: var(--text3);
            padding: 4px 12px;
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 20px;
        }
        
        /* Responsive */
        /* Responsive */
        @media (max-width: 768px) {
            .header { flex-direction: column; gap: 16px; align-items: center; }
            .brand { width: auto; justify-content: center; }
            .server-badge { width: 100%; justify-content: center; }
            .main-grid { grid-template-columns: 1fr; }
            .sidebar { order: 2; }
            /* Banner stays row but responsive */
            .welcome-banner { padding: 16px; }
            .welcome-icon { width: 32px; height: 32px; }
            .welcome-content h3 { font-size: 13px; }
        }
    </style>
</head>
<body>
    <div class="app">
        <header class="header">
            <div class="brand">
                <img src="https://i.imgur.com/12N1q3o.png" alt="Logo" class="brand-icon" style="background:none; box-shadow:none; padding:0;">
                <h1>PAISA<span>LAND</span></h1>
            </div>
            <div style="display:flex;align-items:center;gap:12px;">
                <div class="server-badge" onclick="toggleServerIp()" style="cursor: pointer;" data-title="Clic para ver IP">
                    <div class="server-dot" id="serverDot"></div>
                    <span id="serverStatus">Verificando...</span>
                    <span id="serverSep" style="display:none;">- </span>
                    <span id="serverIp" class="server-text masked" style="font-family: monospace;"></span>
                </div>
                <button class="theme-btn" id="themeBtn" onclick="toggleTheme()" data-title="Cambiar tema">
                    <i data-feather="moon"></i>
                </button>
            </div>
        </header>
        
        <!-- Welcome Guide -->
        <div class="welcome-banner" id="welcomeBanner">
            <div class="welcome-icon"><i data-feather="info"></i></div>
            <div class="welcome-content" style="padding-right: 20px;">
                <h3>Bienvenido al Instalador de PaisaLand</h3>
                <p>Sigue estos pasos: <strong>1.</strong> Verifica que todo este en verde a la izquierda <strong>2.</strong> Selecciona tu version <strong>3.</strong> Haz clic en Instalar</p>
            </div>
            <button onclick="closeWelcome()" style="background:none; border:none; color:var(--text2); cursor:pointer; position:absolute; top:10px; right:10px; z-index:10; width:30px; height:30px; display:flex; align-items:center; justify-content:center; padding:0;">
                <i data-feather="x" style="width:20px; height:20px;"></i>
            </button>
        </div>
        
        <div class="main-grid">
            <aside class="sidebar">
                <div class="sidebar-card">
                    <h3>Estado del Sistema</h3>
                    <div class="check-list">
                        <div class="check-item" id="checkJava" onclick="showHelp('java')">
                            <div class="check-icon loading" id="iconJava"><i data-feather="coffee"></i></div>
                            <div class="check-info">
                                <h4>Java</h4>
                                <p id="statusJava">Verificando...</p>
                            </div>
                            <i data-feather="chevron-right" class="check-arrow"></i>
                        </div>
                        <div class="check-item" id="checkMC" onclick="showHelp('minecraft')">
                            <div class="check-icon loading" id="iconMC"><i data-feather="box"></i></div>
                            <div class="check-info">
                                <h4>Minecraft</h4>
                                <p id="statusMC">Verificando...</p>
                            </div>
                            <i data-feather="chevron-right" class="check-arrow"></i>
                        </div>
                        <div class="check-item" id="checkForge" onclick="showHelp('forge')">
                            <div class="check-icon loading" id="iconForge"><i data-feather="tool"></i></div>
                            <div class="check-info">
                                <h4>Forge</h4>
                                <p id="statusForge">Verificando...</p>
                            </div>
                            <i data-feather="chevron-right" class="check-arrow"></i>
                        </div>
                        <div class="check-item" id="checkRAM">
                            <div class="check-icon loading" id="iconRAM"><i data-feather="cpu"></i></div>
                            <div class="check-info">
                                <h4>Memoria RAM</h4>
                                <p id="statusRAM">Verificando...</p>
                            </div>
                        </div>
                        <div class="check-item" id="checkDisk">
                            <div class="check-icon loading" id="iconDisk"><i data-feather="hard-drive"></i></div>
                            <div class="check-info">
                                <h4>Espacio en Disco</h4>
                                <p id="statusDisk">Verificando...</p>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="sidebar-card">
                    <h3>Acciones Rapidas</h3>
                    <div style="display: flex; flex-direction: column; gap: 10px;">
                        <button class="btn-action" onclick="showGuide()" style="width:100%; justify-content: flex-start; gap: 12px; padding: 14px 16px; background: var(--bg3); border:1px solid var(--border);">
                            <i data-feather="book-open"></i> Guia de Instalacion
                        </button>
                        <button class="btn-action" onclick="backup()" style="width:100%; justify-content: flex-start; gap: 12px; padding: 14px 16px;">
                            <i data-feather="save"></i> Crear Backup
                        </button>
                        <button class="btn-action danger" onclick="showConfirmUninstall()" style="width:100%; justify-content: flex-start; gap: 12px; padding: 14px 16px;">
                            <i data-feather="trash-2"></i> Limpiar Todo
                        </button>
                    </div>
                </div>
            </aside>
            
            <main class="main-content">
                <div class="version-section">
                    <h3>Selecciona tu Version</h3>
                    <p>Elige segun el rendimiento de tu PC</p>
                    <div class="version-grid">
                        <div class="version-card active" id="versionLow" onclick="selectVersion(false)">
                            <i data-feather="zap"></i>
                            <h4>Gama Baja</h4>
                            <span>Optimizado para FPS</span>
                        </div>
                        <div class="version-card" id="versionHigh" onclick="selectVersion(true)">
                            <i data-feather="star"></i>
                            <h4>Gama Alta</h4>
                            <span>Shaders + Texturas HD</span>
                        </div>
                    </div>
                </div>
                
                <div class="progress-section">
                    <div class="progress-header">
                        <div class="progress-info">
                            <h3 id="progressTitle">Listo para instalar</h3>
                            <p id="progressSub">Selecciona una version y haz clic en Instalar</p>
                        </div>
                        <div class="progress-percent" id="progressPercent">0%</div>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" id="progressFill"></div>
                    </div>
                    <div class="action-row">
                        <button class="btn-install" id="btnInstall" onclick="install()">
                            <i data-feather="download"></i>
                            <span>Instalar Modpack</span>
                        </button>
                    </div>
                </div>
                
                <div class="log-section">
                    <div class="log-header">Registro de Actividad</div>
                    <div class="log-content" id="logBox"></div>
                </div>
            </main>
        </div>
        
        <!-- Footer -->
        <footer class="footer">
            <div class="footer-left">
                Creado por con &#10084; por <a href="https://github.com/JharlyOk" target="_blank">JharlyOk</a> para la comunidad PaisaLand.
            </div>
            <div class="footer-right">
                <span class="footer-version">v9.0.0</span>
            </div>
        </footer>
    </div>
    
    <!-- Help Modal -->
    <div class="modal-overlay" id="modalOverlay" onclick="closeModal()">
        <div class="modal" onclick="event.stopPropagation()">
            <div class="modal-icon" id="modalIcon"><i data-feather="alert-circle"></i></div>
            <h2 id="modalTitle">Ayuda</h2>
            <p id="modalText">Informacion de ayuda</p>
            <a class="modal-link" id="modalLink" href="#" target="_blank">Descargar</a>
            <button class="modal-close" onclick="closeModal()">Cerrar</button>
        </div>
    </div>
    
    <!-- Confirm Modal -->
    <div class="modal-overlay" id="confirmOverlay" onclick="closeConfirm()">
        <div class="modal" onclick="event.stopPropagation()">
            <div class="modal-icon warn"><i data-feather="alert-triangle"></i></div>
            <h2>Confirmar Limpieza</h2>
            <p>Esto eliminara: mods, config, shaders, resourcepacks y emotes.<br><br>Esta accion no se puede deshacer.</p>
            <div style="display: flex; gap: 12px; margin-top: 20px;">
                <button class="modal-close" onclick="closeConfirm()" style="flex: 1; padding: 14px;">Cancelar</button>
                <button class="btn-danger" onclick="confirmUninstall()" style="flex: 1; padding: 14px; background: linear-gradient(135deg, #ef4444, #dc2626); border: none; border-radius: 10px; color: white; font-size: 14px; font-weight: 600; cursor: pointer;">Eliminar</button>
            </div>
        </div>
    </div>
    
    <!-- Backup Warning Modal -->
    <div class="modal-overlay" id="backupOverlay" onclick="closeBackupWarning()">
        <div class="modal" onclick="event.stopPropagation()">
            <div class="modal-icon warn"><i data-feather="alert-circle"></i></div>
            <h2>Precauci&oacute;n</h2>
            <p>La instalaci&oacute;n eliminar&aacute; tus mods, shaders y configuraciones actuales.<br><br>&iquest;Deseas hacer una copia de seguridad antes de continuar?</p>
            <div style="display: flex; gap: 12px; margin-top: 20px; flex-direction: column;">
                <button class="btn-action" onclick="installWithBackup()" style="justify-content: center; background: linear-gradient(135deg, var(--green), var(--green2)); border:none; color:white;">
                    <i data-feather="save"></i> Hacer Backup y Continuar
                </button>
                <button class="btn-action" onclick="startInstall()" style="justify-content: center; background: var(--bg3); border:1px solid var(--border);">
                    <i data-feather="arrow-right"></i> Instalar sin Backup
                </button>
                 <button class="modal-close" onclick="closeBackupWarning()" style="width:100%">Cancelar</button>
            </div>
        </div>
    </div>
    
    <!-- Toast -->
    <div class="toast" id="toast">
        <i data-feather="check-circle" class="toast-icon"></i>
        <span class="toast-text" id="toastText">Mensaje</span>
    </div>
    
    <script>
        var API = 'http://localhost:{{PORT}}';
        var isHighSpec = false;
        var systemData = {};
        var isLocalProcessing = false; // Track local processing state
        
        feather.replace();
        
        // Theme Toggle
        var isDark = true;
        function toggleTheme() {
            isDark = !isDark;
            document.body.classList.toggle('light', !isDark);
            var btn = document.getElementById('themeBtn');
            btn.innerHTML = isDark ? '<i data-feather="moon"></i>' : '<i data-feather="sun"></i>';
            feather.replace();
        }
        
        // Close Welcome Banner
        function closeWelcome() {
            document.getElementById('welcomeBanner').classList.add('hidden');
        }
        
        function selectVersion(high) {
            isHighSpec = high;
            document.getElementById('versionLow').classList.toggle('active', !high);
            document.getElementById('versionHigh').classList.toggle('active', high);
            // Reset button if completed
            resetButtonState();
        }
        
        function resetButtonState() {
            var btn = document.getElementById('btnInstall');
            btn.className = 'btn-install';
            btn.innerHTML = '<i data-feather="download"></i><span>Instalar Modpack</span>';
            btn.disabled = false;
            document.getElementById('progressFill').style.width = '0%';
            document.getElementById('progressPercent').textContent = '0%';
            document.getElementById('progressTitle').textContent = 'Listo para instalar';
            document.getElementById('progressSub').textContent = 'Selecciona una version y haz clic en Instalar';
            feather.replace();
            fetch(API + '/reset', { method: 'POST' }).catch(function(){});
        }
        
        function showToast(msg, type) {
            var t = document.getElementById('toast');
            document.getElementById('toastText').textContent = msg;
            t.className = 'toast ' + (type || '') + ' show';
            setTimeout(function() { t.classList.remove('show'); }, 3000);
        }
        
        var helpData = {
            java: {
                icon: 'error',
                title: 'Java no detectado',
                text: 'Minecraft necesita Java para funcionar. Descarga e instala Java 17 o superior desde el sitio oficial.',
                link: 'https://www.oracle.com/java/technologies/downloads/',
                linkText: 'Descargar Java'
            },
            minecraft: {
                icon: 'error',
                title: 'Minecraft no encontrado',
                text: 'No se encontro una instalacion de Minecraft. Descarga el launcher oficial e inicia sesion al menos una vez.',
                link: 'https://www.minecraft.net/download',
                linkText: 'Descargar Minecraft'
            },
            forge: {
                icon: 'warn',
                title: 'Forge no instalado',
                text: 'Forge es necesario para ejecutar mods. Descarga el instalador de Forge 1.20.1 y ejecutalo.',
                link: 'https://files.minecraftforge.net/net/minecraftforge/forge/index_1.20.1.html',
                linkText: 'Descargar Forge'
            },
            java_ok: {
                icon: 'ok',
                title: 'Java OK',
                text: 'Java esta instalado correctamente. No necesitas hacer nada.',
                hideLink: true
            },
            minecraft_ok: {
                icon: 'ok',
                title: 'Minecraft OK',
                text: 'Minecraft esta instalado correctamente. Puedes continuar con la instalacion.',
                hideLink: true
            },
            forge_ok: {
                icon: 'ok',
                title: 'Forge OK',
                text: 'Forge esta instalado correctamente. Ya puedes instalar el modpack.',
                hideLink: true
            }
        };
        
        function showHelp(type) {
            // Check if item is OK, show success message
            if (type === 'java' && systemData.java && systemData.java.ok) {
                type = 'java_ok';
            } else if (type === 'minecraft' && systemData.minecraft && systemData.minecraft.ok) {
                type = 'minecraft_ok';
            } else if (type === 'forge' && systemData.forge && systemData.forge.ok) {
                type = 'forge_ok';
            }
            
            var data = helpData[type];
            if (!data) return;
            
            document.getElementById('modalIcon').className = 'modal-icon ' + data.icon;
            document.getElementById('modalTitle').textContent = data.title;
            document.getElementById('modalText').textContent = data.text;
            
            var linkEl = document.getElementById('modalLink');
            if (data.hideLink) {
                linkEl.style.display = 'none';
            } else {
                linkEl.style.display = 'block';
                linkEl.href = data.link;
                linkEl.textContent = data.linkText;
            }
            
            document.getElementById('modalOverlay').classList.add('show');
        }
        
        function closeModal() {
            document.getElementById('modalOverlay').classList.remove('show');
        }
        
        function updateIcon(id, ok) {
            var el = document.getElementById(id);
            el.classList.remove('ok', 'warn', 'error', 'loading');
            if (ok === null) {
                el.classList.add('loading');
            } else {
                el.classList.add(ok ? 'ok' : 'error');
            }
        }
        
        function updateStatus() {
            fetch(API + '/status')
                .then(function(r) { return r.json(); })
                .then(function(d) {
                    // Progress
                    document.getElementById('progressTitle').textContent = d.message || 'Listo';
                    document.getElementById('progressSub').textContent = d.subProgress || '';
                    document.getElementById('progressPercent').textContent = d.progress + '%';
                    document.getElementById('progressFill').style.width = d.progress + '%';
                    
                    var fill = document.getElementById('progressFill');
                    var btn = document.getElementById('btnInstall');
                    // Consolidated button state based on backend phase OR local processing
                    var isBackendProcessing = d.installing || d.phase === 'deleting' || d.phase === 'backup' || 
                                       d.phase === 'downloading' || d.phase === 'extracting' || d.phase === 'installing';
                    var shouldDisable = isBackendProcessing || isLocalProcessing;
                    
                    if (shouldDisable) {
                        fill.classList.add('active');
                        setAllButtonsDisabled(true);
                        // Show processing state on main button
                        if (!btn.innerHTML.includes('Instalando') && !btn.innerHTML.includes('Jugar')) {
                            btn.innerHTML = '<i data-feather="loader"></i><span>Procesando...</span>';
                            feather.replace();
                        }
                    } else {
                        fill.classList.remove('active');
                        setAllButtonsDisabled(false);
                    }
                    
                    // Handle different phases for install button appearance
                    if (d.phase === 'complete') {
                        isLocalProcessing = false; // Reset local processing
                        setAllButtonsDisabled(false); // Re-enable all buttons
                        btn.className = 'btn-install complete';
                        btn.innerHTML = '<i data-feather="play"></i><span>Jugar Minecraft</span>';
                        btn.onclick = launch;
                        btn.disabled = false;
                        btn.style.opacity = '1';
                        btn.style.pointerEvents = 'auto';
                        feather.replace();
                    } else if (d.phase === 'ready' && d.progress === 0 && !isLocalProcessing) {
                        // Reset to normal state only if not locally processing
                        btn.className = 'btn-install';
                        btn.innerHTML = '<i data-feather="download"></i><span>Instalar Modpack</span>';
                        btn.onclick = install;
                        feather.replace();
                    }
                    
                    if (d.server) {
                        document.getElementById('serverDot').classList.toggle('online', d.server.online);
                        document.getElementById('serverStatus').textContent = d.server.msg;
                        // Only show IP if online
                        var ipEl = document.getElementById('serverIp');
                        var sepEl = document.getElementById('serverSep');
                        if (d.server.online) {
                            var fullAddr = d.server.ip + (d.server.port ? ':' + d.server.port : '');
                            ipEl.textContent = fullAddr;
                            ipEl.style.display = 'inline';
                            sepEl.style.display = 'inline';
                        } else {
                            ipEl.style.display = 'none';
                            sepEl.style.display = 'none';
                        }
                    }
                    
                    // System checks
                    if (d.system) {
                        systemData = d.system;
                        
                        updateIcon('iconJava', d.system.java.ok);
                        document.getElementById('statusJava').textContent = d.system.java.msg;
                        
                        updateIcon('iconMC', d.system.minecraft.ok);
                        document.getElementById('statusMC').textContent = d.system.minecraft.msg;
                        
                        updateIcon('iconForge', d.system.forge.ok);
                        document.getElementById('statusForge').textContent = d.system.forge.msg;
                        
                        updateIcon('iconRAM', d.system.ram.ok);
                        document.getElementById('statusRAM').textContent = d.system.ram.msg;
                        
                        if (d.system.disk) {
                            updateIcon('iconDisk', d.system.disk.ok);
                            document.getElementById('statusDisk').textContent = d.system.disk.msg;
                        }
                    }
                    
                    // Log
                    if (d.log && d.log.length) {
                        var box = document.getElementById('logBox');
                        box.innerHTML = d.log.map(function(l) { return '<div class="log-line">' + l + '</div>'; }).join('');
                        box.scrollTop = box.scrollHeight;
                    }
                })
                .catch(function() {});
        }
        
        function setAllButtonsDisabled(disabled) {
            // Disable action buttons (not theme toggle or close buttons)
            var btns = document.querySelectorAll('.btn-install, .btn-action');
            for (var i = 0; i < btns.length; i++) {
                btns[i].disabled = disabled;
                btns[i].style.opacity = disabled ? '0.5' : '1';
                btns[i].style.pointerEvents = disabled ? 'none' : 'auto';
            }
            // Disable version cards
            var cards = document.querySelectorAll('.version-card');
            for (var j = 0; j < cards.length; j++) {
                cards[j].style.pointerEvents = disabled ? 'none' : 'auto';
                cards[j].style.opacity = disabled ? '0.5' : '1';
            }
        }
        
        function install() {
             showBackupWarning();
        }

        // Actual install logic
        function startInstall() {
            closeBackupWarning();
            var btn = document.getElementById('btnInstall');
            isLocalProcessing = true;
            btn.innerHTML = '<i data-feather="loader"></i><span>Instalando, espere...</span>';
            feather.replace();
            showToast('Instalacion iniciada', 'success');
            setAllButtonsDisabled(true);
            fetch(API + '/install?high=' + isHighSpec, { method: 'POST' })
                .catch(function() { 
                    showToast('Error de conexion', 'error'); 
                    isLocalProcessing = false;
                    setAllButtonsDisabled(false);
                    btn.innerHTML = '<i data-feather="download"></i><span>Instalar Modpack</span>';
                    feather.replace();
                });
        }
        
        function backup() {
            isLocalProcessing = true;
            showToast('Creando backup...', 'success');
            setAllButtonsDisabled(true);
            return fetch(API + '/backup', { method: 'POST' })
                .then(function() { showToast('Backup guardado en Escritorio', 'success'); })
                .catch(function() {})
                .finally(function() { isLocalProcessing = false; setAllButtonsDisabled(false); });
        }

        function installWithBackup() {
            closeBackupWarning();
            // Manually disable buttons as backup() will re-enable them, 
            // but we want them disabled until install starts.
            // However, backup() is async and re-enables in finally.
            // We can just run backup, and ONCE it finishes, run install.
            // The flicker is negligible or we can accept it.
            backup().then(function() {
                // Wait small delay to ensure UI updates then start install
                setTimeout(startInstall, 500);
            });
        }

        function showBackupWarning() {
            document.getElementById('backupOverlay').classList.add('show');
            feather.replace();
        }

        function closeBackupWarning() {
            document.getElementById('backupOverlay').classList.remove('show');
        }

        function toggleServerIp() {
            var el = document.getElementById('serverIp');
            var badge = document.querySelector('.server-badge');
            
            if (el.classList.contains('masked')) {
                el.classList.remove('masked');
                showToast('IP visible', 'success');
                badge.setAttribute('data-title', 'Clic para copiar IP');
                // Force update if tooltip is currently showing
                var tip = document.getElementById('tooltip');
                if (tip.classList.contains('show')) {
                    tip.textContent = 'Clic para copiar IP';
                }
            } else {
                navigator.clipboard.writeText(el.textContent);
                showToast('IP copiada al portapapeles', 'success');
            }
        }

        function showGuide() {
            document.getElementById('guideOverlay').classList.add('show');
        }

        function closeGuide() {
            document.getElementById('guideOverlay').classList.remove('show');
        }
        
        function launch() {
            showToast('Abriendo Minecraft...', 'success');
            fetch(API + '/launch', { method: 'POST' })
                .then(function(r) { return r.json(); })
                .then(function(d) {
                    if (!d.ok) {
                        showToast('Launcher no encontrado - Abrelo manualmente', 'error');
                    }
                })
                .catch(function() { showToast('Error al abrir launcher', 'error'); });
        }
        
        function showConfirmUninstall() {
            document.getElementById('confirmOverlay').classList.add('show');
        }
        
        function closeConfirm() {
            document.getElementById('confirmOverlay').classList.remove('show');
        }
        
        function confirmUninstall() {
            closeConfirm();
            isLocalProcessing = true;
            showToast('Limpiando instalacion...', 'success');
            setAllButtonsDisabled(true);
            fetch(API + '/uninstall', { method: 'POST' })
                .then(function() { showToast('Limpieza completada', 'success'); })
                .catch(function() {})
                .finally(function() { isLocalProcessing = false; setAllButtonsDisabled(false); });
        }
        
        // Fast polling - 300ms
        setInterval(updateStatus, 300);
        updateStatus();
    </script>
    <!-- Guide Modal -->
    <div class="modal-overlay" id="guideOverlay" onclick="closeGuide()">
        <div class="modal" onclick="event.stopPropagation()" style="width: 100%; max-width: 600px;">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:20px;">
                <h2 style="margin:0;">Guia de Instalacion</h2>
                <div onclick="closeGuide()" style="cursor:pointer;"><i data-feather="x"></i></div>
            </div>
            <div class="guide-steps" style="display:flex; flex-direction:column; gap:20px; max-height: 60vh; overflow-y:auto; padding-right:10px;">
                <div class="guide-step">
                    <h3 style="color:var(--green); margin-bottom:10px;">1. Instalar Launcher</h3>
                    <p style="font-size:14px; color:var(--text2); line-height:1.5;">Si aun no tienes Minecraft, necesitas un launcher. Recomendamos TLauncher (gratis) o el Launcher Oficial (si tienes cuenta).</p>
                    <div style="display:flex; gap:10px; margin-top:10px;">
                        <a href="https://tlauncher.org/en/" target="_blank" class="btn-action" style="text-decoration:none; height:auto; padding:8px 12px; font-size:13px;">Descargar TLauncher</a>
                        <a href="https://www.minecraft.net/en-us/download" target="_blank" class="btn-action" style="text-decoration:none; height:auto; padding:8px 12px; font-size:13px; background:var(--bg3);">Launcher Oficial</a>
                    </div>
                </div>
                <div class="guide-step">
                    <h3 style="color:var(--green); margin-bottom:10px;">2. Instalar Java y Forge</h3>
                    <p style="font-size:14px; color:var(--text2); line-height:1.5;">Necesitas <strong>Forge 1.20.1 (47.2.0)</strong>. Si no lo tienes, descargalo e instalalo (selecciona "Install Client").</p>
                    <div style="margin-top:10px;">
                        <a href="https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.2.0/forge-1.20.1-47.2.0-installer.jar" target="_blank" class="btn-action" style="text-decoration:none; height:auto; padding:8px 12px; font-size:13px;">Descargar Forge 1.20.1</a>
                    </div>
                </div>
                <div class="guide-step">
                    <h3 style="color:var(--green); margin-bottom:10px;">3. Usar este Instalador</h3>
                    <p style="font-size:14px; color:var(--text2); line-height:1.5;">En la pantalla principal, selecciona tu version (Gama Alta o Baja) y haz clic en <strong>"Instalar Modpack"</strong>. El programa hara todo por ti.</p>
                </div>
                <div class="guide-step">
                    <h3 style="color:var(--green); margin-bottom:10px;">4. Abrir Minecraft</h3>
                    <p style="font-size:14px; color:var(--text2); line-height:1.5;">Abre tu launcher y asegurate de seleccionar la version <strong>"release 1.20.1-forge-47.2.0"</strong> antes de jugar.</p>
                </div>
            </div>

            <button class="modal-close" onclick="closeGuide()" style="margin-top:20px; width:100%;">Entendido</button>
        </div>
    </div>

    <!-- Custom Tooltip Element -->
    <div id="tooltip"></div>

    <script>
    // Tooltip Logic
    function initTooltips() {
        var targets = document.querySelectorAll('[data-title]');
        var tip = document.getElementById('tooltip');
        
        for (var i = 0; i < targets.length; i++) {
            (function(target) {
                target.addEventListener('mouseenter', function() {
                    var text = target.getAttribute('data-title');
                    if (!text) return;
                    
                    tip.textContent = text;
                    tip.classList.add('show');
                    
                    // Static Position
                    var rect = target.getBoundingClientRect();
                    // Center horizontal, Top vertical (minus gap)
                    var left = rect.left + (rect.width / 2);
                    var top = rect.top - 12; // 12px gap above element
                    
                    // Edge detection (prevent overflow)
                    var tipWidth = tip.offsetWidth;
                    if (left - (tipWidth / 2) < 10) { // Too far left
                        left = (tipWidth / 2) + 10;
                    } else if (left + (tipWidth / 2) > window.innerWidth - 10) { // Too far right
                        left = window.innerWidth - (tipWidth / 2) - 10;
                    }

                    tip.style.left = left + 'px';
                    tip.style.top = top + 'px';
                });
                
                target.addEventListener('mouseleave', function() {
                    tip.classList.remove('show');
                });
                
                // Update on click (e.g. for IP copy)
                target.addEventListener('click', function() {
                     var newText = target.getAttribute('data-title');
                     if (newText) tip.textContent = newText;
                });
            })(targets[i]);
        }
    }
    
    // Initialize
    initTooltips();
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
        Write-Host "`n  [ERROR] Puerto $port en uso`n" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "  =========================================" -ForegroundColor Cyan
    Write-Host "       PaisaLand Installer v9.0         " -ForegroundColor White
    Write-Host "  =========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [OK] http://localhost:$port" -ForegroundColor Green
    Write-Host "  [OK] Abriendo navegador..." -ForegroundColor Green
    Write-Host ""
    
    # Open browser FIRST (system shows loading state)
    $htmlPath = "$env:TEMP\paisaland_v9.html"
    $HTML.Replace("{{PORT}}", $port) | Out-File -FilePath $htmlPath -Encoding UTF8
    Start-Process $htmlPath
    
    # Start delayed system checks in background
    Start-Job -ScriptBlock {
        Start-Sleep -Seconds 1
    } | Wait-Job | Out-Null
    
    # Now run checks (UI will update via polling)
    Invoke-SystemCheck
    $serverStatus = Get-ServerStatus
    
    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "*")
            
            if ($request.HttpMethod -eq "OPTIONS") { $response.StatusCode = 200; $response.Close(); continue }
            
            $path = $request.Url.LocalPath
            $result = @{}
            
            switch ($path) {
                "/status" {
                    $result = @{
                        message = $script:Status.Message
                        progress = $script:Status.Progress
                        subProgress = $script:Status.SubProgress
                        log = $script:Status.Log
                        installing = $script:Installing
                        phase = $script:Status.Phase
                        server = @{ online = $serverStatus.Online; msg = $serverStatus.Message; ip = $script:Config.ServerIP; port = $script:Config.ServerPort }
                        system = @{
                            java = @{ ok = $script:SystemCheck.Java.OK; msg = $script:SystemCheck.Java.Message }
                            minecraft = @{ ok = $script:SystemCheck.Minecraft.OK; msg = $script:SystemCheck.Minecraft.Message }
                            forge = @{ ok = $script:SystemCheck.Forge.OK; msg = $script:SystemCheck.Forge.Message }
                            ram = @{ ok = $script:SystemCheck.RAM.OK; msg = $script:SystemCheck.RAM.Message }
                            disk = @{ ok = $script:SystemCheck.Disk.OK; msg = $script:SystemCheck.Disk.Message }
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
                "/backup" { New-Backup; $result = @{ ok = $true } }
                "/uninstall" { Remove-Modpack; $result = @{ ok = $true } }
                "/reset" {
                    $script:Status.Message = "Listo para instalar"
                    $script:Status.Progress = 0
                    $script:Status.SubProgress = "Selecciona una version y haz clic en Instalar"
                    $script:Status.Phase = "ready"
                    $result = @{ ok = $true }
                }
                "/launch" { $success = Open-MinecraftLauncher; $result = @{ ok = $success } }
                default { $result = @{ error = "404" } }
            }
            
            $json = $result | ConvertTo-Json -Compress -Depth 5
            $buf = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)
            $response.Close()
        } catch {}
    }
}

Start-Installer
