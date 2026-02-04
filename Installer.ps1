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

# ==================== XAML UI ====================
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PaisaLand Installer" Height="520" Width="480"
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <!-- DARK THEME (Default) -->
        <Color x:Key="BgColor">#2D2D30</Color>
        <Color x:Key="CardColor">#1E1E1E</Color>
        <Color x:Key="TextColor">#FFFFFF</Color>
        <Color x:Key="SubTextColor">#888888</Color>
        <Color x:Key="BorderColor">#404040</Color>
        <Color x:Key="AccentColor">#4CAF50</Color>
        
        <SolidColorBrush x:Key="BgBrush" Color="{DynamicResource BgColor}"/>
        <SolidColorBrush x:Key="CardBrush" Color="{DynamicResource CardColor}"/>
        <SolidColorBrush x:Key="TextBrush" Color="{DynamicResource TextColor}"/>
        <SolidColorBrush x:Key="SubTextBrush" Color="{DynamicResource SubTextColor}"/>
        <SolidColorBrush x:Key="BorderBrush" Color="{DynamicResource BorderColor}"/>
        <SolidColorBrush x:Key="AccentBrush" Color="{DynamicResource AccentColor}"/>
        
        <!-- ICON BUTTON -->
        <Style x:Key="IconBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{DynamicResource SubTextBrush}"/>
            <Setter Property="Width" Value="36"/><Setter Property="Height" Value="36"/><Setter Property="FontSize" Value="16"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="4">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#44FFFFFF"/></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <!-- CLOSE BUTTON -->
        <Style x:Key="CloseBtn" TargetType="Button" BasedOn="{StaticResource IconBtn}">
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Bd" Background="Transparent" CornerRadius="4">
                    <TextBlock Text="✕" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="{DynamicResource SubTextBrush}" FontWeight="Bold"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#E53935"/></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <!-- TOGGLE SWITCH -->
        <Style x:Key="ToggleSwitch" TargetType="CheckBox">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="CheckBox">
                <Grid>
                    <Border x:Name="Track" Width="50" Height="26" CornerRadius="13" Background="#555555"/>
                    <Border x:Name="Thumb" Width="22" Height="22" CornerRadius="11" Background="White" HorizontalAlignment="Left" Margin="2,0,0,0">
                        <Border.RenderTransform><TranslateTransform x:Name="ThumbTranslate" X="0"/></Border.RenderTransform>
                    </Border>
                </Grid>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsChecked" Value="True">
                        <Setter TargetName="Track" Property="Background" Value="{DynamicResource AccentBrush}"/>
                        <Setter TargetName="ThumbTranslate" Property="X" Value="24"/>
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <!-- PRIMARY BUTTON -->
        <Style x:Key="PrimaryBtn" TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource AccentBrush}"/><Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="6" Padding="24,12">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#66BB6A"/></Trigger>
                    <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Background" Value="#555"/><Setter Property="Foreground" Value="#888"/></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <!-- SECONDARY BUTTON -->
        <Style x:Key="SecondaryBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{DynamicResource SubTextBrush}"/>
            <Setter Property="FontSize" Value="12"/><Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
                <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="4" Padding="12,8" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#22FFFFFF"/><Setter Property="Foreground" Value="{DynamicResource TextBrush}"/></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
        
        <!-- EXPANDER -->
        <Style x:Key="ExpanderStyle" TargetType="Expander">
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}"/>
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Expander">
                <Border BorderBrush="{DynamicResource BorderBrush}" BorderThickness="0,1,0,0">
                    <StackPanel>
                        <ToggleButton x:Name="HeaderSite" IsChecked="{Binding IsExpanded, RelativeSource={RelativeSource TemplatedParent}}" Cursor="Hand"
                                      Background="Transparent" BorderThickness="0" Padding="0,15">
                            <ToggleButton.Template><ControlTemplate TargetType="ToggleButton">
                                <Border Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                                    <Grid>
                                        <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                                        <TextBlock x:Name="Arrow" Text="▼" HorizontalAlignment="Right" Foreground="{DynamicResource SubTextBrush}" FontSize="10">
                                            <TextBlock.RenderTransform><RotateTransform x:Name="ArrowRotate" Angle="0" CenterX="5" CenterY="5"/></TextBlock.RenderTransform>
                                        </TextBlock>
                                    </Grid>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsChecked" Value="True"><Setter TargetName="ArrowRotate" Property="Angle" Value="180"/></Trigger>
                                    <Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#11FFFFFF"/></Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate></ToggleButton.Template>
                            <TextBlock Text="{TemplateBinding Header}" FontWeight="SemiBold" Foreground="{DynamicResource TextBrush}"/>
                        </ToggleButton>
                        <ContentPresenter x:Name="ExpandSite" Visibility="Collapsed"/>
                    </StackPanel>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsExpanded" Value="True"><Setter TargetName="ExpandSite" Property="Visibility" Value="Visible"/></Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate></Setter.Value></Setter>
        </Style>
    </Window.Resources>

    <Border CornerRadius="10" Background="{DynamicResource BgBrush}" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="1">
        <Border.Effect><DropShadowEffect Color="Black" BlurRadius="20" ShadowDepth="0" Opacity="0.5"/></Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="50"/>  <!-- Header -->
                <RowDefinition Height="*"/>   <!-- Content -->
                <RowDefinition Height="50"/>  <!-- Footer -->
            </Grid.RowDefinitions>

            <!-- HEADER -->
            <Grid Grid.Row="0" Name="DragZone" Background="Transparent">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="15,0,0,0">
                    <TextBlock Text="🎮" FontSize="20" VerticalAlignment="Center"/>
                    <TextBlock Text=" PAISA" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource TextBrush}" VerticalAlignment="Center"/>
                    <TextBlock Text="LAND" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource AccentBrush}" VerticalAlignment="Center"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,5,0">
                    <Button Name="BtnTheme" Content="☀️" Style="{StaticResource IconBtn}" ToolTip="Cambiar Tema"/>
                    <Button Name="BtnMinimize" Content="─" Style="{StaticResource IconBtn}"/>
                    <Button Name="BtnClose" Style="{StaticResource CloseBtn}"/>
                </StackPanel>
            </Grid>

            <!-- CONTENT -->
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="20,10">
                <StackPanel>
                    <!-- Main Toggle -->
                    <Border Background="{DynamicResource CardBrush}" CornerRadius="8" Padding="20" Margin="0,0,0,15">
                        <Grid>
                            <StackPanel>
                                <TextBlock Text="Activar Gama Alta" FontSize="16" FontWeight="SemiBold" Foreground="{DynamicResource TextBrush}"/>
                                <TextBlock Text="Incluye Shaders, Texturas HD y efectos visuales avanzados." FontSize="12" Foreground="{DynamicResource SubTextBrush}" Margin="0,8,0,0" TextWrapping="Wrap"/>
                            </StackPanel>
                            <CheckBox Name="ToggleHighSpec" Style="{StaticResource ToggleSwitch}" HorizontalAlignment="Right" VerticalAlignment="Top"/>
                        </Grid>
                    </Border>
                    
                    <!-- Server Status -->
                    <Border Background="{DynamicResource CardBrush}" CornerRadius="8" Padding="15" Margin="0,0,0,15">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal">
                                <Ellipse Name="ServerIndicator" Width="10" Height="10" Fill="#E53935"/>
                                <TextBlock Name="ServerStatus" Text="Servidor: Verificando..." Foreground="{DynamicResource SubTextBrush}" FontSize="12" Margin="8,0,0,0"/>
                            </StackPanel>
                            <TextBlock Name="StatusText" Text="Listo para instalar" Foreground="{DynamicResource TextBrush}" FontSize="14" Margin="0,10,0,0"/>
                            <ProgressBar Name="ProgressBar" Height="4" Background="#333" Foreground="{DynamicResource AccentBrush}" BorderThickness="0" Margin="0,10,0,0" Value="0"/>
                        </StackPanel>
                    </Border>
                    
                    <!-- Install Button -->
                    <Button Name="BtnInstall" Content="⬇️  INSTALAR MODPACK" Style="{StaticResource PrimaryBtn}" HorizontalAlignment="Stretch"/>
                    
                    <!-- Advanced Section -->
                    <Expander Name="AdvancedExpander" Header="Opciones Avanzadas" Style="{StaticResource ExpanderStyle}" Margin="0,15,0,0">
                        <StackPanel Margin="0,10,0,0">
                            <Border Background="#0A0A0A" CornerRadius="6" Padding="10" Height="80" Margin="0,0,0,10">
                                <ScrollViewer Name="LogScroller" VerticalScrollBarVisibility="Auto">
                                    <TextBlock Name="LogText" Text="> Instalador PaisaLand v5.0" Foreground="#00DD00" FontFamily="Consolas" FontSize="10" TextWrapping="Wrap"/>
                                </ScrollViewer>
                            </Border>
                            <StackPanel Orientation="Horizontal">
                                <Button Name="BtnBackup" Content="📁 Backup" Style="{StaticResource SecondaryBtn}" Margin="0,0,10,0"/>
                                <Button Name="BtnUninstall" Content="🗑️ Desinstalar" Style="{StaticResource SecondaryBtn}"/>
                            </StackPanel>
                        </StackPanel>
                    </Expander>
                </StackPanel>
            </ScrollViewer>

            <!-- FOOTER -->
            <Border Grid.Row="2" BorderBrush="{DynamicResource BorderBrush}" BorderThickness="0,1,0,0" Padding="15,0">
                <Grid VerticalAlignment="Center">
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Left">
                        <TextBlock Text="💬" FontSize="14" Cursor="Hand" ToolTip="Discord" Margin="0,0,10,0"/>
                        <TextBlock Text="🐙" FontSize="14" Cursor="Hand" ToolTip="GitHub"/>
                    </StackPanel>
                    <TextBlock Text="Powered by JharlyOk" Foreground="{DynamicResource SubTextBrush}" FontSize="11" HorizontalAlignment="Center"/>
                    <TextBlock Name="VersionText" Text="v5.0.0" Foreground="{DynamicResource SubTextBrush}" FontSize="11" HorizontalAlignment="Right"/>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

