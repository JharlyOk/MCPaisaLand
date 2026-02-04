# ==============================================================================================
# PaisaLand Installer v7.0.0 - PREMIUM EDITION
# ==============================================================================================

$script:Config = @{
    Version = "7.0.0"
    Port = 8199
    DownloadUrlLow = "https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=1"
    DownloadUrlHigh = "https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=1"
    ServerIP = "play.paisaland.com"
    ServerPort = 25565
    MinecraftPath = "$env:APPDATA\.minecraft"
    TempDir = "$env:TEMP\PaisaLandInstaller"
    ManagedFolders = @("mods", "config", "shaderpacks", "resourcepacks", "emotes", "options.txt", "servers.dat")
}

$script:Status = @{ Message = "Listo para instalar"; Progress = 0; Log = @("Sistema iniciado"); Complete = $false }
$script:Installing = $false

function Test-MinecraftInstalled { return (Test-Path $script:Config.MinecraftPath) }
function Test-DiskSpace { $drive = (Get-Item $env:APPDATA).PSDrive.Name; return ((Get-PSDrive $drive).Free / 1MB) -ge 500 }

function Get-ServerStatus {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ar = $tcp.BeginConnect($script:Config.ServerIP, $script:Config.ServerPort, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne(2000, $false) -and $tcp.Connected) { $tcp.Close(); return @{ Online = $true; Message = "Online" } }
        return @{ Online = $false; Message = "Offline" }
    } catch { return @{ Online = $false; Message = "Error" } }
}

function Add-Log { param($msg); $script:Status.Log += $msg }

function Install-Modpack {
    param([bool]$HighSpec = $false)
    $script:Installing = $true
    $script:Status.Complete = $false
    $script:Status.Message = "Verificando requisitos..."; $script:Status.Progress = 5
    Add-Log "Iniciando instalacion - Modo: $(if($HighSpec){'GAMA ALTA'}else{'GAMA BAJA'})"
    
    if (-not (Test-MinecraftInstalled)) { Add-Log "ERROR: Minecraft no encontrado"; $script:Status.Message = "Error: Minecraft no instalado"; $script:Installing = $false; return $false }
    Add-Log "Minecraft detectado correctamente"; $script:Status.Progress = 10
    
    if (-not (Test-DiskSpace)) { Add-Log "ERROR: Espacio insuficiente"; $script:Status.Message = "Error: Sin espacio en disco"; $script:Installing = $false; return $false }
    Add-Log "Espacio en disco verificado"; $script:Status.Progress = 15
    
    $url = if ($HighSpec) { $script:Config.DownloadUrlHigh } else { $script:Config.DownloadUrlLow }
    $zip = "$($script:Config.TempDir)\modpack.zip"
    
    if (-not (Test-Path $script:Config.TempDir)) { New-Item -ItemType Directory -Path $script:Config.TempDir -Force | Out-Null }
    
    $script:Status.Message = "Descargando modpack..."; $script:Status.Progress = 20
    Add-Log "Conectando al servidor de descarga..."
    try { 
        (New-Object System.Net.WebClient).DownloadFile($url, $zip)
        Add-Log "Descarga completada exitosamente"
    } catch { 
        Add-Log "ERROR: Fallo en descarga - $($_.Exception.Message)"
        $script:Status.Message = "Error en descarga"
        $script:Installing = $false
        return $false 
    }
    $script:Status.Progress = 60
    
    $script:Status.Message = "Instalando archivos..."
    Add-Log "Extrayendo contenido del modpack..."
    
    $modsPath = "$($script:Config.MinecraftPath)\mods"
    if (Test-Path $modsPath) { Remove-Item "$modsPath\*" -Recurse -Force -ErrorAction SilentlyContinue }
    
    $extract = "$($script:Config.TempDir)\extracted"
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $items = Get-ChildItem -Path $extract
    $src = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $extract }
    Copy-Item -Path "$src\*" -Destination $script:Config.MinecraftPath -Recurse -Force
    Add-Log "Archivos instalados correctamente"
    $script:Status.Progress = 90
    
    if (Test-Path $script:Config.TempDir) { Remove-Item $script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue }
    Add-Log "Limpieza de archivos temporales completada"
    
    $script:Status.Message = "Instalacion completada!"; $script:Status.Progress = 100; $script:Status.Complete = $true
    Add-Log "=== INSTALACION EXITOSA ==="
    $script:Installing = $false
    return $true
}

