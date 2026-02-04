# ==============================================================================================
# PaisaLand Installer v4.0.0 - PROFESSIONAL EDITION
# Main Entry Point
# ==============================================================================================

# --- Cargar Librerías ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# --- Obtener Ruta del Script ---
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptPath) { $ScriptPath = Get-Location }

# --- Cargar Módulos ---
. "$ScriptPath\src\config.ps1"
. "$ScriptPath\src\functions.ps1"

# --- Cargar XAML ---
$xamlPath = "$ScriptPath\src\ui.xaml"
[xml]$XAML = Get-Content $xamlPath

# Reemplazar referencia de styles.xaml con contenido inline para compatibilidad
$stylesPath = "$ScriptPath\src\styles.xaml"
[xml]$StylesXAML = Get-Content $stylesPath

# Crear ventana desde XAML (necesitamos merge manual de diccionarios)
$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Cargar estilos
$StyleReader = New-Object System.Xml.XmlNodeReader $StylesXAML
$StyleDict = [Windows.Markup.XamlReader]::Load($StyleReader)
$Window.Resources.MergedDictionaries.Add($StyleDict)

# --- Mapear Controles ---
$controls = @(
    "DragZone", "BtnMinimize", "BtnClose",
    "ServerIndicator", "ServerStatus", "VersionBadge", "UpdateBadge",
    "RadioLow", "RadioHigh",
    "StatusText", "ProgressBar", "LogScroller", "LogText",
    "BtnBackup", "BtnUninstall", "BtnInstall"
)

$UI = @{}
foreach ($name in $controls) {
    $ctrl = $Window.FindName($name)
    if ($ctrl) { $UI[$name] = $ctrl }
}

