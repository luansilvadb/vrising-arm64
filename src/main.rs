mod config;

use anyhow::{Context, Result};
use clap::Parser;
use config::LauncherConfig;
use log::{debug, info, warn};
use std::fs;
use std::path::Path;
use std::process::{Child, Command};
use std::time::Duration;

// Imports específicos de Unix
#[cfg(unix)]
use std::os::unix::fs::symlink;
#[cfg(unix)]
use std::os::unix::process::CommandExt;

// ============================================================================
// CONSTANTES - IDÊNTICAS AO start.sh ORIGINAL
// ============================================================================

const BANNER: &str = r#"
┌─────────────────────────────────────────────────────────────────────────┐
│          V Rising Dedicated Server - ARM64 (Rust Edition)              │
│              Based on luansilvadb/vrising-arm64                         │
│                    Using FEXInterpreter + Wine                          │
└─────────────────────────────────────────────────────────────────────────┘
"#;

// ============================================================================
// LOGGING COM CORES - IDÊNTICO AO start.sh
// ============================================================================

fn section(title: &str) {
    println!("\n\x1b[1;36m━━━ {} ━━━\x1b[0m", title);
}

fn log_ok(msg: &str) {
    let ts = chrono::Local::now().format("%H:%M:%S");
    println!("\x1b[0;90m[{}]\x1b[0m \x1b[1;32m[OK]\x1b[0m {}", ts, msg);
}

fn log_fail(msg: &str) {
    let ts = chrono::Local::now().format("%H:%M:%S");
    eprintln!("\x1b[0;90m[{}]\x1b[0m \x1b[1;31m[FAIL]\x1b[0m {}", ts, msg);
}

// ============================================================================
// MAIN - FLUXO PRINCIPAL IDÊNTICO AO start.sh
// ============================================================================

fn main() -> Result<()> {
    // Inicializar logger
    env_logger::init_from_env(env_logger::Env::default().default_filter_or("info"));

    // Parse configuração
    let config = LauncherConfig::parse();

    // Banner
    println!("{}", BANNER);
    section("Server Configuration");
    info!("Server Name: {}", config.server_name);
    info!("Save Name: {}", config.save_name);
    info!(
        "Game Port: {} | Query Port: {}",
        config.game_port, config.query_port
    );
    info!("Server Dir: {}", config.server_dir.display());
    info!("Debug Mode: {}", config.debug);

    // 1. Setup Environment (export das variáveis globais)
    setup_environment(&config);

    // 2. Setup Wine/FEX (verificar binários e iniciar Xvfb)
    let _xvfb_handle = setup_wine(&config)?;

    // 3. Install/Update Server via SteamCMD
    install_or_update_server(&config)?;

    // 4. Configure Server Settings
    config.configure_settings()?;

    // 5. Dump environment (debug)
    dump_environment(&config);

    // 6. Pre-launch checks
    pre_launch_checks(&config)?;

    // 7. Launch Server
    section("Launching Server");
    info!(
        "Command: FEXInterpreter {} VRisingServer.exe",
        config.wine_bin.display()
    );
    info!("Log file: NUL (Performance Mode)");
    info!("Press Ctrl+C to stop the server");
    println!(
        "\x1b[0;90m{}\x1b[0m",
        "────────────────────────────────────────────────────────────────"
    );

    start_server(&config)?;

    Ok(())
}

// ============================================================================
// SETUP ENVIRONMENT - IDÊNTICO AO start.sh
// ============================================================================