# ==================== CARGAR UI ====================
$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$controls = @("DragZone","BtnTheme","BtnMinimize","BtnClose","ToggleHighSpec","ServerIndicator","ServerStatus","StatusText","ProgressBar","BtnInstall","AdvancedExpander","LogScroller","LogText","BtnBackup","BtnUninstall","VersionText")
$UI = @{}; foreach ($n in $controls) { $c = $Window.FindName($n); if ($c) { $UI[$n] = $c } }

# ==================== THEME SYSTEM ====================
function Set-Theme {
    param([bool]$Dark)
    $script:IsDarkMode = $Dark
    if ($Dark) {
        $Window.Resources["BgColor"] = [System.Windows.Media.Color]::FromRgb(45, 45, 48)
        $Window.Resources["CardColor"] = [System.Windows.Media.Color]::FromRgb(30, 30, 30)
        $Window.Resources["TextColor"] = [System.Windows.Media.Color]::FromRgb(255, 255, 255)
        $Window.Resources["SubTextColor"] = [System.Windows.Media.Color]::FromRgb(136, 136, 136)
        $Window.Resources["BorderColor"] = [System.Windows.Media.Color]::FromRgb(64, 64, 64)
        $UI.BtnTheme.Content = "☀️"
    } else {
        $Window.Resources["BgColor"] = [System.Windows.Media.Color]::FromRgb(255, 255, 255)
        $Window.Resources["CardColor"] = [System.Windows.Media.Color]::FromRgb(245, 245, 245)
        $Window.Resources["TextColor"] = [System.Windows.Media.Color]::FromRgb(26, 26, 26)
        $Window.Resources["SubTextColor"] = [System.Windows.Media.Color]::FromRgb(102, 102, 102)
        $Window.Resources["BorderColor"] = [System.Windows.Media.Color]::FromRgb(224, 224, 224)
        $UI.BtnTheme.Content = "🌙"
    }
    Save-UserPreference -Key "DarkMode" -Value $Dark
}

