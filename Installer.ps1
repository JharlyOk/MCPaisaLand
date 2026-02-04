# ==============================================================================================
# EpicScript - Instalador Automático de Mods para PaisaLand
# v2.0 - Rediseño Moderno "Launcher Style"
# ==============================================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURACIÓN ---
# ¡IMPORTANTE! REEMPLAZA ESTOS LINKS POR LOS TUYOS DE DROPBOX
# Si terminan en dl=0, el script lo arreglará automáticamente.
$DownloadUrlLow = "https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=0".Replace("dl=0", "dl=1")
$DownloadUrlHigh = "https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=0".Replace("dl=0", "dl=1")
$InstallerTitle = "PaisaLand - Instalador Oficial"
$MinecraftPath = "$env:APPDATA\.minecraft"
$TempDir = "$env:TEMP\PaisaLandInstaller"

# --- ESTILO VISUAL (Launcher Theme) ---
$ColorBgDeep    = [System.Drawing.Color]::FromArgb(30, 30, 30)      # Fondo Principal
$ColorPanel     = [System.Drawing.Color]::FromArgb(45, 45, 45)      # Paneles
$ColorGreen     = [System.Drawing.Color]::FromArgb(59, 133, 38)     # Botón Jugar (Normal)
$ColorGreenHv   = [System.Drawing.Color]::FromArgb(83, 163, 58)     # Botón Jugar (Hover)
$ColorText      = [System.Drawing.Color]::White
$ColorSubText   = [System.Drawing.Color]::FromArgb(170, 170, 170)
$ColorBorder    = [System.Drawing.Color]::FromArgb(60, 60, 60)

$FontTitle      = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
$FontSubTitle   = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)
$FontButton     = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$FontRadio      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$FontConsole    = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)

# --- VENTANA PRINCIPAL ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = $InstallerTitle
$Form.Size = New-Object System.Drawing.Size(800, 500)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $ColorBgDeep
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false
$Form.Icon = [System.Drawing.SystemIcons]::Application

# --- COMPONENTES UI ---

# 1. Header Hero
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(800, 100)
$HeaderPanel.BackColor = $ColorBgDeep
$HeaderPanel.Location = New-Object System.Drawing.Point(0, 0)
$Form.Controls.Add($HeaderPanel)

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "PAISALAND"
$TitleLabel.Font = $FontTitle
$TitleLabel.ForeColor = $ColorText
$TitleLabel.AutoSize = $true
$TitleLabel.Location = New-Object System.Drawing.Point(30, 25)
$HeaderPanel.Controls.Add($TitleLabel)

$DescLabel = New-Object System.Windows.Forms.Label
$DescLabel.Text = "INSTALADOR DE MODS"
$DescLabel.Font = $FontSubTitle
$DescLabel.ForeColor = $ColorGreen
$DescLabel.AutoSize = $true
$DescLabel.Location = New-Object System.Drawing.Point(230, 42)
$HeaderPanel.Controls.Add($DescLabel)

# 2. Área de Contenido
$ContentPanel = New-Object System.Windows.Forms.Panel
$ContentPanel.Size = New-Object System.Drawing.Size(740, 340)
$ContentPanel.Location = New-Object System.Drawing.Point(30, 100)
$ContentPanel.BackColor = $ColorPanel
$Form.Controls.Add($ContentPanel)

# Selección de Gama
$LblSelect = New-Object System.Windows.Forms.Label
$LblSelect.Text = "SELECCIONA TU VERSIÓN:"
$LblSelect.ForeColor = $ColorSubText
$LblSelect.Font = $FontSubTitle
$LblSelect.AutoSize = $true
$LblSelect.Location = New-Object System.Drawing.Point(30, 20)
$ContentPanel.Controls.Add($LblSelect)

$RadioLow = New-Object System.Windows.Forms.RadioButton
$RadioLow.Text = "PC Gama Baja (Optimizado para FPS)"
$RadioLow.Location = New-Object System.Drawing.Point(50, 60)
$RadioLow.Size = New-Object System.Drawing.Size(300, 30)
$RadioLow.Font = $FontRadio
$RadioLow.ForeColor = [System.Drawing.Color]::LightGreen
$RadioLow.Checked = $true
$ContentPanel.Controls.Add($RadioLow)

