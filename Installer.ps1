# ==============================================================================================
# EpicScript - Instalador Automático de Mods para PaisaLand
# Desarrollado para una experiencia de usuario premium y simplificada.
# ==============================================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURACIÓN ---
# ¡IMPORTANTE! REEMPLAZA ESTOS LINKS POR LOS TUYOS DE DROPBOX/DRIVE
$DownloadUrlLow = "URL_GAMA_BAJA_AQUI" 
$DownloadUrlHigh = "URL_GAMA_ALTA_AQUI"
$InstallerTitle = "PaisaLand - Instalador Oficial de Mods"
$MinecraftPath = "$env:APPDATA\.minecraft"
$TempDir = "$env:TEMP\PaisaLandInstaller"

# --- DISEÑO VISUAL (Colores y Fuentes) ---
$ColorBackground = [System.Drawing.Color]::FromArgb(30, 30, 30)
$ColorPanel = [System.Drawing.Color]::FromArgb(45, 45, 48)
$ColorText = [System.Drawing.Color]::White
$ColorAccent = [System.Drawing.Color]::FromArgb(0, 122, 204) # Azul VSCode style
$ColorButton = [System.Drawing.Color]::FromArgb(60, 60, 60)
$ColorButtonHover = [System.Drawing.Color]::FromArgb(80, 80, 80)
$FontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$FontNormal = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$FontRadio = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$FontSmall = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Regular)

# --- VENTANA PRINCIPAL ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = $InstallerTitle
$Form.Size = New-Object System.Drawing.Size(600, 450)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $ColorBackground
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false
$Form.Icon = [System.Drawing.SystemIcons]::Application # Puedes cambiar esto si tienes un .ico

# --- FUNCIONES AUXILIARES DE GUI ---
function Create-Button($text, $x, $y, $w, $h, $handler) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.FlatStyle = "Flat"
    $btn.ForeColor = $ColorText
    $btn.BackColor = $ColorButton
    $btn.Font = $FontNormal
    $btn.FlatAppearance.BorderSize = 0
    $btn.add_MouseEnter({ $btn.BackColor = $ColorButtonHover })
    $btn.add_MouseLeave({ $btn.BackColor = $ColorButton })
    $btn.add_Click($handler)
    $Form.Controls.Add($btn)
    return $btn
}

function Log-Message($msg) {
    $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $msg`r`n")
    $LogBox.ScrollToCaret()
    $Form.Refresh()
}

# --- HEADER ---
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(600, 80)
$HeaderPanel.BackColor = $ColorPanel
$Form.Controls.Add($HeaderPanel)

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "PaisaLand"
$TitleLabel.Font = $FontTitle
$TitleLabel.ForeColor = $ColorAccent
$TitleLabel.AutoSize = $true
$TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
$HeaderPanel.Controls.Add($TitleLabel)

$SubTitleLabel = New-Object System.Windows.Forms.Label
$SubTitleLabel.Text = "Instalador Automático de Mods, Shaders y Texturas"
$SubTitleLabel.Font = $FontNormal
$SubTitleLabel.ForeColor = [System.Drawing.Color]::LightGray
$SubTitleLabel.AutoSize = $true
$SubTitleLabel.Location = New-Object System.Drawing.Point(22, 45)
$HeaderPanel.Controls.Add($SubTitleLabel)

# --- CONTROLES ---
# Selección de Versión
$VersionPanel = New-Object System.Windows.Forms.GroupBox
$VersionPanel.Text = "Selecciona tu Versión"
$VersionPanel.ForeColor = $ColorText
$VersionPanel.Location = New-Object System.Drawing.Point(20, 95)
$VersionPanel.Size = New-Object System.Drawing.Size(545, 60)
$Form.Controls.Add($VersionPanel)

$RadioLow = New-Object System.Windows.Forms.RadioButton
$RadioLow.Text = "PC Gama Baja (Optimizado)"
$RadioLow.Location = New-Object System.Drawing.Point(20, 25)
$RadioLow.Font = $FontRadio
$RadioLow.ForeColor = [System.Drawing.Color]::LightGreen
$RadioLow.AutoSize = $true
$RadioLow.Checked = $true # Default
$VersionPanel.Controls.Add($RadioLow)

$RadioHigh = New-Object System.Windows.Forms.RadioButton
$RadioHigh.Text = "PC Gama Alta (Shaders + Gráficos)"
$RadioHigh.Location = New-Object System.Drawing.Point(280, 25)
$RadioHigh.Font = $FontRadio
$RadioHigh.ForeColor = [System.Drawing.Color]::Gold
$RadioHigh.AutoSize = $true
$VersionPanel.Controls.Add($RadioHigh)

# Barra de Progreso
$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(20, 170)
$ProgressBar.Size = New-Object System.Drawing.Size(545, 10)
$ProgressBar.Style = "Continuous"
$Form.Controls.Add($ProgressBar)

# Status Label
$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Text = "Listo para instalar..."
$StatusLabel.ForeColor = $ColorText
$StatusLabel.Font = $FontNormal
$StatusLabel.AutoSize = $true
$StatusLabel.Location = New-Object System.Drawing.Point(20, 185)
$Form.Controls.Add($StatusLabel)

# Log Box
$LogBox = New-Object System.Windows.Forms.TextBox
$LogBox.Multiline = $true
$LogBox.ReadOnly = $true
$LogBox.ScrollBars = "Vertical"
$LogBox.Location = New-Object System.Drawing.Point(20, 210)
$LogBox.Size = New-Object System.Drawing.Size(545, 120)
$LogBox.BackColor = $ColorPanel
$LogBox.ForeColor = [System.Drawing.Color]::LightGray
$LogBox.BorderStyle = "None"
$LogBox.Font = $FontSmall
$Form.Controls.Add($LogBox)

