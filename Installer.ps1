# ==============================================================================================
# PaisaLand Installer v6.0.0 - HTML + Browser UI
# Compatible con: irm https://... | iex
# ==============================================================================================

$script:Config = @{
    Version = "6.0.0"
    Port = 8199
    DownloadUrlLow = "https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=1"
    DownloadUrlHigh = "https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=1"
    ServerIP = "play.paisaland.com"
    ServerPort = 25565
    MinecraftPath = "$env:APPDATA\.minecraft"
    TempDir = "$env:TEMP\PaisaLandInstaller"
    ManagedFolders = @("mods", "config", "shaderpacks", "resourcepacks", "emotes", "options.txt", "servers.dat")
}

$script:Status = @{ Message = "Listo"; Progress = 0; Log = @("Instalador iniciado") }
$script:Installing = $false

# ==================== FUNCTIONS ====================
function Test-MinecraftInstalled { return (Test-Path $script:Config.MinecraftPath) }
function Test-DiskSpace { $drive = (Get-Item $env:APPDATA).PSDrive.Name; return ((Get-PSDrive $drive).Free / 1MB) -ge 500 }

function Get-ServerStatus {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ar = $tcp.BeginConnect($script:Config.ServerIP, $script:Config.ServerPort, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne(2000, $false) -and $tcp.Connected) { $tcp.Close(); return @{ Online = $true; Message = "En Línea" } }
        return @{ Online = $false; Message = "Fuera de Línea" }
    } catch { return @{ Online = $false; Message = "Error" } }
}

function Add-Log { param($msg); $script:Status.Log += $msg }

function Install-Modpack {
    param([bool]$HighSpec = $false)
    
    $script:Installing = $true
    $script:Status.Message = "Verificando..."; $script:Status.Progress = 5
    Add-Log "Modo: $(if($HighSpec){'GAMA ALTA'}else{'GAMA BAJA'})"
    
    if (-not (Test-MinecraftInstalled)) { Add-Log "ERROR: .minecraft no encontrado"; $script:Installing = $false; return $false }
    Add-Log "Minecraft OK"; $script:Status.Progress = 10
    
    if (-not (Test-DiskSpace)) { Add-Log "ERROR: Sin espacio"; $script:Installing = $false; return $false }
    Add-Log "Espacio OK"; $script:Status.Progress = 20
    
    $url = if ($HighSpec) { $script:Config.DownloadUrlHigh } else { $script:Config.DownloadUrlLow }
    $zip = "$($script:Config.TempDir)\mods.zip"
    
    if (-not (Test-Path $script:Config.TempDir)) { New-Item -ItemType Directory -Path $script:Config.TempDir -Force | Out-Null }
    
    $script:Status.Message = "Descargando..."; Add-Log "Descargando..."
    try { (New-Object System.Net.WebClient).DownloadFile($url, $zip) } catch { Add-Log "ERROR: $($_.Exception.Message)"; $script:Installing = $false; return $false }
    Add-Log "Descarga completa"; $script:Status.Progress = 50
    
    $script:Status.Message = "Instalando..."
    $modsPath = "$($script:Config.MinecraftPath)\mods"
    if (Test-Path $modsPath) { Remove-Item "$modsPath\*" -Recurse -Force -ErrorAction SilentlyContinue }
    
    $extract = "$($script:Config.TempDir)\ex"
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $items = Get-ChildItem -Path $extract
    $src = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $extract }
    Copy-Item -Path "$src\*" -Destination $script:Config.MinecraftPath -Recurse -Force
    Add-Log "Archivos copiados"; $script:Status.Progress = 90
    
    if (Test-Path $script:Config.TempDir) { Remove-Item $script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue }
    
    $script:Status.Message = "¡COMPLETADO!"; $script:Status.Progress = 100
    Add-Log "¡Instalación exitosa!"
    $script:Installing = $false
    return $true
}

function New-Backup {
    $dir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    foreach ($item in $script:Config.ManagedFolders) { $p = "$($script:Config.MinecraftPath)\$item"; if (Test-Path $p) { Copy-Item -Path $p -Destination $dir -Recurse } }
    Add-Log "Backup creado: $dir"
    return $dir
}

function Remove-Modpack {
    foreach ($item in $script:Config.ManagedFolders) { $p = "$($script:Config.MinecraftPath)\$item"; if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue } }
    Add-Log "Mods eliminados"
}

