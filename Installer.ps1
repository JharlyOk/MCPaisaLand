# ==============================================================================================
# PaisaLand Installer v5.0.0 - WOOTING-INSPIRED DESIGN (Dark/Light Mode)
# Compatible con: irm https://... | iex
# ==============================================================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ==================== CONFIGURACIÓN ====================
$script:Config = @{
    Version = "5.0.0"
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

$script:IsDarkMode = $true

# ==================== FUNCIONES ====================
function Test-MinecraftInstalled { return (Test-Path $script:Config.MinecraftPath) }
function Test-DiskSpace { param([int]$RequiredMB = 500); $drive = (Get-Item $env:APPDATA).PSDrive.Name; return ((Get-PSDrive $drive).Free / 1MB) -ge $RequiredMB }

function Get-ServerStatus {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ar = $tcp.BeginConnect($script:Config.ServerIP, $script:Config.ServerPort, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne(2000, $false) -and $tcp.Connected) { $tcp.Close(); return @{ Online = $true; Message = "En Línea" } }
        return @{ Online = $false; Message = "Fuera de Línea" }
    } catch { return @{ Online = $false; Message = "Error" } }
}

function Save-UserPreference { param([string]$Key, $Value)
    $dir = Split-Path $script:Config.PrefsFile -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
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
    $src = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $tempExtract }
    Copy-Item -Path "$src\*" -Destination $script:Config.MinecraftPath -Recurse -Force
}

function New-Backup {
    $backupDir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    foreach ($item in $script:Config.ManagedFolders) {
        $p = "$($script:Config.MinecraftPath)\$item"
        if (Test-Path $p) { Copy-Item -Path $p -Destination $backupDir -Recurse }
    }
    return $backupDir
}

function Remove-Modpack { foreach ($item in $script:Config.ManagedFolders) { $p = "$($script:Config.MinecraftPath)\$item"; if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue } } }
function Clear-TempFiles { if (Test-Path $script:Config.TempDir) { Remove-Item $script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue } }

# ==================== THEME COLORS ====================
$script:Themes = @{
    Dark = @{
        Bg = "#2D2D30"; Card = "#1E1E1E"; Text = "#FFFFFF"; SubText = "#888888"; Border = "#404040"; Accent = "#4CAF50"
    }
    Light = @{
        Bg = "#FFFFFF"; Card = "#F5F5F5"; Text = "#1A1A1A"; SubText = "#666666"; Border = "#E0E0E0"; Accent = "#4CAF50"
    }
}

