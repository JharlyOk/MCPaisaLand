# ==============================================================================================
# EpicScript - Instalador Automático de Mods para PaisaLand
# v3.0 - ULTIMATE EDITION (WPF + XAML + Animations)
# ==============================================================================================

# --- CARGAR LIBRERÍAS DE WPF ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

# --- CONFIGURACIÓN ---
# ¡IMPORTANTE! REEMPLAZA ESTOS LINKS POR LOS TUYOS DE DROPBOX
$DownloadUrlLow = "https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=0".Replace("dl=0", "dl=1")
$DownloadUrlHigh = "https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=0".Replace("dl=0", "dl=1")
$InstallerTitle = "PaisaLand - Launcher"
$MinecraftPath = "$env:APPDATA\.minecraft"
$TempDir = "$env:TEMP\PaisaLandInstaller"

# --- DEFINICIÓN DE LA INTERFAZ XAML (ESTILO VISUAL) ---
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$InstallerTitle" Height="550" Width="850"
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">

    <Window.Resources>
        <!-- COLORES -->
        <SolidColorBrush x:Key="BgBrush" Color="#121212"/>
        <SolidColorBrush x:Key="PanelBrush" Color="#1E1E1E"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#3DAE2B"/> <!-- Verde Minecraft -->
        <SolidColorBrush x:Key="AccentDarkBrush" Color="#2A7A1E"/>
        <SolidColorBrush x:Key="TextBrush" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="SubTextBrush" Color="#AAAAAA"/>
        
        <!-- ESTILO BOTÓN PRINCIPAL (ANIMADO) -->
        <Style x:Key="MainButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="Border" Background="{TemplateBinding Background}" CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="{StaticResource AccentDarkBrush}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Border" Property="Background" Value="#444444"/>
                                <Setter Property="Foreground" Value="#888888"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ESTILO BOTÓN SECUNDARIO -->
        <Style x:Key="TextButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#AAAAAA"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="Transparent">
                            <TextBlock Text="{TemplateBinding Content}" TextDecorations="Underline" Foreground="{TemplateBinding Foreground}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ESTILO RADIO BUTTON (TARJETA) -->
        <Style x:Key="CardRadioStyle" TargetType="RadioButton">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Border Name="Border" Background="#252525" CornerRadius="10" 
                                BorderBrush="#333333" BorderThickness="2" Padding="15" Margin="0,0,15,0">
                            <DockPanel>
                                <Ellipse Name="Dot" Width="10" Height="10" Fill="Transparent" Stroke="{StaticResource AccentBrush}" StrokeThickness="2" DockPanel.Dock="Top" HorizontalAlignment="Right"/>
                                <StackPanel>
                                    <TextBlock Text="{TemplateBinding Content}" FontSize="16" FontWeight="Bold" Foreground="White" Margin="0,0,0,5"/>
                                    <TextBlock Name="Desc" Text="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}" FontSize="11" Foreground="#AAAAAA" TextWrapping="Wrap"/>
                                </StackPanel>
                            </DockPanel>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Border" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                                <Setter TargetName="Border" Property="Background" Value="#1A2E1A"/>
                                <Setter TargetName="Dot" Property="Fill" Value="{StaticResource AccentBrush}"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="BorderBrush" Value="#666666"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <!-- LAYOUT PRINCIPAL -->
    <Border CornerRadius="15" Background="{StaticResource BgBrush}" BorderBrush="#333333" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <!-- Header -->
                <RowDefinition Height="*"/>    <!-- Content -->
                <RowDefinition Height="Auto"/> <!-- Footer -->
            </Grid.RowDefinitions>

            <!-- HEADER / DRAG ZONE -->
            <Grid Grid.Row="0" Height="90" Background="Transparent" Name="DragZone">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="30,0,0,0">
                    <TextBlock Text="PAISA" FontSize="32" FontWeight="Black" Foreground="White"/>
                    <TextBlock Text="LAND" FontSize="32" FontWeight="Black" Foreground="{StaticResource AccentBrush}"/>
                </StackPanel>
                
                <Button Name="BtnClose" Content="✕" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,15,15,0"
                        Width="30" Height="30" Background="Transparent" Foreground="#666666" BorderThickness="0" FontSize="16" Cursor="Hand"/>
            </Grid>

            <!-- CONTENIDO -->
            <StackPanel Grid.Row="1" Margin="30,10,30,0">
                <TextBlock Text="SELECCIONA TU VERSIÓN" Foreground="#666666" FontSize="12" FontWeight="Bold" Margin="0,0,0,15"/>

                <StackPanel Orientation="Horizontal" Height="100">
                    <RadioButton Name="RadioLow" Content="PC GAMA BAJA" Tag="Optimizado para máximo rendimiento. Sin efectos pesados."
                                 GroupName="Version" Style="{StaticResource CardRadioStyle}" IsChecked="True" Width="380"/>
                    
                    <RadioButton Name="RadioHigh" Content="PC GAMA ALTA" Tag="Gráficos Ultra. Incluye Shaders, Texturas HD y animaciones."
                                 GroupName="Version" Style="{StaticResource CardRadioStyle}" Width="380"/>
                </StackPanel>

                <TextBlock Text="ESTADO" Foreground="#666666" FontSize="12" FontWeight="Bold" Margin="0,30,0,10"/>
                
                <!-- STATUS BAR -->
                <TextBlock Name="StatusText" Text="Listo para instalar" Foreground="White" FontSize="14" Margin="0,0,0,10"/>
                <ProgressBar Name="ProgressBar" Height="6" Background="#252525" Foreground="{StaticResource AccentBrush}" BorderThickness="0" Value="0"/>

                <!-- LOG VISUAL -->
                <Border Background="#0A0A0A" CornerRadius="5" Height="120" Margin="0,20,0,0" Padding="10">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <TextBlock Name="LogText" Text="Bienvenido al instalador v3.0..." Foreground="#00FF00" FontFamily="Consolas" FontSize="11"/>
                    </ScrollViewer>
                </Border>
            </StackPanel>

            <!-- FOOTER -->
            <Grid Grid.Row="2" Height="80" Margin="30,0,30,0">
                <Button Name="BtnBackup" Content="Crear Backup de Seguridad" HorizontalAlignment="Left" Style="{StaticResource TextButtonStyle}"/>
                <Button Name="BtnInstall" Content="INSTALAR SERVIDOR" Width="220" Height="50" HorizontalAlignment="Right" Style="{StaticResource MainButtonStyle}"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