$RadioHigh = New-Object System.Windows.Forms.RadioButton
$RadioHigh.Text = "PC Gama Alta (Texturas + Shaders)"
$RadioHigh.Location = New-Object System.Drawing.Point(400, 60)
$RadioHigh.Size = New-Object System.Drawing.Size(300, 30)
$RadioHigh.Font = $FontRadio
$RadioHigh.ForeColor = [System.Drawing.Color]::Gold
$ContentPanel.Controls.Add($RadioHigh)

# Estado y Progreso
$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Text = "Esperando..."
$StatusLabel.ForeColor = $ColorText
$StatusLabel.Font = $FontSubTitle
$StatusLabel.AutoSize = $true
$StatusLabel.Location = New-Object System.Drawing.Point(30, 120)
$ContentPanel.Controls.Add($StatusLabel)

$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(30, 150)
$ProgressBar.Size = New-Object System.Drawing.Size(680, 20)
$ProgressBar.Style = "Continuous"
$ContentPanel.Controls.Add($ProgressBar)

# Terminal (Log) - Más discreta
$LogBox = New-Object System.Windows.Forms.TextBox
$LogBox.Multiline = $true
$LogBox.ReadOnly = $true
$LogBox.ScrollBars = "Vertical"
$LogBox.Location = New-Object System.Drawing.Point(30, 190)
$LogBox.Size = New-Object System.Drawing.Size(680, 130)
$LogBox.BackColor = [System.Drawing.Color]::Black
$LogBox.ForeColor = [System.Drawing.Color]::LimeGreen
$LogBox.BorderStyle = "FixedSingle"
$LogBox.Font = $FontConsole
$ContentPanel.Controls.Add($LogBox)

function Log-Message($msg) {
    $LogBox.AppendText("> $msg`r`n")
    $LogBox.ScrollToCaret()
    $Form.Refresh()
}

# 3. Footer (Botones)
$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "INSTALAR"
$BtnInstall.Size = New-Object System.Drawing.Size(250, 60)
$BtnInstall.Location = New-Object System.Drawing.Point(520, 260) # Dentro del ContentPanel? No, form.
# Ubicación en Form absolute
$BtnInstall.Location = New-Object System.Drawing.Point(520, 370)
$BtnInstall.FlatStyle = "Flat"
$BtnInstall.ForeColor = $ColorText
$BtnInstall.BackColor = $ColorGreen
$BtnInstall.Font = $FontButton
$BtnInstall.FlatAppearance.BorderSize = 0
$BtnInstall.Cursor = [System.Windows.Forms.Cursors]::Hand
# Hover Effects
$BtnInstall.add_MouseEnter({ param($sender,$e) $sender.BackColor = $ColorGreenHv })
$BtnInstall.add_MouseLeave({ param($sender,$e) $sender.BackColor = $ColorGreen })
$Form.Controls.Add($BtnInstall)

$BtnBackup = New-Object System.Windows.Forms.Button
$BtnBackup.Text = "Crear Backup"
$BtnBackup.Size = New-Object System.Drawing.Size(150, 40)
$BtnBackup.Location = New-Object System.Drawing.Point(30, 380)
$BtnBackup.FlatStyle = "Flat"
$BtnBackup.ForeColor = [System.Drawing.Color]::Gray
$BtnBackup.BackColor = $ColorBgDeep
$BtnBackup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Underline)
$BtnBackup.FlatAppearance.BorderSize = 0
$BtnBackup.Cursor = [System.Windows.Forms.Cursors]::Hand
$Form.Controls.Add($BtnBackup)