fn setup_environment(config: &LauncherConfig) {
    section("Environment Setup");

    // Variáveis do FEX (Respeitar ENV do Docker se existir)
    if std::env::var("FEX_TSOENABLE").is_err() {
        std::env::set_var("FEX_TSOENABLE", "0");
    }

    // Unity GC settings
    std::env::set_var("GC_DONT_GC", "0");
    if std::env::var("UNITY_GC_MODE").is_err() {
        std::env::set_var("UNITY_GC_MODE", "incremental");
    }

    // Wine TCP buffer
    if std::env::var("WINE_TCP_BUFFER_SIZE").is_err() {
        std::env::set_var("WINE_TCP_BUFFER_SIZE", "65536");
    }

    // Wine prefix e arch
    std::env::set_var(
        "WINEPREFIX",
        config.wineprefix.to_str().unwrap_or("/data/wineprefix"),
    );
    std::env::set_var("WINEARCH", "win64");
    std::env::set_var("DISPLAY", ":0");

    // Debug mode
    if config.is_debug() {
        std::env::set_var("WINEDEBUG", "+loaddll,+module,+relay");
        info!("Debug mode ENABLED (Verbose logging)");
    } else {
        std::env::set_var("WINEDEBUG", "-all");
    }

    // Wine DLL overrides
    std::env::set_var(
        "WINEDLLOVERRIDES",
        "mscoree,mshtml=;winemenubuilder.exe=d;winhttp=n,b;winealsa.drv=d;winepulse.drv=d;openal32=d;xaudio2_7=d",
    );

    log_ok("Environment variables configured");
}

// ============================================================================
// SETUP WINE/FEX - IDÊNTICO AO start.sh setup_wine()
// ============================================================================

fn setup_wine(config: &LauncherConfig) -> Result<Option<Child>> {
    section("Wine/FEX Configuration");

    // Verificar FEXInterpreter
    let fex_check = Command::new("which").arg("FEXInterpreter").output();

    match fex_check {
        Ok(output) if output.status.success() => {
            let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
            log_ok(&format!("FEXInterpreter found: {}", path));
        }
        _ => {
            log_fail("FEXInterpreter not found in PATH");
            anyhow::bail!("FEXInterpreter não encontrado. Verifique a instalação do FEX-Emu.");
        }
    }

    // Verificar Wine binary
    if config.wine_bin.exists() && config.wine_bin.is_file() {
        log_ok(&format!("Wine binary: {}", config.wine_bin.display()));
    } else {
        log_fail(&format!(
            "Wine binary not found or not executable: {}",
            config.wine_bin.display()
        ));
        anyhow::bail!("Wine não encontrado em {}", config.wine_bin.display());
    }

    // Iniciar Xvfb
    info!("Starting Xvfb virtual display...");
    let _ = fs::remove_file("/tmp/.X0-lock");

    let xvfb = Command::new("Xvfb")
        .args([":0", "-screen", "0", "1024x768x16"])
        .spawn()
        .context("Falha ao iniciar Xvfb")?;

    let xvfb_pid = xvfb.id();

    // Aguardar socket
    let mut ready = false;
    for _ in 0..50 {
        if Path::new("/tmp/.X11-unix/X0").exists() {
            ready = true;
            break;
        }
        std::thread::sleep(Duration::from_millis(100));
    }

    if ready {
        log_ok(&format!("Xvfb started (PID: {})", xvfb_pid));
    } else {
        warn!("Xvfb socket not found after 5s - continuing anyway");
    }

    // Inicializar Wine prefix se não existir
    let drive_c = config.wineprefix.join("drive_c");
    if !drive_c.is_dir() {
        section("Wine Prefix Initialization");
        info!("Creating Wine prefix at {}...", config.wineprefix.display());
        fs::create_dir_all(&config.wineprefix)?;

        // FEXInterpreter wine64 wineboot --init
        let status = Command::new("timeout")
            .args(["60", "FEXInterpreter"])
            .arg(&config.wine_bin)
            .arg("wineboot")
            .arg("--init")
            .env("WINEPREFIX", &config.wineprefix)
            .env("WINEARCH", "win64")
            .env("DISPLAY", ":0")
            .status();

        match status {
            Ok(s) if s.success() => {
                log_ok("Wine prefix initialized successfully");
            }
            _ => {
                warn!("Wine initialization may have issues - continuing");
            }
        }

        // Matar wineserver
        let _ = Command::new("FEXInterpreter")
            .arg("/opt/wine/bin/wineserver")
            .arg("-k")
            .env("WINEPREFIX", &config.wineprefix)
            .status();
    } else {
        log_ok(&format!(
            "Wine prefix exists at {}",
            config.wineprefix.display()
        ));
    }

    Ok(Some(xvfb))
}

