# ==============================================================================================
# PaisaLand Installer - Core Functions Module
# v4.0.0
# ==============================================================================================

# --- VERIFICACIONES ---

function Test-MinecraftInstalled {
    return (Test-Path $script:Config.MinecraftPath)
}

function Test-DiskSpace {
    param([int]$RequiredMB = 500)
    $drive = (Get-Item $env:APPDATA).PSDrive.Name
    $freeSpace = (Get-PSDrive $drive).Free / 1MB
    return $freeSpace -ge $RequiredMB
}

function Get-ServerStatus {
    param(
        [string]$IP = $script:Config.ServerIP,
        [int]$Port = $script:Config.ServerPort
    )
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($IP, $Port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne(2000, $false)
        if ($wait -and $tcpClient.Connected) {
            $tcpClient.Close()
            return @{ Online = $true; Message = "En Línea" }
        } else {
            return @{ Online = $false; Message = "Fuera de Línea" }
        }
    } catch {
        return @{ Online = $false; Message = "Error de Conexión" }
    }
}

function Get-RemoteVersion {
    try {
        $webClient = New-Object System.Net.WebClient
        $remoteVersion = $webClient.DownloadString($script:Config.VersionUrl).Trim()
        return $remoteVersion
    } catch {
        return $null
    }
}

function Test-UpdateAvailable {
    $remote = Get-RemoteVersion
    if ($remote -and $remote -ne $script:Config.Version) {
        return @{ Available = $true; RemoteVersion = $remote }
    }
    return @{ Available = $false; RemoteVersion = $script:Config.Version }
}

# --- PREFERENCIAS DE USUARIO ---

function Save-UserPreference {
    param([string]$Key, $Value)
    $prefsDir = Split-Path $script:Config.PrefsFile -Parent
    if (-not (Test-Path $prefsDir)) { New-Item -ItemType Directory -Path $prefsDir -Force | Out-Null }
    
    $prefs = @{}
    if (Test-Path $script:Config.PrefsFile) {
        $prefs = Get-Content $script:Config.PrefsFile | ConvertFrom-Json -AsHashtable
    }
    $prefs[$Key] = $Value
    $prefs | ConvertTo-Json | Set-Content $script:Config.PrefsFile
}

function Get-UserPreference {
    param([string]$Key, $Default = $null)
    if (Test-Path $script:Config.PrefsFile) {
        $prefs = Get-Content $script:Config.PrefsFile | ConvertFrom-Json -AsHashtable
        if ($prefs.ContainsKey($Key)) { return $prefs[$Key] }
    }
    return $Default
}

# --- DESCARGA CON PROGRESO ---

function Start-ModDownload {
    param(
        [string]$Url,
        [string]$Destination,
        [scriptblock]$OnProgress,
        [scriptblock]$OnComplete
    )
    
    $webClient = New-Object System.Net.WebClient
    
    # Evento de progreso
    $webClient.add_DownloadProgressChanged({
        param($sender, $e)
        if ($OnProgress) { & $OnProgress $e.ProgressPercentage }
    })
    
    # Evento de completado
    $webClient.add_DownloadFileCompleted({
        param($sender, $e)
        if ($e.Error) {
            throw $e.Error
        }
        if ($OnComplete) { & $OnComplete }
    })
    
    # Iniciar descarga async
    $webClient.DownloadFileAsync([Uri]$Url, $Destination)
    return $webClient
}

# --- INSTALACIÓN ---

function Install-Modpack {
    param([string]$ZipPath)
    
    $tempExtract = "$($script:Config.TempDir)\extracted"
    
    # Limpiar mods viejos
    $modsPath = "$($script:Config.MinecraftPath)\mods"
    if (Test-Path $modsPath) {
        Remove-Item "$modsPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Extraer
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $tempExtract -Force
    
    # Detectar estructura (carpeta raíz o contenido directo)
    $items = Get-ChildItem -Path $tempExtract
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        $sourceDir = $items[0].FullName
    } else {
        $sourceDir = $tempExtract
    }
    
    # Copiar
    Copy-Item -Path "$sourceDir\*" -Destination $script:Config.MinecraftPath -Recurse -Force
    
    return $true
}

# --- BACKUP ---

function New-Backup {
    $backupDir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    foreach ($item in $script:Config.ManagedFolders) {
        $itemPath = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $itemPath) {
            Copy-Item -Path $itemPath -Destination $backupDir -Recurse
        }
    }
    
    return $backupDir
}

# --- DESINSTALACIÓN ---

function Remove-Modpack {
    foreach ($item in $script:Config.ManagedFolders) {
        $itemPath = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $itemPath) {
            Remove-Item -Path $itemPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    return $true
}

# --- LIMPIEZA ---

function Clear-TempFiles {
    if (Test-Path $script:Config.TempDir) {
        Remove-Item $script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
