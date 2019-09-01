use rand::prelude::*;
use serde::Serialize;
use crate::cards::CardRegistry;

/// The state of a single game.
#[derive(Debug, Clone, Serialize)]
pub struct Game {
    #[serde(skip)]
    card_registry: CardRegistry,
    player_count: usize,
    pub players: Vec<PlayerData>,
    age: usize,
}

impl Game {
    pub fn new(player_count: usize) -> Game {
        let mut rng = thread_rng();

        let card_registry = CardRegistry::new();
        let mut cards = card_registry.generate_cards(0, player_count);
        cards.shuffle(&mut rng);

        let players = (0..player_count).map(|i| {
            PlayerData {
                hand_cards: cards[i*7..(i+1)*7].into(),
                board_cards: vec![],
                resource_productions: Default::default(),
                adjacent_resource_costs: Default::default(),
                gold: 3,
            }
        }).collect();

        Game {
            card_registry,
            player_count,
            players,
            age: 0,
        }
    }
}

/// The state of one player's board and hand.
#[derive(Debug, Clone, Serialize)]
pub struct PlayerData {
    #[serde(skip)]
    pub hand_cards: Vec<Card>,
    board_cards: Vec<Card>,
    resource_productions: [Vec<ResourceArray>; 3],
    adjacent_resource_costs: [ResourceArray; 2],
    gold: u32,
}

/// A card.
#[derive(Debug, Clone, Serialize)]
pub struct Card {
    pub name: String,
    pub gold_cost: u32,
    pub resource_cost: ResourceArray,
    pub effect: CardEffect,
    pub chaining_targets: Vec<String>,
    pub chaining_sources: Vec<String>,
}

pub const LEFT_PLAYER: isize = -1;
pub const RIGHT_PLAYER: isize = 1;
pub const SCIENCE_TABLET: usize = 0;
pub const SCIENCE_COMPASS: usize = 1;
pub const SCIENCE_GEAR: usize = 2;

#[derive(Debug, Clone, Serialize)]
pub enum CardEffect {
    /// Produce one of the following resource.
    Resources(ResourceArray),
    /// Give points.
    Points(u32),
    /// Change the cost of buying raw materials coming from an adjacent player to 1 (left is -1, right is 1).
    RawMaterialsCost(isize),
    /// Change the cost of buying manufactured products from adjacent players to 1.
    ManufacturedProductsCost,
    /// Give military points.
    Shields(u32),
    Science(usize),
}

pub type ResourceArray = [u32; 7];