# ==================== HELPERS ====================
function Write-Log { param([string]$M); $UI.LogText.Text += "`n> $M"; $UI.LogScroller.ScrollToEnd(); [System.Windows.Forms.Application]::DoEvents() }
function Update-Status { param([string]$M); $UI.StatusText.Text = $M; [System.Windows.Forms.Application]::DoEvents() }
function Update-Progress { param([int]$V); $UI.ProgressBar.Value = $V; [System.Windows.Forms.Application]::DoEvents() }

# ==================== INIT ====================
function Initialize-Installer {
    # Theme
    $savedDark = Get-UserPreference -Key "DarkMode" -Default $true
    Set-Theme -Dark $savedDark
    
    # High Spec Toggle
    $savedHigh = Get-UserPreference -Key "HighSpec" -Default $false
    $UI.ToggleHighSpec.IsChecked = $savedHigh
    
    # Server
    Write-Log "Verificando servidor..."
    $s = Get-ServerStatus
    if ($s.Online) { $UI.ServerIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen; $UI.ServerStatus.Text = "Servidor: $($s.Message)"; $UI.ServerStatus.Foreground = [System.Windows.Media.Brushes]::LimeGreen }
    else { $UI.ServerIndicator.Fill = [System.Windows.Media.Brushes]::Red; $UI.ServerStatus.Text = "Servidor: $($s.Message)" }
    
    $UI.VersionText.Text = "v$($script:Config.Version)"
    Write-Log "Instalador listo."
}