# --- LÓGICA DE INSTALACIÓN ---
$ActionInstall = {
    $InstallButton.Enabled = $false
    $BackupButton.Enabled = $false
    
    try {
        # Determinar URL basada en selección
        $SelectedUrl = ""
        if ($RadioLow.Checked) { 
            $SelectedUrl = $DownloadUrlLow 
            Log-Message "Modo seleccionado: GAMA BAJA"
        } else { 
            $SelectedUrl = $DownloadUrlHigh
            Log-Message "Modo seleccionado: GAMA ALTA"
        }

        if ($SelectedUrl -match "URL_.*_AQUI" -or $SelectedUrl -eq "") {
            Log-Message "ERROR: URL de descarga no configurada para la opción seleccionada."
            [System.Windows.Forms.MessageBox]::Show("Falta configurar el link de descarga en el script.", "Error", "OK", "Error")
            return
        }

        # 1. Comprobaciones
        Log-Message "Iniciando proceso de instalación..."
        $StatusLabel.Text = "Buscando carpeta de Minecraft..."
        if (-not (Test-Path $MinecraftPath)) {
            Log-Message "Error: No se encontró la carpeta .minecraft en $MinecraftPath"
            [System.Windows.Forms.MessageBox]::Show("No se encontró la instalación de Minecraft. Ejecuta el juego al menos una vez.", "Error", "OK", "Error")
            return
        }
        Log-Message "Carpeta de Minecraft encontrada."

        # 2. Descarga
        $ZipPath = "$TempDir\PaisaLand_Mods.zip"
        if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir | Out-Null }
        
        $StatusLabel.Text = "Descargando archivos del servidor..."
        Log-Message "Descargando desde: $SelectedUrl"
        
        # WebClient para descarga con progreso (simulado visualmente ya que WebClient async es complejo en PS simple)
        $WebClient = New-Object System.Net.WebClient
        $ProgressBar.Style = "Marquee" # Indeterminado mientras descarga
        $WebClient.DownloadFile($SelectedUrl, $ZipPath)
        $ProgressBar.Style = "Continuous"
        $ProgressBar.Value = 25
        Log-Message "Descarga completada."

        # 3. Backup (Opcional, pero recomendado limpiar carpetas viejas)
        $StatusLabel.Text = "Limpiando versiones anteriores..."
        Log-Message "Eliminando mods antiguos..."
        $ModsPath = "$MinecraftPath\mods"
        if (Test-Path $ModsPath) { Remove-Item "$ModsPath\*" -Recurse -Force -ErrorAction SilentlyContinue }
        
        # 4. Extracción
        $StatusLabel.Text = "Extrayendo archivos..."
        Log-Message "Extrayendo en $TempDir..."
        $ProgressBar.Value = 50
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempDir -Force
        
        # 5. Instalación (Mover archivos)
        $ProgressBar.Value = 75
        $StatusLabel.Text = "Instalando mods y configuraciones..."
        
        # Mover todo el contenido de la carpeta extraída a .minecraft
        # Asumimos que el ZIP tiene la estructura correcta (mods/, config/, shaderpacks/, etc.)
        # Si el zip tiene una carpeta raíz, entramos en ella.
        $ExtractedItems = Get-ChildItem -Path $TempDir -Exclude "PaisaLand_Mods.zip"
        if ($ExtractedItems.Count -eq 1 -and $ExtractedItems[0].PSIsContainer) {
            $SourceDir = $ExtractedItems[0].FullName
        } else {
            $SourceDir = $TempDir
        }

        Log-Message "Copiando archivos desde: $SourceDir"
        Copy-Item -Path "$SourceDir\*" -Destination $MinecraftPath -Recurse -Force
        
        $ProgressBar.Value = 100
        $StatusLabel.Text = "¡Instalación Completada!"
        Log-Message "¡Todo listo! Ya puedes abrir el launcher y jugar."
        [System.Windows.Forms.MessageBox]::Show("¡Los mods de PaisaLand se han instalado correctamente!", "Éxito", "OK", "Information")

    } catch {
        Log-Message "ERROR CRÍTICO: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Ocurrió un error: $($_.Exception.Message)", "Error", "OK", "Error")
    } finally {
        $InstallButton.Enabled = $true
        $BackupButton.Enabled = $true
        # Limpieza
        if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
        $ProgressBar.Value = 0
        $ProgressBar.Style = "Continuous"
    }
}

$ActionBackup = {
    # Función simple de backup
    try {
        $BackupDir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
        Log-Message "Creando backup en el escritorio..."
        $StatusLabel.Text = "Creando Backup..."
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        
        $FoldersToBackup = @("mods", "options.txt", "servers.dat")
        foreach ($item in $FoldersToBackup) {
            $itemPath = "$MinecraftPath\$item"
            if (Test-Path $itemPath) {
                Copy-Item -Path $itemPath -Destination $BackupDir -Recurse
            }
        }
        Log-Message "Backup creado en: $BackupDir"
        [System.Windows.Forms.MessageBox]::Show("Backup guardado en tu Escritorio.", "Backup", "OK", "Information")
        $StatusLabel.Text = "Listo."
    } catch {
        Log-Message "Error creando backup: $($_.Exception.Message)"
    }
}

# --- BOTONES ---
$InstallButton = Create-Button "INSTALAR MODPACK" 365 350 200 40 $ActionInstall
$InstallButton.BackColor = $ColorAccent # Destacar el botón principal

$BackupButton = Create-Button "Crear Backup" 20 350 150 40 $ActionBackup

# --- MOSTRAR ---
$Form.Add_Shown({ $Form.Activate() })
[void] $Form.ShowDialog()