// ============================================================================
// INSTALL/UPDATE SERVER - IDÊNTICO AO start.sh install_or_update_server()
// ============================================================================

fn install_or_update_server(config: &LauncherConfig) -> Result<()> {
    section("Server Installation/Update");

    let server_exe = config.server_dir.join("VRisingServer.exe");

    // Verificar se precisa atualizar
    if server_exe.exists() && !config.should_update() {
        log_ok("Server already installed and UPDATE_ON_START is false");
        return Ok(());
    }

    // Copiar SteamCMD se necessário (assim como no start.sh)
    if !config.steamcmd_dir.join("linux32/steamcmd").exists() {
        info!("Copying SteamCMD to writable location...");
        fs::create_dir_all(&config.steamcmd_dir)?;

        let _ = Command::new("cp")
            .args(["-r", "-n"])
            .arg(format!("{}/.", config.steamcmd_orig.display()))
            .arg(&config.steamcmd_dir)
            .status();

        let _ = Command::new("chmod")
            .args(["-R", "+x"])
            .arg(&config.steamcmd_dir)
            .status();

        log_ok("SteamCMD copied");
    }

    // Criar diretório do servidor
    fs::create_dir_all(&config.server_dir)?;

    // Executar SteamCMD com retry (idêntico ao start.sh)
    let max_attempts = 3;
    let install_dir = config.server_dir.to_str().unwrap();

    for attempt in 1..=max_attempts {
        info!("SteamCMD attempt {}/{}...", attempt, max_attempts);

        // FEXInterpreter /data/steamcmd/linux32/steamcmd ...
        let steamcmd_path = config.steamcmd_dir.join("linux32/steamcmd");

        let status = Command::new("FEXInterpreter")
            .arg(&steamcmd_path)
            .arg("+force_install_dir")
            .arg(install_dir)
            .arg("+@sSteamCmdForcePlatformType")
            .arg("windows")
            .arg("+login")
            .arg("anonymous")
            .arg("+app_update")
            .arg(&config.app_id)
            .arg("validate")
            .arg("+quit")
            .current_dir(&config.steamcmd_dir)
            .status();

        match status {
            Ok(s) if s.success() => {
                log_ok("SteamCMD completed successfully");
                return Ok(());
            }
            Ok(s) => {
                warn!("SteamCMD failed with exit code: {:?}", s.code());
            }
            Err(e) => {
                warn!("SteamCMD error: {}", e);
            }
        }

        if attempt < max_attempts {
            info!("Retrying in 10 seconds...");
            std::thread::sleep(Duration::from_secs(10));
        }
    }

    // Verificar se servidor existe mesmo após falha
    if server_exe.exists() {
        warn!("Update failed but server exists - continuing");
        Ok(())
    } else {
        anyhow::bail!(
            "Critical failure: Server not installed after {} attempts",
            max_attempts
        )
    }
}

// ============================================================================
// DUMP ENVIRONMENT - IDÊNTICO AO start.sh dump_environment()
// ============================================================================

fn dump_environment(config: &LauncherConfig) {
    if !config.is_debug() {
        return;
    }

    section("Environment Dump (DEBUG)");

    let vars = [
        "APP_ID",
        "SERVER_DIR",
        "STEAMCMD_DIR",
        "WINEPREFIX",
        "WINEARCH",
        "DISPLAY",
        "SERVER_NAME",
        "SAVE_NAME",
        "GAME_PORT",
        "QUERY_PORT",
        "FEX_TSOENABLE",
        "GC_DONT_GC",
        "UNITY_GC_MODE",
        "WINEDEBUG",
    ];

    for var in vars {
        if let Ok(value) = std::env::var(var) {
            debug!("{}={}", var, value);
        }
    }
}

