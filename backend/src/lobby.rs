use actix::prelude::*;
use rand::prelude::*;
use std::collections::HashMap;
use crate::connection::PlayerConnection;
use crate::game::{Game as GameState, PlayerAction};
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
                        player_ids: HashMap::new(),
                        player_names: Vec::new(),
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
                FromPlayer::Action(action) => {
                    if let Some(player_state) = self.players.get(&addr) {
                        if let PlayerState::InGame(game_name) = player_state {
                            self.games.get_mut(game_name).map(move |game| {
                                game.perform_action(addr, action);
                            });
                        }
                    }
                }
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
    pub player_ids: HashMap<String, usize>,
    pub player_names: Vec<String>,
}

type ConnectedPlayer = Option<Addr<PlayerConnection>>;

impl Game {
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
            self.mabye_start_game();
            self.broadcast_game_info();
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
        self.broadcast_game_info();
    }

    pub fn mabye_start_game(&mut self) {
        if self.state.is_none() && self.players.len() == self.player_count {
            self.start_game();
        }
    }

    fn start_game(&mut self) {
        println!("Game started!");

        // Randomly assign positions to players
        let mut names = self.get_connected_players();
        names.shuffle(&mut thread_rng());
        self.player_names = names;
        for (i, name) in self.player_names.iter().enumerate() {
            self.player_ids.insert(name.to_string(), i);
        }
        
        self.state = Some(GameState::new(self.player_count));

        dbg!(&self.player_names, &self.player_ids);
    }

    fn get_connected_players(&self) -> Vec<String> {
        // TODO: handle disconnected players while the game is running
        let mut players: Vec<_> = self.players.iter().map(
            |(name, cp)| name.clone()
        ).collect();
        // Sort by id if the game has started, or by name otherwise
        if let Some(_) = self.state {
            players.sort_by_key(|name| self.player_ids.get(name).unwrap());
        } else {
            players.sort();
        }
        players
    }

    fn broadcast_game_info(&self) {
        println!("broadcasting game info");
        let connected_players = self.get_connected_players();
        let agi = ActiveGameInfo { name: self.name.clone(), player_count: self.player_count, connected_players, game: self.state.clone(), };
        for (player_name, cp) in self.players.iter() {
            if let Some(addr) = cp {
                let i = self.player_ids.get(player_name);
                addr.do_send(ToPlayer::ActiveGame(
                    PlayerInfo {
                        player_name: player_name.clone(),
                        cards: self.state.as_ref().map(|game| game.players[*i.expect("Unknown player name")].hand_cards.clone()),
                        play: self.state.as_ref().map(|game| game.plays[*i.expect("Unknown player name")].clone()),
                    },
                    agi.clone()
                ));
            }
        }
    }

    pub fn perform_action(&mut self, player: Addr<PlayerConnection>, action: PlayerAction) {
        for (name, cp) in self.players.iter() {
            if let Some(addr) = cp {
                if *addr == player {
                    if let Some(game) = self.state.as_mut() {
                        let player_id = self.player_ids.get(name).expect("Unknown player name");
                        println!("name {:?} was mapped to id {:?}", &name, player_id);
                        game.perform_action(*player_id, action.clone());
                    }
                }
            };
        }
        self.broadcast_game_info();
    }
}

#[derive(Debug)]
enum PlayerState {
    InLobby,
    InGame(String),
}