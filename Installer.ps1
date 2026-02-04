# ==============================================================================================
# PaisaLand Installer v4.0.0 - PROFESSIONAL EDITION (Bundled Single-File)
# Compatible con: irm https://... | iex
# ==============================================================================================

# --- Cargar Librerías ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ==================== CONFIGURACIÓN ====================
$script:Config = @{
    Version = "4.0.0"
    VersionUrl = "https://raw.githubusercontent.com/JharlyOk/MCPaisaLand/main/version.txt"
    DownloadUrlLow = "https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=1"
    DownloadUrlHigh = "https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=1"
    ServerIP = "play.paisaland.com"
    ServerPort = 25565
    MinecraftPath = "$env:APPDATA\.minecraft"
    TempDir = "$env:TEMP\PaisaLandInstaller"
    PrefsFile = "$env:APPDATA\PaisaLand\preferences.json"
    ManagedFolders = @("mods", "config", "shaderpacks", "resourcepacks", "emotes", "options.txt", "servers.dat")
    MinDiskSpaceMB = 500
}

# ==================== FUNCIONES ====================

function Test-MinecraftInstalled { return (Test-Path $script:Config.MinecraftPath) }

function Test-DiskSpace {
    param([int]$RequiredMB = 500)
    $drive = (Get-Item $env:APPDATA).PSDrive.Name
    $freeSpace = (Get-PSDrive $drive).Free / 1MB
    return $freeSpace -ge $RequiredMB
}

function Get-ServerStatus {
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($script:Config.ServerIP, $script:Config.ServerPort, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne(2000, $false)
        if ($wait -and $tcpClient.Connected) { $tcpClient.Close(); return @{ Online = $true; Message = "En Línea" } }
        return @{ Online = $false; Message = "Fuera de Línea" }
    } catch { return @{ Online = $false; Message = "Error" } }
}

function Get-RemoteVersion {
    try { return (New-Object System.Net.WebClient).DownloadString($script:Config.VersionUrl).Trim() } catch { return $null }
}

function Test-UpdateAvailable {
    $remote = Get-RemoteVersion
    if ($remote -and $remote -ne $script:Config.Version) { return @{ Available = $true; RemoteVersion = $remote } }
    return @{ Available = $false; RemoteVersion = $script:Config.Version }
}

function Save-UserPreference { param([string]$Key, $Value)
    $prefsDir = Split-Path $script:Config.PrefsFile -Parent
    if (-not (Test-Path $prefsDir)) { New-Item -ItemType Directory -Path $prefsDir -Force | Out-Null }
    $prefs = @{}; if (Test-Path $script:Config.PrefsFile) { $prefs = Get-Content $script:Config.PrefsFile | ConvertFrom-Json -AsHashtable }
    $prefs[$Key] = $Value; $prefs | ConvertTo-Json | Set-Content $script:Config.PrefsFile
}

function Get-UserPreference { param([string]$Key, $Default = $null)
    if (Test-Path $script:Config.PrefsFile) { $prefs = Get-Content $script:Config.PrefsFile | ConvertFrom-Json -AsHashtable; if ($prefs.ContainsKey($Key)) { return $prefs[$Key] } }
    return $Default
}

function Install-Modpack { param([string]$ZipPath)
    $tempExtract = "$($script:Config.TempDir)\extracted"
    $modsPath = "$($script:Config.MinecraftPath)\mods"
    if (Test-Path $modsPath) { Remove-Item "$modsPath\*" -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $tempExtract -Force
    $items = Get-ChildItem -Path $tempExtract
    $sourceDir = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $tempExtract }
    Copy-Item -Path "$sourceDir\*" -Destination $script:Config.MinecraftPath -Recurse -Force
    return $true
}

function New-Backup {
    $backupDir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    foreach ($item in $script:Config.ManagedFolders) {
        $itemPath = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $itemPath) { Copy-Item -Path $itemPath -Destination $backupDir -Recurse }
    }
    return $backupDir
}