# --- Funciones de UI ---
function Write-Log {
    param([string]$Message)
    $UI.LogText.Text += "`n> $Message"
    $UI.LogScroller.ScrollToEnd()
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-Status {
    param([string]$Message)
    $UI.StatusText.Text = $Message
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-Progress {
    param([int]$Value)
    $UI.ProgressBar.Value = $Value
    [System.Windows.Forms.Application]::DoEvents()
}

# --- Inicialización ---
function Initialize-Installer {
    # Verificar servidor
    Write-Log "Verificando estado del servidor..."
    $serverStatus = Get-ServerStatus
    if ($serverStatus.Online) {
        $UI.ServerIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen
        $UI.ServerStatus.Text = "Servidor: $($serverStatus.Message)"
        $UI.ServerStatus.Foreground = [System.Windows.Media.Brushes]::LimeGreen
    } else {
        $UI.ServerIndicator.Fill = [System.Windows.Media.Brushes]::Red
        $UI.ServerStatus.Text = "Servidor: $($serverStatus.Message)"
        $UI.ServerStatus.Foreground = [System.Windows.Media.Brushes]::Gray
    }
    
    # Verificar actualizaciones
    Write-Log "Buscando actualizaciones..."
    $updateInfo = Test-UpdateAvailable
    $UI.VersionBadge.Text = "v$($script:Config.Version)"
    if ($updateInfo.Available) {
        $UI.UpdateBadge.Visibility = "Visible"
        Write-Log "Nueva versión disponible: $($updateInfo.RemoteVersion)"
    }
    
    # Cargar preferencia guardada
    $lastChoice = Get-UserPreference -Key "GamaSelection" -Default "Low"
    if ($lastChoice -eq "High") {
        $UI.RadioHigh.IsChecked = $true
    }
    
    Write-Log "Instalador listo."
}

# --- Eventos de Ventana ---
$UI.DragZone.Add_MouseLeftButtonDown({ $Window.DragMove() })
$UI.BtnClose.Add_Click({ $Window.Close() })
$UI.BtnMinimize.Add_Click({ $Window.WindowState = "Minimized" })

# --- Evento: Instalar ---
$UI.BtnInstall.Add_Click({
    $UI.BtnInstall.IsEnabled = $false
    $UI.BtnBackup.IsEnabled = $false
    $UI.BtnUninstall.IsEnabled = $false
    
    try {
        # Determinar URL
        if ($UI.RadioLow.IsChecked) {
            $url = $script:Config.DownloadUrlLow
            Save-UserPreference -Key "GamaSelection" -Value "Low"
            Write-Log "Modo seleccionado: GAMA BAJA"
        } else {
            $url = $script:Config.DownloadUrlHigh
            Save-UserPreference -Key "GamaSelection" -Value "High"
            Write-Log "Modo seleccionado: GAMA ALTA"
        }
        
        # Verificar Minecraft
        Update-Status "Verificando instalación de Minecraft..."
        if (-not (Test-MinecraftInstalled)) {
            [System.Windows.MessageBox]::Show("No se encontró la carpeta .minecraft. Ejecuta Minecraft al menos una vez.", "Error", "OK", "Error")
            return
        }
        Write-Log "Carpeta .minecraft encontrada."
        Update-Progress 10
        
        # Verificar espacio
        Update-Status "Verificando espacio en disco..."
        if (-not (Test-DiskSpace -RequiredMB $script:Config.MinDiskSpaceMB)) {
            [System.Windows.MessageBox]::Show("No hay suficiente espacio en disco ($($script:Config.MinDiskSpaceMB)MB requeridos).", "Error", "OK", "Error")
            return
        }
        Write-Log "Espacio en disco suficiente."
        Update-Progress 20
        
        # Preparar descarga
        $zipPath = "$($script:Config.TempDir)\PaisaLand_Mods.zip"
        if (-not (Test-Path $script:Config.TempDir)) {
            New-Item -ItemType Directory -Path $script:Config.TempDir -Force | Out-Null
        }
        
        # Descargar (sync por simplicidad, pero con actualizaciones)
        Update-Status "Descargando modpack..."
        Write-Log "Iniciando descarga desde la nube..."
        $UI.ProgressBar.IsIndeterminate = $true
        [System.Windows.Forms.Application]::DoEvents()
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $zipPath)
        
        $UI.ProgressBar.IsIndeterminate = $false
        Update-Progress 50
        Write-Log "Descarga completada."
        
        # Instalar
        Update-Status "Instalando archivos..."
        Write-Log "Extrayendo y copiando archivos..."
        Install-Modpack -ZipPath $zipPath
        Update-Progress 90
        
        # Limpiar
        Clear-TempFiles
        Update-Progress 100
        
        Update-Status "¡INSTALACIÓN COMPLETADA!"
        $UI.StatusText.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        Write-Log "¡Todo listo! Abre el launcher y disfruta."
        
        [System.Windows.MessageBox]::Show("¡Modpack instalado exitosamente! Ya puedes jugar.", "PaisaLand", "OK", "Information")
        
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", "OK", "Error")
    } finally {
        $UI.BtnInstall.IsEnabled = $true
        $UI.BtnBackup.IsEnabled = $true
        $UI.BtnUninstall.IsEnabled = $true
        $UI.ProgressBar.IsIndeterminate = $false
    }
})

# --- Evento: Backup ---
$UI.BtnBackup.Add_Click({
    try {
        Update-Status "Creando backup..."
        Write-Log "Respaldando archivos actuales..."
        $backupPath = New-Backup
        Write-Log "Backup guardado en: $backupPath"
        Update-Status "Backup completado"
        [System.Windows.MessageBox]::Show("Backup creado en tu Escritorio.", "Backup", "OK", "Information")
    } catch {
        Write-Log "Error en backup: $($_.Exception.Message)"
    }
})

# --- Evento: Desinstalar ---
$UI.BtnUninstall.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "¿Estás seguro de que deseas eliminar todos los mods de PaisaLand?`n`nEsto borrará: mods, config, shaders, resourcepacks, emotes.",
        "Confirmar Desinstalación",
        "YesNo",
        "Warning"
    )
    
    if ($result -eq "Yes") {
        try {
            Update-Status "Desinstalando mods..."
            Write-Log "Eliminando archivos de PaisaLand..."
            Remove-Modpack
            Write-Log "Desinstalación completada."
            Update-Status "Mods eliminados"
            [System.Windows.MessageBox]::Show("Los mods de PaisaLand han sido eliminados.", "Desinstalación", "OK", "Information")
        } catch {
            Write-Log "Error: $($_.Exception.Message)"
        }
    }
})

# --- Iniciar Aplicación ---
$Window.Add_Loaded({ Initialize-Installer })
[void]$Window.ShowDialog()