// ============================================================================
// PRE-LAUNCH CHECKS - IDÊNTICO AO start.sh pre_launch_checks()
// ============================================================================

fn pre_launch_checks(config: &LauncherConfig) -> Result<()> {
    section("Pre-Launch Verification");

    let server_exe = config.server_dir.join("VRisingServer.exe");

    // 1. Verificar VRisingServer.exe
    if !server_exe.exists() {
        log_fail("VRisingServer.exe not found!");
        anyhow::bail!(
            "VRisingServer.exe não encontrado em {}",
            config.server_dir.display()
        );
    }
    log_ok(&format!(
        "VRisingServer.exe found ({})",
        fs::metadata(&server_exe)
            .map(|m| format!("{} bytes", m.len()))
            .unwrap_or_default()
    ));

    // 2. Verificar UnityPlayer.dll
    let unity_dll = config.server_dir.join("UnityPlayer.dll");
    if unity_dll.exists() {
        log_ok("UnityPlayer.dll found");
    } else {
        warn!("UnityPlayer.dll not found - server may fail");
    }

    // 3. Verificar diretório de saves
    let save_data = Path::new("/data/save-data");
    fs::create_dir_all(save_data)?;
    log_ok(&format!("Save directory ready: {}", save_data.display()));

    // 4. Verificar permissões de escrita
    let test_file = save_data.join(".write_test");
    if fs::write(&test_file, "test").is_ok() {
        let _ = fs::remove_file(&test_file);
        log_ok("Write permissions verified");
    } else {
        warn!("Cannot write to save directory - check permissions");
    }

    Ok(())
}

// ============================================================================
// START SERVER - IDÊNTICO AO start.sh (exec FEXInterpreter wine ...)
// ============================================================================

#[cfg(unix)]
fn start_server(config: &LauncherConfig) -> Result<()> {
    let server_exe = config.server_dir.join("VRisingServer.exe");

    // Configurar prioridade do processo (renice)
    let pid = std::process::id();
    let _ = Command::new("renice")
        .args(["-n", "-10", "-p", &pid.to_string()])
        .status();
    info!("Process priority adjusted (renice -10)");

    // Mudar para diretório do servidor
    std::env::set_current_dir(&config.server_dir)
        .context("Falha ao mudar para diretório do servidor")?;

    info!("Executing server...");

    // exec FEXInterpreter wine64 VRisingServer.exe ...
    let err = Command::new("FEXInterpreter")
        .arg(&config.wine_bin)
        .arg(&server_exe)
        .arg("-batchmode")
        .arg("-nographics")
        .arg("-persistentDataPath")
        .arg("Z:/data/save-data")
        .arg("-serverName")
        .arg(&config.server_name)
        .arg("-saveName")
        .arg(&config.save_name)
        .arg("-logFile")
        .arg("NUL")
        .arg("-gamePort")
        .arg(config.game_port.to_string())
        .arg("-queryPort")
        .arg(config.query_port.to_string())
        .arg("-job-worker-count")
        .arg("4")
        .env("WINEPREFIX", &config.wineprefix)
        .env("WINEARCH", "win64")
        .env("DISPLAY", ":0")
        .env("LD_PRELOAD", "/usr/lib/aarch64-linux-gnu/libjemalloc.so.2")
        .exec();

    anyhow::bail!("Exec failed: {}", err)
}

#[cfg(not(unix))]
fn start_server(config: &LauncherConfig) -> Result<()> {
    warn!("Windows platform: start_server not implemented (Unix only)");
    info!(
        "Would execute: FEXInterpreter {} VRisingServer.exe",
        config.wine_bin.display()
    );
    info!("This binary is designed to run inside a Docker container on ARM64 Linux.");
    Ok(())
}
