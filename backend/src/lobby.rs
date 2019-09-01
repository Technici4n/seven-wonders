use actix::prelude::*;
use std::collections::HashMap;
use crate::connection::PlayerConnection;
use crate::game::Game as GameState;
use crate::messages::{ActiveGameInfo, ConnectInfo, PlayerInfo, FromPlayer, GameInfo, ToPlayer, ToServer};

#[derive(Debug)]
pub struct Lobby {
    games: HashMap<String, Game>,
    players: HashMap<Addr<PlayerConnection>, PlayerState>,
}

impl Lobby {
    pub fn new() -> Self {
        Self {
            games: HashMap::new(),
            players: HashMap::new(),
        }
    }

    fn broadcast_games(&self) {
        let games : Vec<_> = self.games.iter().map(|(name, game)| {
            GameInfo {
                name: name.clone(),
                player_count: game.player_count,
                connected_players: game.players.iter().map(|(name, _)| name.clone()).collect(), // TODO: take disconnections into account
            }
        }).collect();
        let message = ToPlayer::GameList(games);
        for (addr, _) in self.players.iter() {
            addr.do_send(message.clone());
        }
    }
}

impl Actor for Lobby {
    type Context = Context<Self>;
}

impl Handler<ToServer> for Lobby {
    type Result = ();

    fn handle(&mut self, msg: ToServer, _ctx: &mut Context<Self>) {
        match msg {
            ToServer::StartSpectating(addr) => {
                self.players.entry(addr).or_insert(PlayerState::InLobby);
                self.broadcast_games();
            },
            ToServer::StopSpectating(addr) => {
                if let Some(player_state) = self.players.remove(&addr) {
                    if let PlayerState::InGame(game_name) = player_state {
                        self.games.get_mut(&game_name).map(move |game| {
                            game.remove_player(addr);
                        });
                    }
                } else {
                    println!("Couldn't remove a player that should have been connected!");
                }
                self.broadcast_games();
            },
            ToServer::PlayerMessage(addr, msg) => match msg {
                FromPlayer::CreateGame(name, player_count) => {
                    // TODO: Ban cancer game names
                    // Make sure the game does not exist yet
                    self.games.entry(name.clone()).or_insert(Game {
                        name,
                        player_count,
                        players: HashMap::new(),
                        state: None,
                    });
                    self.broadcast_games();
                },
                FromPlayer::Connect(ConnectInfo { game_name, player_name }) => {
                    // Make sure the game exists
                    // Make sure the player is not in a game
                    if let Some(player_state) = self.players.get_mut(&addr) {
                        if let PlayerState::InGame(_) = player_state {
                            return;
                        }
                        self.games.get_mut(&game_name).map(move |game| {
                            if game.maybe_accept_player(player_name, addr) {
                                *player_state = PlayerState::InGame(game_name);
                            }
                            // TODO: Handle rejection
                        });
                    }
                },
            }
        }
    }
}

#[derive(Debug)]
struct Game {
    pub name: String,
    pub player_count: usize,
    pub players: HashMap<String, ConnectedPlayer>,
    pub state: Option<GameState>,
}

type ConnectedPlayer = Option<Addr<PlayerConnection>>;

impl Game {
    // TODO: start the game if there are enough players
    pub fn maybe_accept_player(&mut self, player_name: String, addr: Addr<PlayerConnection>) -> bool {
        let mut accepted = false;
        if let Some(connected_player) = self.players.get_mut(&player_name) {
            connected_player.get_or_insert_with(|| {
                accepted = true;
                addr.clone()
            });
        } else if self.state.is_none() && self.player_count > self.players.len() {
            self.players.insert(player_name.clone(), Some(addr.clone()));
            accepted = true;
        }
        if accepted {
            self.broadcast_game_info();
            self.mabye_start_game();
        }
        accepted
    }

    pub fn remove_player(&mut self, addr: Addr<PlayerConnection>) {
        match &self.state {
            Some(_) => {
                // Remove player connections matching this address
                self.players.iter_mut().for_each(|(_, connected_player)| {
                    if let Some(a) = connected_player {
                        if *a == addr {
                            *connected_player = None;
                        }
                    }
                });
            },
            None => {
                // Remove players matching this address
                self.players.retain(|_, connected_player| {
                    match connected_player {
                        Some(a) => *a != addr,
                        None => false,
                    }
                });
            },
        }
    }

    pub fn mabye_start_game(&mut self) {
        if self.state.is_none() && self.players.len() == self.player_count {
            self.start_game();
        }
    }

    fn start_game(&mut self) {
        println!("Game started!");
        self.state = Some(GameState::new(self.player_count));
        self.broadcast_game_info();
    }

    fn broadcast_game_info(&mut self) {
        println!("broadcasting game info");
        let connected_players: Vec<_> = self.players.iter().filter_map(
            |(name, cp)| cp.as_ref().map(|_| name).cloned()
        ).collect();
        let agi = ActiveGameInfo { name: self.name.clone(), player_count: self.player_count, connected_players, game: self.state.clone(), };
        for (i, (player_name, cp)) in self.players.iter().enumerate() {
            if let Some(addr) = cp {
                addr.do_send(ToPlayer::ActiveGame(
                    PlayerInfo {
                        player_name: player_name.clone(),
                        cards: self.state.as_ref().map(|game| game.players[i].hand_cards.clone()),
                    },
                    agi.clone()
                ));
            }
        }
    }
}

#[derive(Debug)]
enum PlayerState {
    InLobby,
    InGame(String),
}