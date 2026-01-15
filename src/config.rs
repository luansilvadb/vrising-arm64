use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

// ============================================================================
// CONFIGURAÇÃO PRINCIPAL - IDÊNTICA AO start.sh DO REPOSITÓRIO ORIGINAL
// ============================================================================

/// Configuração principal do lançador, lendo variáveis de ambiente
/// idênticas às definidas no start.sh original
#[derive(Debug, Clone, clap::Parser)]
pub struct LauncherConfig {
    /// V Rising Steam App ID
    #[clap(env = "APP_ID", default_value = "1829350")]
    pub app_id: String,

    /// Diretório do servidor
    #[clap(env = "SERVER_DIR", default_value = "/data/server")]
    pub server_dir: PathBuf,

    /// Diretório do SteamCMD (writable)
    #[clap(env = "STEAMCMD_DIR", default_value = "/data/steamcmd")]
    pub steamcmd_dir: PathBuf,

    /// Diretório original do SteamCMD (read-only image)
    #[clap(env = "STEAMCMD_ORIG", default_value = "/steamcmd")]
    pub steamcmd_orig: PathBuf,

    /// Atualizar servidor ao iniciar
    #[clap(env = "UPDATE_ON_START", default_value = "true")]
    pub update_on_start: String,

    /// Binário do Wine
    #[clap(env = "WINE_BIN", default_value = "/opt/wine/bin/wine64")]
    pub wine_bin: PathBuf,

    /// Prefix do Wine
    #[clap(env = "WINEPREFIX", default_value = "/data/wineprefix")]
    pub wineprefix: PathBuf,

    /// Nome do servidor
    #[clap(env = "SERVER_NAME", default_value = "V Rising FEX Server")]
    pub server_name: String,

    /// Nome do save
    #[clap(env = "SAVE_NAME", default_value = "world1")]
    pub save_name: String,

    /// Porta do jogo (UDP)
    #[clap(env = "GAME_PORT", default_value = "9876")]
    pub game_port: u16,

    /// Porta de query (UDP)
    #[clap(env = "QUERY_PORT", default_value = "9877")]
    pub query_port: u16,

    /// Modo debug
    #[clap(env = "DEBUG", default_value = "false")]
    pub debug: String,
}

// ============================================================================
// CONFIGURAÇÕES DO SERVIDOR HOST - IDÊNTICAS AO ORIGINAL
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub struct ServerHostSettings {
    pub name: String,
    pub description: String,
    pub port: u16,
    pub query_port: u16,
    pub max_connected_users: u16,
    pub max_connected_admins: u16,
    pub server_fps: u16,
    pub save_name: String,
    pub password: String,
    pub secure: bool,
    pub list_on_master_server: bool,
    pub list_on_steam: bool,
    #[serde(rename = "ListOnEOS")]
    pub list_on_eos: bool,
    pub auto_save_count: u16,
    pub auto_save_interval: u16,
    pub compress_save_files: bool,
    pub game_settings_preset: String,
    pub game_difficulty_preset: String,
    pub admin_only_debug_events: bool,
    pub disable_debug_events: bool,
    #[serde(rename = "API")]
    pub api: ApiSettings,
    #[serde(rename = "Rcon")]
    pub rcon: RconSettings,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub struct ApiSettings {
    pub enabled: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub struct RconSettings {
    pub enabled: bool,
    pub port: u16,
    pub password: String,
}

// ============================================================================
// CONFIGURAÇÕES DO JOGO - ESTRUTURA COMPLETA IGUAL AO ServerGameSettings.json
// Essas structs são usadas para parsing de JSON, mesmo que não sejam instanciadas diretamente
// ============================================================================

#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "PascalCase")]
pub struct ServerGameSettings {
    pub game_mode_type: String,
    pub castle_damage_mode: String,
    pub siege_weapon_health: String,
    pub player_damage_mode: String,
    pub castle_heart_damage_mode: String,
    pub pvp_protection_mode: String,
    pub death_container_permission: String,
    pub relics_death_container_permission: String,
    pub can_loot_enemy_containers: bool,
    pub blood_bound_equipment: bool,
    pub teleport_bound_items: bool,
    pub allow_global_chat: bool,
    pub all_waypoints_unlocked: bool,
    pub free_castle_claim: bool,
    pub free_castle_destroy: bool,
    pub inspect_other_clan_players: bool,
    pub announce_siege_weapon_spawn: bool,
    pub show_siege_weapon_map_icon: bool,
    pub blood_essence_sun_damage_modifier: f32,
    #[serde(rename = "VBloodUnitSettings")]
    pub vblood_unit_settings: Option<serde_json::Value>,
    #[serde(rename = "UnlockedResearch")]
    pub unlocked_research: Option<serde_json::Value>,
    #[serde(rename = "UnlockedAbilities")]
    pub unlocked_abilities: Option<serde_json::Value>,
    #[serde(rename = "UnitStatModifiers_Global")]
    pub unit_stat_modifiers_global: Option<UnitStatModifiers>,
    #[serde(rename = "UnitStatModifiers_VBlood")]
    pub unit_stat_modifiers_vblood: Option<UnitStatModifiers>,
    #[serde(rename = "EquipmentStatModifiers_Global")]
    pub equipment_stat_modifiers_global: Option<EquipmentStatModifiers>,
    #[serde(rename = "CastleStatModifiers_Global")]
    pub castle_stat_modifiers_global: Option<CastleStatModifiers>,
    #[serde(rename = "PlayerInteractionSettings")]
    pub player_interaction_settings: Option<PlayerInteractionSettings>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "PascalCase")]
pub struct UnitStatModifiers {
    pub max_health_modifier: f32,
    pub power_modifier: f32,
    pub resistance_modifier: f32,
    pub damage_received_modifier: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "PascalCase")]