function Remove-Modpack {
    foreach ($item in $script:Config.ManagedFolders) {
        $itemPath = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $itemPath) { Remove-Item -Path $itemPath -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Clear-TempFiles { if (Test-Path $script:Config.TempDir) { Remove-Item $script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue } }

# ==================== XAML UI (INLINED) ====================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PaisaLand Installer" Height="580" Width="900"
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <SolidColorBrush x:Key="BgBrush" Color="#0D0D0D"/>
        <SolidColorBrush x:Key="CardBrush" Color="#1A1A1A"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#4CAF50"/>
        <SolidColorBrush x:Key="DangerBrush" Color="#E53935"/>
        <SolidColorBrush x:Key="SubTextBrush" Color="#888888"/>
        <SolidColorBrush x:Key="BorderBrush" Color="#333333"/>
        
        <Style x:Key="PrimaryBtn" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="6" Padding="20,12">
                    <Border.Effect><DropShadowEffect Color="Black" BlurRadius="10" ShadowDepth="2" Opacity="0.3"/></Border.Effect>
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#66BB6A"/></Trigger>
                    <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Background" Value="#444"/><Setter Property="Foreground" Value="#888"/></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <Style x:Key="DangerBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{StaticResource DangerBrush}"/>
            <Setter Property="FontSize" Value="12"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="4" Padding="12,8" BorderBrush="{StaticResource DangerBrush}" BorderThickness="1">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{StaticResource DangerBrush}"/><Setter Property="Foreground" Value="White"/></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <Style x:Key="LinkBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{StaticResource SubTextBrush}"/><Setter Property="FontSize" Value="12"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <TextBlock x:Name="T" Text="{TemplateBinding Content}" TextDecorations="Underline" Foreground="{TemplateBinding Foreground}"/>
                <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="T" Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <Style x:Key="CloseBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#666"/><Setter Property="Width" Value="46"/><Setter Property="Height" Value="32"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Bd" Background="{TemplateBinding Background}"><TextBlock Text="✕" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="{TemplateBinding Foreground}" FontWeight="Bold"/></Border>
                <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{StaticResource DangerBrush}"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <Style x:Key="MinBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#666"/><Setter Property="Width" Value="46"/><Setter Property="Height" Value="32"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Bd" Background="{TemplateBinding Background}"><TextBlock Text="—" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="{TemplateBinding Foreground}" FontWeight="Bold"/></Border>
                <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#333"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <Style x:Key="CardRadio" TargetType="RadioButton">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="RadioButton">
                <Border x:Name="Bd" Background="{StaticResource CardBrush}" CornerRadius="10" BorderBrush="{StaticResource BorderBrush}" BorderThickness="2" Padding="20" Margin="0,0,15,0">
                    <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                        <Ellipse x:Name="Dot" Width="12" Height="12" Stroke="{StaticResource AccentBrush}" StrokeThickness="2" Fill="Transparent" HorizontalAlignment="Right"/>
                        <StackPanel Grid.Row="1" Margin="0,10,0,0">
                            <TextBlock Text="{TemplateBinding Content}" FontSize="16" FontWeight="Bold" Foreground="White"/>
                            <TextBlock Text="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}" FontSize="11" Foreground="{StaticResource SubTextBrush}" TextWrapping="Wrap" Margin="0,8,0,0"/>
                        </StackPanel>
                    </Grid>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsChecked" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource AccentBrush}"/><Setter TargetName="Bd" Property="Background" Value="#1A2E1A"/><Setter TargetName="Dot" Property="Fill" Value="{StaticResource AccentBrush}"/></Trigger>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="#555"/></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>

    <Border CornerRadius="12" Background="{StaticResource BgBrush}">
        <Border.Effect><DropShadowEffect Color="Black" BlurRadius="25" ShadowDepth="0" Opacity="0.6"/></Border.Effect>
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="50"/><RowDefinition Height="50"/><RowDefinition Height="*"/><RowDefinition Height="80"/></Grid.RowDefinitions>

            <!-- HEADER -->
            <Grid Grid.Row="0" Name="DragZone">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="20,0,0,0">
                    <TextBlock Text="PAISA" FontSize="22" FontWeight="Black" Foreground="White"/>
                    <TextBlock Text="LAND" FontSize="22" FontWeight="Black" Foreground="{StaticResource AccentBrush}"/>
                    <TextBlock Text=" Installer" FontSize="14" FontWeight="Light" Foreground="#888" VerticalAlignment="Bottom" Margin="5,0,0,3"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Name="BtnMinimize" Style="{StaticResource MinBtn}"/>
                    <Button Name="BtnClose" Style="{StaticResource CloseBtn}"/>
                </StackPanel>
            </Grid>

            <!-- STATUS -->
            <Border Grid.Row="1" Background="#151515" Padding="20,0">
                <Grid>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <Ellipse Name="ServerIndicator" Width="10" Height="10" Fill="#E53935"/>
                        <TextBlock Name="ServerStatus" Text="Servidor: Verificando..." Foreground="#888" FontSize="12" Margin="8,0,0,0"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                        <TextBlock Name="VersionBadge" Text="v4.0.0" Foreground="#444" FontSize="11"/>
                        <Border Name="UpdateBadge" Background="{StaticResource AccentBrush}" CornerRadius="3" Padding="6,2" Margin="10,0,0,0" Visibility="Collapsed">
                            <TextBlock Text="UPDATE" FontSize="10" FontWeight="Bold" Foreground="White"/>
                        </Border>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- CONTENT -->
            <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
                <StackPanel Margin="25,20,25,0">
                    <TextBlock Text="SELECCIONA TU VERSIÓN" Foreground="#555" FontSize="11" FontWeight="Bold" Margin="0,0,0,12"/>
                    <Grid Height="130">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                        <RadioButton Name="RadioLow" Grid.Column="0" Content="💻 PC GAMA BAJA" Tag="Optimizado para máximo FPS. Sin shaders ni texturas pesadas." Style="{StaticResource CardRadio}" IsChecked="True"/>
                        <RadioButton Name="RadioHigh" Grid.Column="1" Content="🎮 PC GAMA ALTA" Tag="Experiencia Ultra. Incluye Shaders, Texturas HD y animaciones." Style="{StaticResource CardRadio}"/>
                    </Grid>
                    <TextBlock Text="ESTADO" Foreground="#555" FontSize="11" FontWeight="Bold" Margin="0,25,0,12"/>
                    <Border Background="#151515" CornerRadius="8" Padding="15">
                        <StackPanel>
                            <TextBlock Name="StatusText" Text="Listo para instalar" Foreground="White" FontSize="14"/>
                            <ProgressBar Name="ProgressBar" Height="4" Background="#252525" Foreground="{StaticResource AccentBrush}" BorderThickness="0" Margin="0,12,0,0" Value="0"/>
                        </StackPanel>
                    </Border>
                    <Border Background="#0A0A0A" CornerRadius="6" Margin="0,15,0,0" Padding="12" Height="100">
                        <ScrollViewer Name="LogScroller" VerticalScrollBarVisibility="Auto">
                            <TextBlock Name="LogText" Text="> Bienvenido al instalador de PaisaLand v4.0" Foreground="#00DD00" FontFamily="Consolas" FontSize="11" TextWrapping="Wrap"/>
                        </ScrollViewer>
                    </Border>
                </StackPanel>
            </ScrollViewer>

            <!-- FOOTER -->
            <Border Grid.Row="3" Background="#0A0A0A" Padding="25,0">
                <Grid VerticalAlignment="Center">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Left">
                        <Button Name="BtnBackup" Content="📁 Crear Backup" Style="{StaticResource LinkBtn}"/>
                        <Button Name="BtnUninstall" Content="🗑️ Desinstalar Mods" Style="{StaticResource DangerBtn}" Margin="20,0,0,0"/>
                    </StackPanel>
                    <Button Name="BtnInstall" Content="⬇️ INSTALAR MODPACK" Style="{StaticResource PrimaryBtn}" HorizontalAlignment="Right"/>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

# ==================== CARGAR UI ====================
$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$controls = @("DragZone","BtnMinimize","BtnClose","ServerIndicator","ServerStatus","VersionBadge","UpdateBadge","RadioLow","RadioHigh","StatusText","ProgressBar","LogScroller","LogText","BtnBackup","BtnUninstall","BtnInstall")
$UI = @{}; foreach ($n in $controls) { $c = $Window.FindName($n); if ($c) { $UI[$n] = $c } }

# ==================== HELPERS UI ====================
function Write-Log { param([string]$M); $UI.LogText.Text += "`n> $M"; $UI.LogScroller.ScrollToEnd(); [System.Windows.Forms.Application]::DoEvents() }
function Update-Status { param([string]$M); $UI.StatusText.Text = $M; [System.Windows.Forms.Application]::DoEvents() }
function Update-Progress { param([int]$V); $UI.ProgressBar.Value = $V; [System.Windows.Forms.Application]::DoEvents() }

# ==================== INIT ====================
function Initialize-Installer {
    Write-Log "Verificando servidor..."
    $s = Get-ServerStatus
    if ($s.Online) { $UI.ServerIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen; $UI.ServerStatus.Text = "Servidor: $($s.Message)"; $UI.ServerStatus.Foreground = [System.Windows.Media.Brushes]::LimeGreen }
    else { $UI.ServerIndicator.Fill = [System.Windows.Media.Brushes]::Red; $UI.ServerStatus.Text = "Servidor: $($s.Message)" }
    
    Write-Log "Buscando actualizaciones..."
    $u = Test-UpdateAvailable; $UI.VersionBadge.Text = "v$($script:Config.Version)"
    if ($u.Available) { $UI.UpdateBadge.Visibility = "Visible"; Write-Log "Nueva versión: $($u.RemoteVersion)" }
    
    $last = Get-UserPreference -Key "GamaSelection" -Default "Low"
    if ($last -eq "High") { $UI.RadioHigh.IsChecked = $true }
    Write-Log "Instalador listo."
}

# ==================== EVENTOS ====================
$UI.DragZone.Add_MouseLeftButtonDown({ $Window.DragMove() })
$UI.BtnClose.Add_Click({ $Window.Close() })
$UI.BtnMinimize.Add_Click({ $Window.WindowState = "Minimized" })

$UI.BtnInstall.Add_Click({
    $UI.BtnInstall.IsEnabled = $false; $UI.BtnBackup.IsEnabled = $false; $UI.BtnUninstall.IsEnabled = $false
    try {
        if ($UI.RadioLow.IsChecked) { $url = $script:Config.DownloadUrlLow; Save-UserPreference -Key "GamaSelection" -Value "Low"; Write-Log "Modo: GAMA BAJA" }
        else { $url = $script:Config.DownloadUrlHigh; Save-UserPreference -Key "GamaSelection" -Value "High"; Write-Log "Modo: GAMA ALTA" }
        
        Update-Status "Verificando Minecraft..."; if (-not (Test-MinecraftInstalled)) { [System.Windows.MessageBox]::Show("No se encontró .minecraft"); return }
        Write-Log "Minecraft encontrado."; Update-Progress 10
        
        Update-Status "Verificando espacio..."; if (-not (Test-DiskSpace)) { [System.Windows.MessageBox]::Show("Espacio insuficiente"); return }
        Write-Log "Espacio OK."; Update-Progress 20
        
        $zip = "$($script:Config.TempDir)\mods.zip"; if (-not (Test-Path $script:Config.TempDir)) { New-Item -ItemType Directory -Path $script:Config.TempDir -Force | Out-Null }
        Update-Status "Descargando..."; Write-Log "Iniciando descarga..."
        $UI.ProgressBar.IsIndeterminate = $true; [System.Windows.Forms.Application]::DoEvents()
        (New-Object System.Net.WebClient).DownloadFile($url, $zip)
        $UI.ProgressBar.IsIndeterminate = $false; Update-Progress 50; Write-Log "Descarga completa."
        
        Update-Status "Instalando..."; Write-Log "Extrayendo archivos..."
        Install-Modpack -ZipPath $zip; Update-Progress 90
        
        Clear-TempFiles; Update-Progress 100
        Update-Status "¡INSTALACIÓN COMPLETADA!"; $UI.StatusText.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        Write-Log "¡Listo! Abre el juego."
        [System.Windows.MessageBox]::Show("¡Modpack instalado!", "PaisaLand", "OK", "Information")
    } catch { Write-Log "ERROR: $($_.Exception.Message)"; [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)") }
    finally { $UI.BtnInstall.IsEnabled = $true; $UI.BtnBackup.IsEnabled = $true; $UI.BtnUninstall.IsEnabled = $true; $UI.ProgressBar.IsIndeterminate = $false }
})

$UI.BtnBackup.Add_Click({
    try { Update-Status "Creando backup..."; Write-Log "Respaldando..."; $p = New-Backup; Write-Log "Backup: $p"; Update-Status "Backup listo"; [System.Windows.MessageBox]::Show("Backup en Escritorio.") }
    catch { Write-Log "Error: $($_.Exception.Message)" }
})

$UI.BtnUninstall.Add_Click({
    $r = [System.Windows.MessageBox]::Show("¿Eliminar mods de PaisaLand?", "Confirmar", "YesNo", "Warning")
    if ($r -eq "Yes") { try { Update-Status "Desinstalando..."; Write-Log "Eliminando..."; Remove-Modpack; Write-Log "Mods eliminados."; Update-Status "Desinstalación OK"; [System.Windows.MessageBox]::Show("Mods eliminados.") } catch { Write-Log "Error: $($_.Exception.Message)" } }
})

# ==================== INICIAR ====================
$Window.Add_Loaded({ Initialize-Installer })
[void]$Window.ShowDialog()
