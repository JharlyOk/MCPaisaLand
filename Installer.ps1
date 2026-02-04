# ==============================================================================================
# PaisaLand Installer v5.0.0 - WOOTING-INSPIRED DESIGN
# Compatible: Windows PowerShell 5.1+, irm ... | iex
# ==============================================================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ==================== CONFIG ====================
$script:Config = @{
    Version = "5.0.0"
    DownloadUrlLow = "https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=1"
    DownloadUrlHigh = "https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=1"
    ServerIP = "play.paisaland.com"
    ServerPort = 25565
    MinecraftPath = "$env:APPDATA\.minecraft"
    TempDir = "$env:TEMP\PaisaLandInstaller"
    PrefsFile = "$env:APPDATA\PaisaLand\prefs.txt"
    ManagedFolders = @("mods", "config", "shaderpacks", "resourcepacks", "emotes", "options.txt", "servers.dat")
}

$script:IsDarkMode = $true
$script:IsHighSpec = $false

# ==================== FUNCTIONS ====================
function Test-MinecraftInstalled { return (Test-Path $script:Config.MinecraftPath) }
function Test-DiskSpace { $drive = (Get-Item $env:APPDATA).PSDrive.Name; return ((Get-PSDrive $drive).Free / 1MB) -ge 500 }

function Get-ServerStatus {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ar = $tcp.BeginConnect($script:Config.ServerIP, $script:Config.ServerPort, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne(2000, $false) -and $tcp.Connected) { $tcp.Close(); return @{ Online = $true; Msg = "En Línea" } }
        return @{ Online = $false; Msg = "Fuera de Línea" }
    } catch { return @{ Online = $false; Msg = "Error" } }
}

function Save-Pref { param($K,$V); $dir = Split-Path $script:Config.PrefsFile -Parent; if (-not (Test-Path $dir)) { mkdir $dir -Force | Out-Null }; "$K=$V" | Out-File -Append $script:Config.PrefsFile }
function Get-Pref { param($K,$D=$null); if (Test-Path $script:Config.PrefsFile) { $lines = Get-Content $script:Config.PrefsFile; foreach($l in $lines) { if ($l -like "$K=*") { return $l.Split("=")[1] } } }; return $D }

function Install-Modpack { param($ZipPath)
    $extract = "$($script:Config.TempDir)\ex"
    $modsPath = "$($script:Config.MinecraftPath)\mods"
    if (Test-Path $modsPath) { Remove-Item "$modsPath\*" -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $extract -Force
    $items = Get-ChildItem -Path $extract
    $src = if ($items.Count -eq 1 -and $items[0].PSIsContainer) { $items[0].FullName } else { $extract }
    Copy-Item -Path "$src\*" -Destination $script:Config.MinecraftPath -Recurse -Force
}

function New-Backup {
    $dir = "$env:USERPROFILE\Desktop\PaisaLand_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    mkdir $dir -Force | Out-Null
    foreach ($item in $script:Config.ManagedFolders) { $p = "$($script:Config.MinecraftPath)\$item"; if (Test-Path $p) { Copy-Item -Path $p -Destination $dir -Recurse } }
    return $dir
}

function Remove-Modpack { foreach ($item in $script:Config.ManagedFolders) { $p = "$($script:Config.MinecraftPath)\$item"; if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue } } }
function Clear-TempFiles { if (Test-Path $script:Config.TempDir) { Remove-Item $script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue } }

# ==================== XAML ====================
function Get-XAML {
    param([bool]$Dark = $true)
    $bg = if($Dark){"#2D2D30"}else{"#FFFFFF"}
    $card = if($Dark){"#1E1E1E"}else{"#F5F5F5"}
    $txt = if($Dark){"#FFFFFF"}else{"#1A1A1A"}
    $sub = if($Dark){"#888888"}else{"#666666"}
    $bdr = if($Dark){"#404040"}else{"#E0E0E0"}
    $acc = "#4CAF50"
    $themeIcon = if($Dark){"☀"}else{"🌙"}

    return @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PaisaLand" Height="480" Width="440"
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">
    <Border CornerRadius="10" Background="$bg" BorderBrush="$bdr" BorderThickness="1">
        <Border.Effect><DropShadowEffect Color="Black" BlurRadius="15" ShadowDepth="0" Opacity="0.4"/></Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="45"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="40"/>
            </Grid.RowDefinitions>

            <!-- HEADER -->
            <Border Grid.Row="0" Name="DragZone" Background="Transparent">
                <Grid>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="12,0,0,0">
                        <TextBlock Text="🎮 " FontSize="16"/>
                        <TextBlock Text="PAISA" FontSize="14" FontWeight="Bold" Foreground="$txt"/>
                        <TextBlock Text="LAND" FontSize="14" FontWeight="Bold" Foreground="$acc"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,5,0">
                        <Button Name="BtnTheme" Content="$themeIcon" Width="32" Height="32" Background="Transparent" BorderThickness="0" Foreground="$sub" FontSize="14" Cursor="Hand" ToolTip="Cambiar tema"/>
                        <Button Name="BtnMin" Content="─" Width="32" Height="32" Background="Transparent" BorderThickness="0" Foreground="$sub" FontSize="12" Cursor="Hand"/>
                        <Button Name="BtnClose" Content="✕" Width="32" Height="32" Background="Transparent" BorderThickness="0" Foreground="$sub" FontSize="12" FontWeight="Bold" Cursor="Hand"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- CONTENT -->
            <StackPanel Grid.Row="1" Margin="15,5,15,5">
                <!-- Toggle Card -->
                <Border Background="$card" CornerRadius="8" Padding="15" Margin="0,0,0,10">
                    <Grid>
                        <StackPanel>
                            <TextBlock Text="Gama Alta" FontSize="14" FontWeight="SemiBold" Foreground="$txt"/>
                            <TextBlock Text="Shaders + Texturas HD" FontSize="11" Foreground="$sub" Margin="0,4,0,0"/>
                        </StackPanel>
                        <CheckBox Name="ChkHigh" HorizontalAlignment="Right" VerticalAlignment="Center" Cursor="Hand"/>
                    </Grid>
                </Border>

                <!-- Status Card -->
                <Border Background="$card" CornerRadius="8" Padding="12" Margin="0,0,0,10">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <Ellipse Name="ServerDot" Width="8" Height="8" Fill="#E53935"/>
                            <TextBlock Name="ServerTxt" Text="Servidor: ..." Foreground="$sub" FontSize="11" Margin="6,0,0,0"/>
                        </StackPanel>
                        <TextBlock Name="StatusTxt" Text="Listo" Foreground="$txt" FontSize="13" Margin="0,8,0,0"/>
                        <ProgressBar Name="Progress" Height="3" Background="#333" Foreground="$acc" BorderThickness="0" Margin="0,8,0,0" Value="0"/>
                    </StackPanel>
                </Border>

                <!-- Install Button -->
                <Button Name="BtnInstall" Height="42" Background="$acc" Foreground="White" FontSize="13" FontWeight="SemiBold" Cursor="Hand" BorderThickness="0">
                    <Button.Content>⬇  INSTALAR</Button.Content>
                </Button>

                <!-- Log -->
                <Border Background="#0A0A0A" CornerRadius="5" Padding="8" Margin="0,10,0,0" Height="70">
                    <ScrollViewer Name="LogScroll" VerticalScrollBarVisibility="Auto">
                        <TextBlock Name="LogTxt" Text="> PaisaLand v5.0" Foreground="#00DD00" FontFamily="Consolas" FontSize="10" TextWrapping="Wrap"/>
                    </ScrollViewer>
                </Border>

                <!-- Secondary Buttons -->
                <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                    <Button Name="BtnBackup" Content="📁 Backup" Background="Transparent" BorderBrush="$bdr" BorderThickness="1" Foreground="$sub" Padding="10,6" Cursor="Hand" Margin="0,0,8,0"/>
                    <Button Name="BtnUninstall" Content="🗑 Eliminar" Background="Transparent" BorderBrush="#E53935" BorderThickness="1" Foreground="#E53935" Padding="10,6" Cursor="Hand"/>
                </StackPanel>
            </StackPanel>

            <!-- FOOTER -->
            <Border Grid.Row="2" BorderBrush="$bdr" BorderThickness="0,1,0,0" Padding="12,0">
                <Grid VerticalAlignment="Center">
                    <TextBlock Text="by JharlyOk" Foreground="$sub" FontSize="10" HorizontalAlignment="Center"/>
                    <TextBlock Text="v5.0.0" Foreground="$sub" FontSize="10" HorizontalAlignment="Right"/>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
"@
}

