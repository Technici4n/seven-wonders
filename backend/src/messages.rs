use actix::prelude::*;
use serde::{Serialize, Deserialize};
use crate::connection::PlayerConnection;

#[derive(Message, Debug, Clone, Serialize)]
pub enum ToPlayer {
    /// List of available games
    GameList(Vec<GameInfo>),
    /// Information about the current game
    ActiveGame(PlayerInfo, ActiveGameInfo),
}

#[derive(Message, Debug, Clone)]
pub enum ToServer {
    StartSpectating(Addr<PlayerConnection>),
    StopSpectating(Addr<PlayerConnection>),
    PlayerMessage(Addr<PlayerConnection>, FromPlayer),
}

#[derive(Debug, Clone, Deserialize)]
pub enum FromPlayer {
    /// Create new game
    CreateGame(String, u32),
    /// Connect to some game
    Connect(ConnectInfo),
}

#[derive(Debug, Clone, Serialize)]
pub struct GameInfo {
    pub name: String,
    pub player_count: u32,
    pub connected_players: Vec<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ConnectInfo {
    pub game_name: String,
    pub player_name: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct PlayerInfo {
    pub player_name: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct ActiveGameInfo {
    pub name: String,
    pub player_count: u32,
    pub connected_players: Vec<String>,
}