# --- CARGAR XAML ---
$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# --- MAPEO DE CONTROLES ---
$controls = @("RadioLow", "RadioHigh", "BtnInstall", "BtnBackup", "BtnClose", "DragZone", "StatusText", "ProgressBar", "LogText", "ScrollViewer")
foreach ($ctrlName in $controls) {
    New-Variable -Name $ctrlName -Value $Window.FindName($ctrlName) -Force
}

# --- LÓGICA DE MOVIMIENTO DE VENTANA (Drag) ---
$DragZone.Add_MouseLeftButtonDown({
    $Window.DragMove()
})

$BtnClose.Add_Click({
    $Window.Close()
})

# --- FUNCIONES ---
function Log-Write($msg) {
    $script:LogText.Text += "`n> $msg"
    # Auto-scroll (Hacky in pure PS/WPF logic, but works)
    $Window.Dispatcher.Invoke([Action]{ $script:LogText.ScrollToEnd() }, "Normal")
}

# --- ACCIÓN INSTALAR ---
$BtnInstall.Add_Click({
    $BtnInstall.IsEnabled = $false
    $BtnBackup.IsEnabled = $false
    
    # Run in simpler async simulation with DoEvents to keep UI responsive-ish
    # Note: Pure PS async is hard. We will use Dispatcher frames or just careful sync steps.
    
    try {
        $SelectedUrl = ""
        if ($RadioLow.IsChecked) { 
            $SelectedUrl = $DownloadUrlLow 
            Log-Write "Modo: GAMA BAJA (Optimizado)"
        } else { 
            $SelectedUrl = $DownloadUrlHigh
            Log-Write "Modo: GAMA ALTA (Ultra)"
        }

        if ($SelectedUrl -match "URL_.*_AQUI" -or $SelectedUrl -eq "") {
            [System.Windows.MessageBox]::Show("URL no configurada.")
            return
        }

        # 1. Comprobaciones
        $StatusText.Text = "Buscando carpeta..."
        Log-Write "Verificando instalación..."
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -m 500

        if (-not (Test-Path $MinecraftPath)) {
            [System.Windows.MessageBox]::Show("No se encontró la carpeta .minecraft")
            return
        }

        # 2. Descarga
        $ZipPath = "$TempDir\PaisaLand_Mods.zip"
        if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Force -Path $TempDir | Out-Null }
        
        $StatusText.Text = "Descargando contenido..."
        Log-Write "Iniciando descarga desde la nube..."
        $ProgressBar.IsIndeterminate = $true
        [System.Windows.Forms.Application]::DoEvents()

        # Descarga Sync (bloquea UI un poco, pero es seguro en PS simple)
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($SelectedUrl, $ZipPath)
        
        $ProgressBar.IsIndeterminate = $false
        $ProgressBar.Value = 40
        Log-Write "Descarga completada."
        [System.Windows.Forms.Application]::DoEvents()

        # 3. Limpieza
        $StatusText.Text = "Limpiando mods antiguos..."
        Log-Write "Eliminando archivos viejos..."
        $ModsPath = "$MinecraftPath\mods"
        if (Test-Path $ModsPath) { Remove-Item "$ModsPath\*" -Recurse -Force -ErrorAction SilentlyContinue }
        
        # 4. Extracción
        $StatusText.Text = "Descomprimiendo paquete..."
        $ProgressBar.Value = 60
        [System.Windows.Forms.Application]::DoEvents()
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempDir -Force
        
        # 5. Instalación
        $StatusText.Text = "Instalando archivos..."
        $ProgressBar.Value = 80
        Log-Write "Copiando a .minecraft..."
        [System.Windows.Forms.Application]::DoEvents()

        $ExtractedItems = Get-ChildItem -Path $TempDir -Exclude "PaisaLand_Mods.zip"
        if ($ExtractedItems.Count -eq 1 -and $ExtractedItems[0].PSIsContainer) {
            $SourceDir = $ExtractedItems[0].FullName
        } else {
            $SourceDir = $TempDir
        }

        Copy-Item -Path "$SourceDir\*" -Destination $MinecraftPath -Recurse -Force
        
        $ProgressBar.Value = 100
        $StatusText.Text = "¡INSTALACIÓN COMPLETADA!"
        $StatusText.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        Log-Write "¡Todo listo! Cierra esto y abre el juego."
        [System.Windows.MessageBox]::Show("Instalación exitosa. ¡A jugar!", "PaisaLand", "OK", "Information")

    } catch {
        Log-Write "ERROR: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)")
    } finally {
        $BtnInstall.IsEnabled = $true
        $BtnBackup.IsEnabled = $true
        if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
        $ProgressBar.IsIndeterminate = $false
        # No reset value so user sees 100%
    }
})

# --- ACCIÓN BACKUP ---
$BtnBackup.Add_Click({
    try {
        $BackupDir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
        $StatusText.Text = "Realizando Backup..."
        Log-Write "Guardando copia en Escritorio..."
        [System.Windows.Forms.Application]::DoEvents()
        
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        $FoldersToBackup = @("mods", "config", "shaderpacks", "resourcepacks", "emotes", "options.txt", "servers.dat")
        
        foreach ($item in $FoldersToBackup) {
            $itemPath = "$MinecraftPath\$item"
            if (Test-Path $itemPath) {
                Copy-Item -Path $itemPath -Destination $BackupDir -Recurse
            }
        }
        Log-Write "Backup guardado: $BackupDir"
        $StatusText.Text = "Backup Finalizado"
        [System.Windows.MessageBox]::Show("Backup creado en el Escritorio.", "Backup", "OK", "Information")
    } catch {
        Log-Write "Error Backup: $($_.Exception.Message)"
    }
})

# --- INICIAR ---
[void]$Window.ShowDialog()