pub struct EquipmentStatModifiers {
    pub max_energy_modifier: f32,
    pub max_health_modifier: f32,
    pub resource_yield_modifier: f32,
    pub physical_power_modifier: f32,
    pub spell_power_modifier: f32,
    pub siege_power_modifier: f32,
    pub damage_taken_modifier: f32,
    pub revival_time_modifier: f32,
    pub repair_time_modifier: f32,
    pub crafting_speed_modifier: f32,
    pub research_speed_modifier: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "PascalCase")]
pub struct CastleStatModifiers {
    pub tick_period_modifier: f32,
    pub decay_rate_modifier: f32,
    pub blood_essence_drain_modifier: f32,
    pub safety_box_limit_modifier: f32,
    pub tombstone_limit_modifier: f32,
    pub vermin_nest_limit_modifier: f32,
    pub prison_cell_limit_modifier: f32,
    pub heart_limit: HeartLimits,
    pub castle_limit: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "PascalCase")]
pub struct HeartLimits {
    pub level1: HeartLevel,
    pub level2: HeartLevel,
    pub level3: HeartLevel,
    pub level4: HeartLevel,
    pub level5: HeartLevel,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "PascalCase")]
pub struct HeartLevel {
    pub level: u8,
    pub floor_limit: u16,
    pub servant_limit: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "PascalCase")]
pub struct PlayerInteractionSettings {
    pub time_zone: String,
    #[serde(rename = "VSPlayerWeekdayTime")]
    pub vs_player_weekday_time: TimeWindow,
    #[serde(rename = "VSPlayerWeekendTime")]
    pub vs_player_weekend_time: TimeWindow,
    #[serde(rename = "VSCastleWeekdayTime")]
    pub vs_castle_weekday_time: TimeWindow,
    #[serde(rename = "VSCastleWeekendTime")]
    pub vs_castle_weekend_time: TimeWindow,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "PascalCase")]
pub struct TimeWindow {
    pub start_hour: u8,
    pub start_minute: u8,
    pub end_hour: u8,
    pub end_minute: u8,
}

// ============================================================================
// IMPLEMENTAÇÃO - GERAR CONFIGURAÇÕES
// ============================================================================

impl LauncherConfig {
    /// Retorna true se o modo debug está ativado
    pub fn is_debug(&self) -> bool {
        self.debug.to_lowercase() == "true"
    }

    /// Retorna true se deve atualizar ao iniciar
    pub fn should_update(&self) -> bool {
        self.update_on_start.to_lowercase() == "true"
    }