# ==================== BUILD XAML FUNCTION ====================
function Get-InstallerXAML {
    param([bool]$Dark = $true)
    $t = if ($Dark) { $script:Themes.Dark } else { $script:Themes.Light }
    
    return @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PaisaLand Installer" Height="520" Width="480"
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">

    <Border CornerRadius="10" Background="$($t.Bg)" BorderBrush="$($t.Border)" BorderThickness="1">
        <Border.Effect><DropShadowEffect Color="Black" BlurRadius="20" ShadowDepth="0" Opacity="0.5"/></Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="50"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="50"/>
            </Grid.RowDefinitions>

            <!-- HEADER -->
            <Grid Grid.Row="0" Name="DragZone" Background="Transparent">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="15,0,0,0">
                    <TextBlock Text="🎮" FontSize="20" VerticalAlignment="Center"/>
                    <TextBlock Text=" PAISA" FontSize="16" FontWeight="Bold" Foreground="$($t.Text)" VerticalAlignment="Center"/>
                    <TextBlock Text="LAND" FontSize="16" FontWeight="Bold" Foreground="$($t.Accent)" VerticalAlignment="Center"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,5,0">
                    <Button Name="BtnTheme" Content="$(if($Dark){'☀️'}else{'🌙'})" Width="36" Height="36" Background="Transparent" BorderThickness="0" Foreground="$($t.SubText)" FontSize="16" Cursor="Hand"/>
                    <Button Name="BtnMinimize" Content="─" Width="36" Height="36" Background="Transparent" BorderThickness="0" Foreground="$($t.SubText)" FontSize="14" Cursor="Hand"/>
                    <Button Name="BtnClose" Content="✕" Width="36" Height="36" Background="Transparent" BorderThickness="0" Foreground="$($t.SubText)" FontSize="14" FontWeight="Bold" Cursor="Hand"/>
                </StackPanel>
            </Grid>

            <!-- CONTENT -->
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="20,10">
                <StackPanel>
                    <!-- Main Toggle Card -->
                    <Border Background="$($t.Card)" CornerRadius="8" Padding="20" Margin="0,0,0,15">
                        <Grid>
                            <StackPanel>
                                <TextBlock Text="Activar Gama Alta" FontSize="16" FontWeight="SemiBold" Foreground="$($t.Text)"/>
                                <TextBlock Text="Incluye Shaders, Texturas HD y efectos visuales avanzados." FontSize="12" Foreground="$($t.SubText)" Margin="0,8,0,0" TextWrapping="Wrap"/>
                            </StackPanel>
                            <CheckBox Name="ToggleHighSpec" HorizontalAlignment="Right" VerticalAlignment="Top" Cursor="Hand">
                                <CheckBox.Template>
                                    <ControlTemplate TargetType="CheckBox">
                                        <Grid>
                                            <Border x:Name="Track" Width="50" Height="26" CornerRadius="13" Background="#555555"/>
                                            <Border x:Name="Thumb" Width="22" Height="22" CornerRadius="11" Background="White" HorizontalAlignment="Left" Margin="2,0,0,0">
                                                <Border.RenderTransform><TranslateTransform x:Name="ThumbTranslate" X="0"/></Border.RenderTransform>
                                            </Border>
                                        </Grid>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsChecked" Value="True">
                                                <Setter TargetName="Track" Property="Background" Value="$($t.Accent)"/>
                                                <Setter TargetName="ThumbTranslate" Property="X" Value="24"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </CheckBox.Template>
                            </CheckBox>
                        </Grid>
                    </Border>
                    
                    <!-- Server Status Card -->
                    <Border Background="$($t.Card)" CornerRadius="8" Padding="15" Margin="0,0,0,15">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal">
                                <Ellipse Name="ServerIndicator" Width="10" Height="10" Fill="#E53935"/>
                                <TextBlock Name="ServerStatus" Text="Servidor: Verificando..." Foreground="$($t.SubText)" FontSize="12" Margin="8,0,0,0"/>
                            </StackPanel>
                            <TextBlock Name="StatusText" Text="Listo para instalar" Foreground="$($t.Text)" FontSize="14" Margin="0,10,0,0"/>
                            <ProgressBar Name="ProgressBar" Height="4" Background="#333333" Foreground="$($t.Accent)" BorderThickness="0" Margin="0,10,0,0" Value="0"/>
                        </StackPanel>
                    </Border>
                    
                    <!-- Install Button -->
                    <Button Name="BtnInstall" Cursor="Hand">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border x:Name="Bd" Background="$($t.Accent)" CornerRadius="6" Padding="24,14">
                                    <TextBlock Text="⬇️  INSTALAR MODPACK" FontSize="14" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#66BB6A"/></Trigger>
                                    <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Background" Value="#555555"/></Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                    
                    <!-- Advanced Section -->
                    <Expander Name="AdvancedExpander" Margin="0,15,0,0" Foreground="$($t.Text)">
                        <Expander.Header>
                            <TextBlock Text="Opciones Avanzadas" FontWeight="SemiBold" Foreground="$($t.Text)"/>
                        </Expander.Header>
                        <StackPanel Margin="0,10,0,0">
                            <Border Background="#0A0A0A" CornerRadius="6" Padding="10" Height="80" Margin="0,0,0,10">
                                <ScrollViewer Name="LogScroller" VerticalScrollBarVisibility="Auto">
                                    <TextBlock Name="LogText" Text="> Instalador PaisaLand v5.0" Foreground="#00DD00" FontFamily="Consolas" FontSize="10" TextWrapping="Wrap"/>
                                </ScrollViewer>
                            </Border>
                            <StackPanel Orientation="Horizontal">
                                <Button Name="BtnBackup" Content="📁 Backup" Background="Transparent" BorderBrush="$($t.Border)" BorderThickness="1" Foreground="$($t.SubText)" Padding="12,8" Cursor="Hand" Margin="0,0,10,0"/>
                                <Button Name="BtnUninstall" Content="🗑️ Desinstalar" Background="Transparent" BorderBrush="#E53935" BorderThickness="1" Foreground="#E53935" Padding="12,8" Cursor="Hand"/>
                            </StackPanel>
                        </StackPanel>
                    </Expander>
                </StackPanel>
            </ScrollViewer>

            <!-- FOOTER -->
            <Border Grid.Row="2" BorderBrush="$($t.Border)" BorderThickness="0,1,0,0" Padding="15,0">
                <Grid VerticalAlignment="Center">
                    <TextBlock Text="Powered by JharlyOk" Foreground="$($t.SubText)" FontSize="11" HorizontalAlignment="Center"/>
                    <TextBlock Name="VersionText" Text="v5.0.0" Foreground="$($t.SubText)" FontSize="11" HorizontalAlignment="Right"/>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
"@
}