# ==================== HTML ====================
$HTML = @'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PaisaLand Installer</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #1a1a1d;
            --card: #25252a;
            --text: #ffffff;
            --subtext: #8b8b8b;
            --border: #3a3a40;
            --accent: #4ade80;
            --accent-hover: #22c55e;
            --danger: #ef4444;
        }
        .light {
            --bg: #f5f5f7;
            --card: #ffffff;
            --text: #1a1a1d;
            --subtext: #6b6b6b;
            --border: #e0e0e0;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
            transition: all 0.3s ease;
        }
        .container {
            width: 100%;
            max-width: 420px;
            background: var(--card);
            border-radius: 16px;
            box-shadow: 0 25px 50px -12px rgba(0,0,0,0.4);
            overflow: hidden;
            border: 1px solid var(--border);
        }
        .header {
            padding: 16px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--border);
        }
        .logo { display: flex; align-items: center; gap: 8px; }
        .logo-icon { font-size: 24px; }
        .logo-text { font-weight: 700; font-size: 16px; }
        .logo-text span { color: var(--accent); }
        .header-actions { display: flex; gap: 8px; }
        .icon-btn {
            width: 32px; height: 32px;
            border: none; background: transparent;
            color: var(--subtext);
            cursor: pointer;
            border-radius: 6px;
            font-size: 16px;
            transition: all 0.2s;
        }
        .icon-btn:hover { background: var(--border); color: var(--text); }
        .content { padding: 20px; }
        .card {
            background: var(--bg);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 16px;
        }
        .toggle-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .toggle-info h3 { font-size: 15px; font-weight: 600; margin-bottom: 4px; }
        .toggle-info p { font-size: 12px; color: var(--subtext); }
        .toggle {
            width: 48px; height: 26px;
            background: #555;
            border-radius: 13px;
            cursor: pointer;
            position: relative;
            transition: all 0.3s;
        }
        .toggle.active { background: var(--accent); }
        .toggle::after {
            content: '';
            position: absolute;
            width: 20px; height: 20px;
            background: white;
            border-radius: 50%;
            top: 3px; left: 3px;
            transition: all 0.3s;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        .toggle.active::after { left: 25px; }
        .status-row {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 12px;
        }
        .status-dot {
            width: 8px; height: 8px;
            border-radius: 50%;
            background: var(--danger);
        }
        .status-dot.online { background: var(--accent); }
        .status-text { font-size: 12px; color: var(--subtext); }
        .progress-text { font-size: 14px; font-weight: 500; margin-bottom: 8px; }
        .progress-bar {
            height: 4px;
            background: var(--border);
            border-radius: 2px;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            background: var(--accent);
            width: 0%;
            transition: width 0.3s;
        }
        .btn-primary {
            width: 100%;
            padding: 14px;
            background: var(--accent);
            color: #000;
            border: none;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            margin-bottom: 16px;
        }
        .btn-primary:hover { background: var(--accent-hover); transform: translateY(-1px); }
        .btn-primary:disabled { background: #555; color: #888; cursor: not-allowed; transform: none; }
        .log-box {
            background: #0d0d0d;
            border-radius: 8px;
            padding: 12px;
            height: 80px;
            overflow-y: auto;
            font-family: 'Consolas', monospace;
            font-size: 11px;
            color: #4ade80;
            margin-bottom: 16px;
        }
        .log-box p { margin: 2px 0; }
        .secondary-actions { display: flex; gap: 10px; }
        .btn-secondary {
            flex: 1;
            padding: 10px;
            background: transparent;
            border: 1px solid var(--border);
            color: var(--subtext);
            border-radius: 8px;
            font-size: 12px;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-secondary:hover { border-color: var(--text); color: var(--text); }
        .btn-danger { border-color: var(--danger); color: var(--danger); }
        .btn-danger:hover { background: var(--danger); color: white; }
        .footer {
            padding: 12px 20px;
            border-top: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            color: var(--subtext);
        }
        @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.5; } }
        .installing .progress-fill { animation: pulse 1s infinite; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">
                <span class="logo-icon">🎮</span>
                <span class="logo-text">PAISA<span>LAND</span></span>
            </div>
            <div class="header-actions">
                <button class="icon-btn" id="themeBtn" title="Cambiar tema">🌙</button>
            </div>
        </div>
        <div class="content">
            <div class="card">
                <div class="toggle-row">
                    <div class="toggle-info">
                        <h3>Gama Alta</h3>
                        <p>Shaders + Texturas HD + Efectos</p>
                    </div>
                    <div class="toggle" id="specToggle"></div>
                </div>
            </div>
            <div class="card">
                <div class="status-row">
                    <div class="status-dot" id="serverDot"></div>
                    <span class="status-text" id="serverText">Servidor: Verificando...</span>
                </div>
                <p class="progress-text" id="statusText">Listo para instalar</p>
                <div class="progress-bar">
                    <div class="progress-fill" id="progressFill"></div>
                </div>
            </div>
            <button class="btn-primary" id="installBtn">⬇️ INSTALAR MODPACK</button>
            <div class="log-box" id="logBox"><p>> Instalador PaisaLand v6.0</p></div>
            <div class="secondary-actions">
                <button class="btn-secondary" id="backupBtn">📁 Backup</button>
                <button class="btn-secondary btn-danger" id="uninstallBtn">🗑️ Eliminar</button>
            </div>
        </div>
        <div class="footer">
            <span>by JharlyOk</span>
            <span>v6.0.0</span>
        </div>
    </div>
    <script>
        const API = 'http://localhost:{{PORT}}';
        let isHigh = false, isDark = true;

        // Theme
        document.getElementById('themeBtn').onclick = () => {
            isDark = !isDark;
            document.body.classList.toggle('light', !isDark);
            document.getElementById('themeBtn').textContent = isDark ? '🌙' : '☀️';
        };

        // Toggle
        document.getElementById('specToggle').onclick = (e) => {
            isHigh = !isHigh;
            e.target.classList.toggle('active', isHigh);
        };

        // Status polling
        async function updateStatus() {
            try {
                const res = await fetch(API + '/status');
                const data = await res.json();
                document.getElementById('statusText').textContent = data.message;
                document.getElementById('progressFill').style.width = data.progress + '%';
                if (data.server) {
                    document.getElementById('serverDot').classList.toggle('online', data.server.online);
                    document.getElementById('serverText').textContent = 'Servidor: ' + data.server.msg;
                }
                const logBox = document.getElementById('logBox');
                logBox.innerHTML = data.log.map(l => '<p>> ' + l + '</p>').join('');
                logBox.scrollTop = logBox.scrollHeight;
            } catch(e) {}
        }
        setInterval(updateStatus, 1000);
        updateStatus();

        // Install
        document.getElementById('installBtn').onclick = async () => {
            document.getElementById('installBtn').disabled = true;
            try {
                await fetch(API + '/install?high=' + isHigh, { method: 'POST' });
            } catch(e) {}
            setTimeout(() => document.getElementById('installBtn').disabled = false, 3000);
        };

        // Backup
        document.getElementById('backupBtn').onclick = async () => {
            await fetch(API + '/backup', { method: 'POST' });
        };

        // Uninstall
        document.getElementById('uninstallBtn').onclick = async () => {
            if (confirm('¿Eliminar todos los mods de PaisaLand?')) {
                await fetch(API + '/uninstall', { method: 'POST' });
            }
        };
    </script>
</body>
</html>
'@

# ==================== HTTP SERVER ====================
function Start-Installer {
    $port = $script:Config.Port
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    
    try { $listener.Start() } catch {
        Write-Host "Error: No se pudo iniciar el servidor en puerto $port" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "  =====================================" -ForegroundColor Green
    Write-Host "   PaisaLand Installer v6.0" -ForegroundColor White
    Write-Host "  =====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Servidor iniciado en: http://localhost:$port" -ForegroundColor Cyan
    Write-Host "  Abriendo navegador..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [Presiona Ctrl+C para cerrar]" -ForegroundColor Yellow
    Write-Host ""
    
    # Check server status
    $serverStatus = Get-ServerStatus
    
    # Open browser with HTML
    $htmlPath = "$env:TEMP\paisaland_installer.html"
    $HTML.Replace("{{PORT}}", $port) | Out-File -FilePath $htmlPath -Encoding UTF8
    Start-Process $htmlPath
    
    # Main loop
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
                        server = @{ online = $serverStatus.Online; msg = $serverStatus.Message }
                    }
                }
                "/install" {
                    if (-not $script:Installing) {
                        $high = $request.QueryString["high"] -eq "true"
                        Start-Job -ScriptBlock {
                            param($cfg, $high)
                            # Note: In actual use, this runs in main thread due to variable scope
                        } -ArgumentList $script:Config, $high | Out-Null
                        Install-Modpack -HighSpec $high
                    }
                    $result = @{ ok = $true }
                }
                "/backup" {
                    $path = New-Backup
                    $result = @{ ok = $true; path = $path }
                }
                "/uninstall" {
                    Remove-Modpack
                    $script:Status.Message = "Mods eliminados"
                    $result = @{ ok = $true }
                }
                "/shutdown" {
                    $result = @{ ok = $true }
                    $listener.Stop()
                }
                default {
                    $result = @{ error = "Not found" }
                }
            }
            
            $json = $result | ConvertTo-Json -Compress
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            
        } catch {
            if ($listener.IsListening) {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# ==================== START ====================
Start-Installer