# ==================== SHOW WINDOW ====================
function Show-App {
    param([bool]$Dark = $true)
    
    $xaml = Get-XAML -Dark $Dark
    [xml]$x = $xaml
    $reader = New-Object System.Xml.XmlNodeReader $x
    $win = [Windows.Markup.XamlReader]::Load($reader)
    
    # Controls
    $dragZone = $win.FindName("DragZone")
    $btnTheme = $win.FindName("BtnTheme")
    $btnMin = $win.FindName("BtnMin")
    $btnClose = $win.FindName("BtnClose")
    $chkHigh = $win.FindName("ChkHigh")
    $serverDot = $win.FindName("ServerDot")
    $serverTxt = $win.FindName("ServerTxt")
    $statusTxt = $win.FindName("StatusTxt")
    $progress = $win.FindName("Progress")
    $btnInstall = $win.FindName("BtnInstall")
    $logScroll = $win.FindName("LogScroll")
    $logTxt = $win.FindName("LogTxt")
    $btnBackup = $win.FindName("BtnBackup")
    $btnUninstall = $win.FindName("BtnUninstall")
    
    # Helpers
    $log = { param($m); $logTxt.Text += "`n> $m"; $logScroll.ScrollToEnd(); [System.Windows.Forms.Application]::DoEvents() }
    $status = { param($m); $statusTxt.Text = $m; [System.Windows.Forms.Application]::DoEvents() }
    $prog = { param($v); $progress.Value = $v; [System.Windows.Forms.Application]::DoEvents() }
    
    # Window Events
    $dragZone.Add_MouseLeftButtonDown({ $win.DragMove() })
    $btnClose.Add_Click({ $win.Close() })
    $btnMin.Add_Click({ $win.WindowState = "Minimized" })
    
    # Theme Toggle
    $btnTheme.Add_Click({
        $script:IsDarkMode = -not $script:IsDarkMode
        $win.Close()
        Show-App -Dark $script:IsDarkMode
    }.GetNewClosure())
    
    # Install
    $btnInstall.Add_Click({
        $btnInstall.IsEnabled = $false
        try {
            $url = if ($chkHigh.IsChecked) { $script:Config.DownloadUrlHigh } else { $script:Config.DownloadUrlLow }
            & $log "Modo: $(if($chkHigh.IsChecked){'ALTA'}else{'BAJA'})"
            
            & $status "Verificando..."; if (-not (Test-MinecraftInstalled)) { [System.Windows.MessageBox]::Show("No se encontró .minecraft"); return }
            & $log "Minecraft OK"; & $prog 10
            
            & $status "Espacio..."; if (-not (Test-DiskSpace)) { [System.Windows.MessageBox]::Show("Sin espacio"); return }
            & $log "Espacio OK"; & $prog 20
            
            $zip = "$($script:Config.TempDir)\m.zip"; if (-not (Test-Path $script:Config.TempDir)) { mkdir $script:Config.TempDir -Force | Out-Null }
            & $status "Descargando..."; & $log "Descargando..."
            $progress.IsIndeterminate = $true; [System.Windows.Forms.Application]::DoEvents()
            (New-Object System.Net.WebClient).DownloadFile($url, $zip)
            $progress.IsIndeterminate = $false; & $prog 50; & $log "OK"
            
            & $status "Instalando..."; & $log "Extrayendo..."
            Install-Modpack -ZipPath $zip; & $prog 90
            
            Clear-TempFiles; & $prog 100
            & $status "¡LISTO!"; $statusTxt.Foreground = [System.Windows.Media.Brushes]::LimeGreen
            & $log "Completado!"
            [System.Windows.MessageBox]::Show("¡Instalado!", "PaisaLand")
        } catch { & $log "ERROR: $($_.Exception.Message)"; [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)") }
        finally { $btnInstall.IsEnabled = $true; $progress.IsIndeterminate = $false }
    }.GetNewClosure())
    
    # Backup
    $btnBackup.Add_Click({
        try { & $status "Backup..."; & $log "Creando..."; $p = New-Backup; & $log "OK: $p"; & $status "Backup OK"; [System.Windows.MessageBox]::Show("Backup creado") }
        catch { & $log "Error: $($_.Exception.Message)" }
    }.GetNewClosure())
    
    # Uninstall
    $btnUninstall.Add_Click({
        $r = [System.Windows.MessageBox]::Show("¿Eliminar mods?", "Confirmar", "YesNo", "Warning")
        if ($r -eq "Yes") { try { & $status "Eliminando..."; Remove-Modpack; & $log "Eliminado"; & $status "OK"; [System.Windows.MessageBox]::Show("Mods eliminados") } catch { & $log "Error" } }
    }.GetNewClosure())
    
    # Init
    $win.Add_Loaded({
        & $log "Verificando servidor..."
        $s = Get-ServerStatus
        if ($s.Online) { $serverDot.Fill = [System.Windows.Media.Brushes]::LimeGreen; $serverTxt.Text = "Servidor: $($s.Msg)"; $serverTxt.Foreground = [System.Windows.Media.Brushes]::LimeGreen }
        else { $serverDot.Fill = [System.Windows.Media.Brushes]::Red; $serverTxt.Text = "Servidor: $($s.Msg)" }
        & $log "Listo"
    }.GetNewClosure())
    
    [void]$win.ShowDialog()
}

# ==================== START ====================
$script:IsDarkMode = $true
Show-App -Dark $script:IsDarkMode