# ==================== CREATE AND SHOW WINDOW ====================
function Show-Installer {
    param([bool]$Dark = $true)
    
    $xamlString = Get-InstallerXAML -Dark $Dark
    [xml]$XAML = $xamlString
    
    $Reader = New-Object System.Xml.XmlNodeReader $XAML
    $Window = [Windows.Markup.XamlReader]::Load($Reader)
    
    # Map controls
    $controls = @("DragZone","BtnTheme","BtnMinimize","BtnClose","ToggleHighSpec","ServerIndicator","ServerStatus","StatusText","ProgressBar","BtnInstall","AdvancedExpander","LogScroller","LogText","BtnBackup","BtnUninstall","VersionText")
    $UI = @{}; foreach ($n in $controls) { $c = $Window.FindName($n); if ($c) { $UI[$n] = $c } }
    
    # Helpers
    $WriteLog = { param($M); $UI.LogText.Text += "`n> $M"; $UI.LogScroller.ScrollToEnd(); [System.Windows.Forms.Application]::DoEvents() }
    $UpdateStatus = { param($M); $UI.StatusText.Text = $M; [System.Windows.Forms.Application]::DoEvents() }
    $UpdateProgress = { param($V); $UI.ProgressBar.Value = $V; [System.Windows.Forms.Application]::DoEvents() }
    
    # Events
    $UI.DragZone.Add_MouseLeftButtonDown({ $Window.DragMove() })
    $UI.BtnClose.Add_Click({ $Window.Close() })
    $UI.BtnMinimize.Add_Click({ $Window.WindowState = "Minimized" })
    
    # Theme Toggle - Restart window with new theme
    $UI.BtnTheme.Add_Click({
        $newDark = -not $script:IsDarkMode
        $script:IsDarkMode = $newDark
        Save-UserPreference -Key "DarkMode" -Value $newDark
        $Window.Close()
        Show-Installer -Dark $newDark
    }.GetNewClosure())
    
    # Save toggle preference
    $UI.ToggleHighSpec.Add_Checked({ Save-UserPreference -Key "HighSpec" -Value $true })
    $UI.ToggleHighSpec.Add_Unchecked({ Save-UserPreference -Key "HighSpec" -Value $false })
    
    # Install
    $UI.BtnInstall.Add_Click({
        $UI.BtnInstall.IsEnabled = $false; $UI.BtnBackup.IsEnabled = $false; $UI.BtnUninstall.IsEnabled = $false
        try {
            $isHigh = $UI.ToggleHighSpec.IsChecked
            $url = if ($isHigh) { $script:Config.DownloadUrlHigh } else { $script:Config.DownloadUrlLow }
            & $WriteLog "Modo: $(if ($isHigh) {'GAMA ALTA'} else {'GAMA BAJA'})"
            
            & $UpdateStatus "Verificando Minecraft..."; if (-not (Test-MinecraftInstalled)) { [System.Windows.MessageBox]::Show("No se encontró .minecraft"); return }
            & $WriteLog "Minecraft OK."; & $UpdateProgress 10
            
            & $UpdateStatus "Verificando espacio..."; if (-not (Test-DiskSpace)) { [System.Windows.MessageBox]::Show("Espacio insuficiente"); return }
            & $WriteLog "Espacio OK."; & $UpdateProgress 20
            
            $zip = "$($script:Config.TempDir)\mods.zip"; if (-not (Test-Path $script:Config.TempDir)) { New-Item -ItemType Directory -Path $script:Config.TempDir -Force | Out-Null }
            & $UpdateStatus "Descargando..."; & $WriteLog "Descargando..."
            $UI.ProgressBar.IsIndeterminate = $true; [System.Windows.Forms.Application]::DoEvents()
            (New-Object System.Net.WebClient).DownloadFile($url, $zip)
            $UI.ProgressBar.IsIndeterminate = $false; & $UpdateProgress 50; & $WriteLog "Descarga OK."
            
            & $UpdateStatus "Instalando..."; & $WriteLog "Extrayendo..."
            Install-Modpack -ZipPath $zip; & $UpdateProgress 90
            
            Clear-TempFiles; & $UpdateProgress 100
            & $UpdateStatus "¡INSTALACIÓN COMPLETADA!"; $UI.StatusText.Foreground = [System.Windows.Media.Brushes]::LimeGreen
            & $WriteLog "¡Listo! Abre el juego."
            [System.Windows.MessageBox]::Show("¡Modpack instalado!", "PaisaLand", "OK", "Information")
        } catch { & $WriteLog "ERROR: $($_.Exception.Message)"; [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)") }
        finally { $UI.BtnInstall.IsEnabled = $true; $UI.BtnBackup.IsEnabled = $true; $UI.BtnUninstall.IsEnabled = $true; $UI.ProgressBar.IsIndeterminate = $false }
    }.GetNewClosure())
    
    # Backup
    $UI.BtnBackup.Add_Click({
        try { & $UpdateStatus "Backup..."; & $WriteLog "Respaldando..."; $p = New-Backup; & $WriteLog "Backup: $p"; & $UpdateStatus "Backup listo"; [System.Windows.MessageBox]::Show("Backup en Escritorio.") }
        catch { & $WriteLog "Error: $($_.Exception.Message)" }
    }.GetNewClosure())
    
    # Uninstall
    $UI.BtnUninstall.Add_Click({
        $r = [System.Windows.MessageBox]::Show("¿Eliminar mods?", "Confirmar", "YesNo", "Warning")
        if ($r -eq "Yes") { try { & $UpdateStatus "Eliminando..."; & $WriteLog "Desinstalando..."; Remove-Modpack; & $WriteLog "OK."; & $UpdateStatus "Mods eliminados"; [System.Windows.MessageBox]::Show("Mods eliminados.") } catch { & $WriteLog "Error: $($_.Exception.Message)" } }
    }.GetNewClosure())
    
    # Init
    $Window.Add_Loaded({
        # Load prefs
        $savedHigh = Get-UserPreference -Key "HighSpec" -Default $false
        $UI.ToggleHighSpec.IsChecked = $savedHigh
        
        & $WriteLog "Verificando servidor..."
        $s = Get-ServerStatus
        if ($s.Online) { $UI.ServerIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen; $UI.ServerStatus.Text = "Servidor: $($s.Message)"; $UI.ServerStatus.Foreground = [System.Windows.Media.Brushes]::LimeGreen }
        else { $UI.ServerIndicator.Fill = [System.Windows.Media.Brushes]::Red; $UI.ServerStatus.Text = "Servidor: $($s.Message)" }
        
        $UI.VersionText.Text = "v$($script:Config.Version)"
        & $WriteLog "Instalador listo."
    }.GetNewClosure())
    
    [void]$Window.ShowDialog()
}

# ==================== START ====================
$script:IsDarkMode = Get-UserPreference -Key "DarkMode" -Default $true
Show-Installer -Dark $script:IsDarkMode