# ==================== EVENTOS ====================
$UI.DragZone.Add_MouseLeftButtonDown({ $Window.DragMove() })
$UI.BtnClose.Add_Click({ $Window.Close() })
$UI.BtnMinimize.Add_Click({ $Window.WindowState = "Minimized" })
$UI.BtnTheme.Add_Click({ Set-Theme -Dark (-not $script:IsDarkMode) })

$UI.ToggleHighSpec.Add_Checked({ Save-UserPreference -Key "HighSpec" -Value $true })
$UI.ToggleHighSpec.Add_Unchecked({ Save-UserPreference -Key "HighSpec" -Value $false })

$UI.BtnInstall.Add_Click({
    $UI.BtnInstall.IsEnabled = $false; $UI.BtnBackup.IsEnabled = $false; $UI.BtnUninstall.IsEnabled = $false
    try {
        $isHigh = $UI.ToggleHighSpec.IsChecked
        $url = if ($isHigh) { $script:Config.DownloadUrlHigh } else { $script:Config.DownloadUrlLow }
        Write-Log "Modo: $(if ($isHigh) {'GAMA ALTA'} else {'GAMA BAJA'})"
        
        Update-Status "Verificando Minecraft..."; if (-not (Test-MinecraftInstalled)) { [System.Windows.MessageBox]::Show("No se encontró .minecraft"); return }
        Write-Log "Minecraft OK."; Update-Progress 10
        
        Update-Status "Verificando espacio..."; if (-not (Test-DiskSpace)) { [System.Windows.MessageBox]::Show("Espacio insuficiente"); return }
        Write-Log "Espacio OK."; Update-Progress 20
        
        $zip = "$($script:Config.TempDir)\mods.zip"; if (-not (Test-Path $script:Config.TempDir)) { New-Item -ItemType Directory -Path $script:Config.TempDir -Force | Out-Null }
        Update-Status "Descargando..."; Write-Log "Descargando..."
        $UI.ProgressBar.IsIndeterminate = $true; [System.Windows.Forms.Application]::DoEvents()
        (New-Object System.Net.WebClient).DownloadFile($url, $zip)
        $UI.ProgressBar.IsIndeterminate = $false; Update-Progress 50; Write-Log "Descarga OK."
        
        Update-Status "Instalando..."; Write-Log "Extrayendo..."
        Install-Modpack -ZipPath $zip; Update-Progress 90
        
        Clear-TempFiles; Update-Progress 100
        Update-Status "¡INSTALACIÓN COMPLETADA!"; $UI.StatusText.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        Write-Log "¡Listo! Abre el juego."
        [System.Windows.MessageBox]::Show("¡Modpack instalado!", "PaisaLand", "OK", "Information")
    } catch { Write-Log "ERROR: $($_.Exception.Message)"; [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)") }
    finally { $UI.BtnInstall.IsEnabled = $true; $UI.BtnBackup.IsEnabled = $true; $UI.BtnUninstall.IsEnabled = $true; $UI.ProgressBar.IsIndeterminate = $false }
})

$UI.BtnBackup.Add_Click({
    try { Update-Status "Backup..."; Write-Log "Respaldando..."; $p = New-Backup; Write-Log "Backup: $p"; Update-Status "Backup listo"; [System.Windows.MessageBox]::Show("Backup en Escritorio.") }
    catch { Write-Log "Error: $($_.Exception.Message)" }
})

$UI.BtnUninstall.Add_Click({
    $r = [System.Windows.MessageBox]::Show("¿Eliminar mods?", "Confirmar", "YesNo", "Warning")
    if ($r -eq "Yes") { try { Update-Status "Eliminando..."; Write-Log "Desinstalando..."; Remove-Modpack; Write-Log "OK."; Update-Status "Mods eliminados"; [System.Windows.MessageBox]::Show("Mods eliminados.") } catch { Write-Log "Error: $($_.Exception.Message)" } }
})

# ==================== INICIAR ====================
$Window.Add_Loaded({ Initialize-Installer })
[void]$Window.ShowDialog()