# --- LÓGICA DE INSTALACIÓN (Sin cambios funcionales, solo visuales) ---
$ActionInstall = {
    $BtnInstall.Enabled = $false
    $BtnBackup.Enabled = $false
    $BtnInstall.BackColor = [System.Drawing.Color]::Gray
    
    try {
        $SelectedUrl = ""
        if ($RadioLow.Checked) { 
            $SelectedUrl = $DownloadUrlLow 
            Log-Message "Versión seleccionada: GAMA BAJA"
        } else { 
            $SelectedUrl = $DownloadUrlHigh
            Log-Message "Versión seleccionada: GAMA ALTA"
        }

        if ($SelectedUrl -match "URL_.*_AQUI" -or $SelectedUrl -eq "") {
            Log-Message "ERROR: URL no configurada."
            [System.Windows.Forms.MessageBox]::Show("Falta configurar el link de descarga.", "Error", "OK", "Error")
            return
        }

        # 1. Comprobaciones
        $StatusLabel.Text = "Verificando Minecraft..."
        if (-not (Test-Path $MinecraftPath)) {
            Log-Message "Error: No se encontró .minecraft"
            [System.Windows.Forms.MessageBox]::Show("Abre Minecraft al menos una vez antes de instalar.", "Error", "OK", "Error")
            return
        }

        # 2. Descarga
        $ZipPath = "$TempDir\PaisaLand_Mods.zip"
        if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir | Out-Null }
        
        $StatusLabel.Text = "Descargando contenido..."
        Log-Message "Iniciando descarga..."
        
        $WebClient = New-Object System.Net.WebClient
        $ProgressBar.Style = "Marquee"
        $WebClient.DownloadFile($SelectedUrl, $ZipPath)
        $ProgressBar.Style = "Continuous"
        $ProgressBar.Value = 40
        Log-Message "Descarga exitosa."

        # 3. Limpieza
        $StatusLabel.Text = "Limpiando instalación anterior..."
        Log-Message "Borrando mods viejos..."
        $ModsPath = "$MinecraftPath\mods"
        if (Test-Path $ModsPath) { Remove-Item "$ModsPath\*" -Recurse -Force -ErrorAction SilentlyContinue }
        
        # 4. Extracción
        $StatusLabel.Text = "Descomprimiendo..."
        Log-Message "Extrayendo archivos..."
        $ProgressBar.Value = 70
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempDir -Force
        
        # 5. Instalación
        $ProgressBar.Value = 90
        $StatusLabel.Text = "Instalando..."
        
        $ExtractedItems = Get-ChildItem -Path $TempDir -Exclude "PaisaLand_Mods.zip"
        if ($ExtractedItems.Count -eq 1 -and $ExtractedItems[0].PSIsContainer) {
            $SourceDir = $ExtractedItems[0].FullName
        } else {
            $SourceDir = $TempDir
        }

        Log-Message "Moviendo archivos a Minecraft..."
        Copy-Item -Path "$SourceDir\*" -Destination $MinecraftPath -Recurse -Force
        
        $ProgressBar.Value = 100
        $StatusLabel.Text = "¡LISTO PARA JUGAR!"
        $StatusLabel.ForeColor = $ColorGreen
        Log-Message "Instalación completada exitosamente."
        [System.Windows.Forms.MessageBox]::Show("¡Instalación completada! Abre el Launcher y juega.", "PaisaLand", "OK", "Information")

    } catch {
        Log-Message "ERROR: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", "OK", "Error")
    } finally {
        $BtnInstall.Enabled = $true
        $BtnBackup.Enabled = $true
        $BtnInstall.BackColor = $ColorGreen
        if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
        $ProgressBar.Style = "Continuous"
    }
}

$ActionBackup = {
    try {
        $BackupDir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
        $StatusLabel.Text = "Creando Backup..."
        Log-Message "Guardando copia en el Escritorio..."
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        
        $FoldersToBackup = @("mods", "config", "shaderpacks", "resourcepacks", "emotes", "options.txt", "servers.dat")
        foreach ($item in $FoldersToBackup) {
            $itemPath = "$MinecraftPath\$item"
            if (Test-Path $itemPath) {
                Copy-Item -Path $itemPath -Destination $BackupDir -Recurse
            }
        }
        Log-Message "Backup guardado: $BackupDir"
        $StatusLabel.Text = "Backup Completado"
        [System.Windows.Forms.MessageBox]::Show("Backup guardado en tu Escritorio.", "Backup", "OK", "Information")
    } catch {
        Log-Message "Error Backup: $($_.Exception.Message)"
    }
}

$BtnInstall.add_Click($ActionInstall)
$BtnBackup.add_Click($ActionBackup)

# --- MOSTRAR ---
$Form.Add_Shown({ $Form.Activate() })
[void] $Form.ShowDialog()