    /// Gera arquivos de configuração do servidor
    /// Equivalente à função configure_settings() do start.sh
    pub fn configure_settings(&self) -> Result<()> {
        let settings_dir = PathBuf::from("/data/save-data/Settings");
        fs::create_dir_all(&settings_dir)?;

        // Ler variáveis de ambiente adicionais (idêntico ao start.sh)
        let server_description =
            std::env::var("SERVER_DESCRIPTION").unwrap_or_else(|_| String::new());
        let list_on_master = std::env::var("LIST_ON_MASTER_SERVER")
            .map(|v| v.to_lowercase() == "true")
            .unwrap_or(true);
        let max_connected_users: u16 = std::env::var("MAX_CONNECTED_USERS")
            .unwrap_or_else(|_| "100".to_string())
            .parse()
            .unwrap_or(100);
        let max_connected_admins: u16 = std::env::var("MAX_CONNECTED_ADMINS")
            .unwrap_or_else(|_| "5".to_string())
            .parse()
            .unwrap_or(5);
        let server_fps: u16 = std::env::var("SERVER_FPS")
            .unwrap_or_else(|_| "60".to_string())
            .parse()
            .unwrap_or(60);
        let server_password = std::env::var("SERVER_PASSWORD").unwrap_or_default();
        let secure = std::env::var("SECURE")
            .map(|v| v.to_lowercase() == "true")
            .unwrap_or(true);
        let auto_save_count: u16 = std::env::var("AUTO_SAVE_COUNT")
            .unwrap_or_else(|_| "25".to_string())
            .parse()
            .unwrap_or(25);
        let auto_save_interval: u16 = std::env::var("AUTO_SAVE_INTERVAL")
            .unwrap_or_else(|_| "120".to_string())
            .parse()
            .unwrap_or(120);
        let compress_save = std::env::var("COMPRESS_SAVE_FILES")
            .map(|v| v.to_lowercase() == "true")
            .unwrap_or(false);
        let game_settings_preset = std::env::var("GAME_SETTINGS_PRESET").unwrap_or_default();
        let game_difficulty_preset = std::env::var("GAME_DIFFICULTY_PRESET").unwrap_or_default();
        let admin_only_debug = std::env::var("ADMIN_ONLY_DEBUG_EVENTS")
            .map(|v| v.to_lowercase() == "true")
            .unwrap_or(true);
        let disable_debug = std::env::var("DISABLE_DEBUG_EVENTS")
            .map(|v| v.to_lowercase() == "true")
            .unwrap_or(false);
        let api_enabled = std::env::var("API_ENABLED")
            .map(|v| v.to_lowercase() == "true")
            .unwrap_or(false);
        let rcon_enabled = std::env::var("RCON_ENABLED")
            .map(|v| v.to_lowercase() == "true")
            .unwrap_or(true);
        let rcon_port: u16 = std::env::var("RCON_PORT")
            .unwrap_or_else(|_| "25575".to_string())
            .parse()
            .unwrap_or(25575);
        let rcon_password = std::env::var("RCON_PASSWORD").unwrap_or_default();

        let host_settings = ServerHostSettings {
            name: self.server_name.clone(),
            description: server_description,
            port: self.game_port,
            query_port: self.query_port,
            max_connected_users,
            max_connected_admins,
            server_fps,
            save_name: self.save_name.clone(),
            password: server_password,
            secure,
            list_on_master_server: list_on_master,
            list_on_steam: list_on_master,
            list_on_eos: list_on_master,
            auto_save_count,
            auto_save_interval,
            compress_save_files: compress_save,
            game_settings_preset,
            game_difficulty_preset,
            admin_only_debug_events: admin_only_debug,
            disable_debug_events: disable_debug,
            api: ApiSettings {
                enabled: api_enabled,
            },
            rcon: RconSettings {
                enabled: rcon_enabled,
                port: rcon_port,
                password: rcon_password,
            },
        };

        let json = serde_json::to_string_pretty(&host_settings)?;
        fs::write(settings_dir.join("ServerHostSettings.json"), json)?;

        log::info!("ServerHostSettings.json gerado em {:?}", settings_dir);

        // Verificar se deve copiar ServerGameSettings.json (GAME_SETTINGS_PRESET vazio)
        let enable_mods = std::env::var("ENABLE_MODS")
            .map(|v| v.to_lowercase() == "true")
            .unwrap_or(false);

        if !enable_mods {
            // Se GAME_SETTINGS_PRESET estiver vazio e existir arquivo customizado, usar ele
            if host_settings.game_settings_preset.is_empty() {
                let custom_path = PathBuf::from("/ServerGameSettings.json");
                if custom_path.exists() {
                    let content = fs::read_to_string(&custom_path)?;
                    fs::write(settings_dir.join("ServerGameSettings.json"), content)?;
                    log::info!("ServerGameSettings.json customizado copiado");
                }
            }
        }

        Ok(())
    }
}