function New-Backup {
    $dir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    foreach ($item in $script:Config.ManagedFolders) { 
        $p = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $p) { Copy-Item -Path $p -Destination $dir -Recurse } 
    }
    Add-Log "Backup creado en: $dir"
    return $dir
}

function Remove-Modpack {
    foreach ($item in $script:Config.ManagedFolders) { 
        $p = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue } 
    }
    Add-Log "Todos los mods han sido eliminados"
    $script:Status.Message = "Mods eliminados"
}

$HTML = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PaisaLand Installer</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --bg-gradient: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            --card-bg: rgba(255,255,255,0.03);
            --card-border: rgba(255,255,255,0.08);
            --card-hover: rgba(255,255,255,0.06);
            --text-primary: #ffffff;
            --text-secondary: rgba(255,255,255,0.6);
            --text-muted: rgba(255,255,255,0.4);
            --accent: #10b981;
            --accent-glow: rgba(16, 185, 129, 0.3);
            --danger: #ef4444;
        }
        body.light {
            --bg-gradient: linear-gradient(135deg, #f0f4f8 0%, #e2e8f0 50%, #cbd5e1 100%);
            --card-bg: rgba(255,255,255,0.8);
            --card-border: rgba(0,0,0,0.08);
            --card-hover: rgba(0,0,0,0.04);
            --text-primary: #1e293b;
            --text-secondary: rgba(30,41,59,0.7);
            --text-muted: rgba(30,41,59,0.5);
        }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: var(--bg-gradient);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        body::before {
            content: '';
            position: fixed;
            top: -50%; left: -50%;
            width: 200%; height: 200%;
            background: radial-gradient(circle at 20% 80%, rgba(16, 185, 129, 0.08) 0%, transparent 50%),
                        radial-gradient(circle at 80% 20%, rgba(59, 130, 246, 0.08) 0%, transparent 50%);
            animation: bgMove 20s ease-in-out infinite;
            z-index: -1;
        }
        @keyframes bgMove {
            0%, 100% { transform: translate(0, 0); }
            50% { transform: translate(-1%, 2%); }
        }
        .installer {
            width: 100%; max-width: 480px;
            background: var(--card-bg);
            backdrop-filter: blur(20px);
            border: 1px solid var(--card-border);
            border-radius: 24px;
            overflow: hidden;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            animation: fadeIn 0.5s ease;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .header {
            padding: 24px 28px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--card-border);
        }
        .brand { display: flex; align-items: center; gap: 12px; }
        .brand-icon {
            width: 42px; height: 42px;
            background: linear-gradient(135deg, var(--accent) 0%, #059669 100%);
            border-radius: 12px;
            display: flex; align-items: center; justify-content: center;
            font-size: 20px; font-weight: 800; color: white;
            box-shadow: 0 4px 12px var(--accent-glow);
        }
        .brand-text { font-size: 20px; font-weight: 700; color: var(--text-primary); }
        .brand-text span { color: var(--accent); }
        .icon-btn {
            width: 36px; height: 36px;
            border: 1px solid var(--card-border);
            background: var(--card-bg);
            color: var(--text-secondary);
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex; align-items: center; justify-content: center;
        }
        .icon-btn:hover { background: var(--card-hover); color: var(--text-primary); }
        .content { padding: 24px 28px; }
        .server-status {
            display: flex; align-items: center; gap: 10px;
            padding: 14px 18px;
            background: var(--card-bg);
            border: 1px solid var(--card-border);
            border-radius: 14px;
            margin-bottom: 20px;
        }
        .status-indicator {
            width: 10px; height: 10px;
            border-radius: 50%;
            background: var(--danger);
            box-shadow: 0 0 10px var(--danger);
            animation: pulse 2s infinite;
        }
        .status-indicator.online { background: var(--accent); box-shadow: 0 0 10px var(--accent); }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
        .status-text { font-size: 13px; color: var(--text-secondary); }
        .status-text strong { color: var(--text-primary); }
        .mode-selector {
            background: var(--card-bg);
            border: 1px solid var(--card-border);
            border-radius: 16px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .mode-label {
            font-size: 11px; font-weight: 600;
            text-transform: uppercase; letter-spacing: 1px;
            color: var(--text-muted);
            margin-bottom: 14px;
        }
        .mode-options { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .mode-option {
            padding: 16px;
            background: transparent;
            border: 2px solid var(--card-border);
            border-radius: 12px;
            cursor: pointer;
            transition: all 0.3s ease;
            text-align: left;
        }
        .mode-option:hover { border-color: var(--text-muted); background: var(--card-hover); }
        .mode-option.active { border-color: var(--accent); background: rgba(16, 185, 129, 0.1); }
        .mode-option h4 { font-size: 14px; font-weight: 600; color: var(--text-primary); margin-bottom: 4px; }
        .mode-option p { font-size: 11px; color: var(--text-muted); }
        .mode-option.active h4 { color: var(--accent); }
        .progress-section {
            background: var(--card-bg);
            border: 1px solid var(--card-border);
            border-radius: 16px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .progress-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
        .progress-status { font-size: 14px; font-weight: 600; color: var(--text-primary); }
        .progress-percent { font-size: 13px; font-weight: 700; color: var(--accent); }
        .progress-bar { height: 6px; background: rgba(255,255,255,0.1); border-radius: 3px; overflow: hidden; }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, var(--accent) 0%, #34d399 100%);
            border-radius: 3px;
            width: 0%;
            transition: width 0.5s ease;
        }
        .install-btn {
            width: 100%;
            padding: 18px 24px;
            background: linear-gradient(135deg, var(--accent) 0%, #059669 100%);
            border: none;
            border-radius: 14px;
            color: white;
            font-size: 15px; font-weight: 700;
            cursor: pointer;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 1px;
            box-shadow: 0 4px 20px var(--accent-glow);
            margin-bottom: 20px;
        }
        .install-btn:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 8px 30px var(--accent-glow); }
        .install-btn:disabled { background: rgba(255,255,255,0.1); color: var(--text-muted); cursor: not-allowed; box-shadow: none; }
        .log-section {
            background: #0a0a0f;
            border: 1px solid var(--card-border);
            border-radius: 12px;
            padding: 14px;
            height: 100px;
            overflow-y: auto;
            margin-bottom: 20px;
            font-family: monospace;
        }
        body.light .log-section { background: #f8fafc; }
        .log-line { font-size: 11px; color: var(--accent); line-height: 1.6; }
        body.light .log-line { color: #059669; }
        .log-line::before { content: '>'; margin-right: 8px; opacity: 0.5; }
        .secondary-actions { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .secondary-btn {
            padding: 14px;
            background: transparent;
            border: 1px solid var(--card-border);
            border-radius: 12px;
            color: var(--text-secondary);
            font-size: 13px; font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        .secondary-btn:hover { background: var(--card-hover); border-color: var(--text-muted); color: var(--text-primary); }
        .secondary-btn.danger { border-color: rgba(239, 68, 68, 0.3); color: var(--danger); }
        .secondary-btn.danger:hover { background: rgba(239, 68, 68, 0.1); border-color: var(--danger); }
        .footer {
            padding: 16px 28px;
            border-top: 1px solid var(--card-border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .footer-text { font-size: 12px; color: var(--text-muted); }
        .footer-text a { color: var(--accent); text-decoration: none; }
        .version { font-size: 11px; color: var(--text-muted); font-weight: 500; padding: 4px 10px; background: var(--card-bg); border-radius: 20px; border: 1px solid var(--card-border); }
        .complete .progress-status { color: var(--accent) !important; }
    </style>
</head>
<body>
    <div class="installer">
        <div class="header">
            <div class="brand">
                <div class="brand-icon">P</div>
                <div class="brand-text">PAISA<span>LAND</span></div>
            </div>
            <button class="icon-btn" id="themeBtn" title="Cambiar tema">M</button>
        </div>
        <div class="content">
            <div class="server-status">
                <div class="status-indicator" id="serverDot"></div>
                <span class="status-text">Servidor: <strong id="serverText">Verificando...</strong></span>
            </div>
            <div class="mode-selector">
                <div class="mode-label">Selecciona tu version</div>
                <div class="mode-options">
                    <div class="mode-option active" id="modeLow" onclick="selectMode(false)">
                        <h4>Gama Baja</h4>
                        <p>Optimizado para FPS</p>
                    </div>
                    <div class="mode-option" id="modeHigh" onclick="selectMode(true)">
                        <h4>Gama Alta</h4>
                        <p>Shaders + Texturas HD</p>
                    </div>
                </div>
            </div>
            <div class="progress-section" id="progressSection">
                <div class="progress-header">
                    <span class="progress-status" id="statusText">Listo para instalar</span>
                    <span class="progress-percent" id="progressPercent">0%</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" id="progressFill"></div>
                </div>
            </div>
            <button class="install-btn" id="installBtn" onclick="install()">Instalar Modpack</button>
            <div class="log-section" id="logBox"></div>
            <div class="secondary-actions">
                <button class="secondary-btn" onclick="backup()">Backup</button>
                <button class="secondary-btn danger" onclick="uninstall()">Eliminar</button>
            </div>
        </div>
        <div class="footer">
            <span class="footer-text">Creado por <a href="#">JharlyOk</a></span>
            <span class="version">v7.0.0</span>
        </div>
    </div>
    <script>
        var API = 'http://localhost:{{PORT}}';
        var isHighSpec = false;
        var isDark = true;

        document.getElementById('themeBtn').addEventListener('click', function() {
            isDark = !isDark;
            document.body.classList.toggle('light', !isDark);
            this.textContent = isDark ? 'M' : 'S';
        });

        function selectMode(high) {
            isHighSpec = high;
            document.getElementById('modeLow').classList.toggle('active', !high);
            document.getElementById('modeHigh').classList.toggle('active', high);
        }

        function updateStatus() {
            fetch(API + '/status')
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    document.getElementById('statusText').textContent = data.message;
                    document.getElementById('progressPercent').textContent = data.progress + '%';
                    document.getElementById('progressFill').style.width = data.progress + '%';
                    if (data.complete) {
                        document.getElementById('progressSection').classList.add('complete');
                    } else {
                        document.getElementById('progressSection').classList.remove('complete');
                    }
                    if (data.server) {
                        document.getElementById('serverDot').classList.toggle('online', data.server.online);
                        document.getElementById('serverText').textContent = data.server.msg;
                    }
                    var logBox = document.getElementById('logBox');
                    logBox.innerHTML = data.log.map(function(l) { return '<div class="log-line">' + l + '</div>'; }).join('');
                    logBox.scrollTop = logBox.scrollHeight;
                })
                .catch(function(e) { console.error(e); });
        }

        function install() {
            document.getElementById('installBtn').disabled = true;
            fetch(API + '/install?high=' + isHighSpec, { method: 'POST' })
                .catch(function(e) {});
            setTimeout(function() { document.getElementById('installBtn').disabled = false; }, 5000);
        }

        function backup() {
            fetch(API + '/backup', { method: 'POST' }).catch(function(e) {});
        }

        function uninstall() {
            if (confirm('Eliminar todos los mods de PaisaLand?\n\nEsto borrara: mods, config, shaders, resourcepacks')) {
                fetch(API + '/uninstall', { method: 'POST' }).catch(function(e) {});
            }
        }

        setInterval(updateStatus, 800);
        updateStatus();
    </script>
</body>
</html>
"@

function Start-Installer {
    $port = $script:Config.Port
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    
    try { $listener.Start() } catch {
        Write-Host ""
        Write-Host "  [ERROR] Puerto $port en uso. Cierra otras instancias." -ForegroundColor Red
        Write-Host ""
        return
    }
    
    Write-Host ""
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host "       PaisaLand Installer v7.0.0      " -ForegroundColor Cyan
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [OK] Servidor iniciado en localhost:$port" -ForegroundColor Green
    Write-Host "  [OK] Abriendo navegador..." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Presiona Ctrl+C para cerrar el instalador" -ForegroundColor Yellow
    Write-Host ""
    
    $serverStatus = Get-ServerStatus
    
    $htmlPath = "$env:TEMP\paisaland_v7.html"
    $HTML.Replace("{{PORT}}", $port) | Out-File -FilePath $htmlPath -Encoding UTF8
    Start-Process $htmlPath
    
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
                        log = $script:Status.Log
                        installing = $script:Installing
                        complete = $script:Status.Complete
                        server = @{ online = $serverStatus.Online; msg = $serverStatus.Message }
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
                    $script:Status.Message = "Creando backup..."
                    $p = New-Backup
                    $script:Status.Message = "Backup completado"
                    $result = @{ ok = $true; path = $p }
                }
                "/uninstall" {
                    Remove-Modpack
                    $result = @{ ok = $true }
                }
                default { $result = @{ error = "404" } }
            }
            
            $json = $result | ConvertTo-Json -Compress
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            
        } catch { if ($listener.IsListening) { } }
    }
}

Start-Installer
