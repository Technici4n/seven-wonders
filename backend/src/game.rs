use rand::prelude::*;
use serde::{Deserialize, Serialize};
use crate::cards::CardRegistry;

/// The state of a single game.
#[derive(Debug, Clone, Serialize)]
pub struct Game {
    #[serde(skip)]
    card_registry: CardRegistry,
    #[serde(skip)]
    pub plays: Vec<Play>,
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
                hand_cards: cards[(i*7)..((i+1)*7)].into(),
                board_cards: vec![],
                resource_productions: Default::default(),
                resource_costs: [[2; 7], [0; 7], [2; 7]],
                gold: 3,
            }
        }).collect();

        Game {
            card_registry,
            player_count,
            plays: vec![Play::NoAction; player_count],
            players,
            age: 0,
        }
    }

    pub fn perform_action(&mut self, player: usize, action: PlayerAction) {
        assert!(player < self.player_count);
        let adjacent_players = {
            let previous_player = (player + self.player_count - 1) % self.player_count;
            let next_player = (player + 1) % self.player_count;
            [previous_player, player, next_player]
        };

        let play = &mut self.plays[player];
        let data = &self.players[player];
        match action {
            PlayerAction::PickCard(card) => {
                // Check card index
                println!("Picking card {} for player {}!", card, player);
                if let Play::NoAction = play {
                    println!("Picking card {} for player {}!", card, player);
                    if card < data.hand_cards.len() {
                        println!("Picking card {} for player {}!", card, player);
                        let no_resource_allocation = {
                            let mut nra: ResourceAllocation = Default::default();
                            for i in 0..3 {
                                nra[i] = vec![0; data.resource_productions[i].len()];
                            }
                            nra
                        };
                        let verdict = data.get_card_verdict(card, &no_resource_allocation);
                        dbg!(card);
                        *play = Play::ChoosingResources {
                            card_index: card,
                            resource_allocation: no_resource_allocation,
                            verdict,
                        };
                    }
                }
            },
            PlayerAction::CancelCard => {
                *play = Play::NoAction;
            },
            PlayerAction::GetResource(player, production, resource) => {
                if player < 3 && production < data.resource_productions[player].len() && resource < 8 {
                    if let Play::ChoosingResources { card_index, resource_allocation, verdict } = play {
                        println!("Resource productions: {:?}", data.resource_productions);
                        println!("First RA: {:?}", resource_allocation);
                        resource_allocation[player][production] = resource;
                        println!("Second RA: {:?}", resource_allocation);
                        *verdict = data.get_card_verdict(*card_index, &resource_allocation);
                        dbg!(*card_index);
                        println!("Verdict: {:?}", verdict);
                    }
                }
            },
            PlayerAction::Validate => {
                if let Play::ChoosingResources { card_index, resource_allocation, verdict } = play {
                    if verdict.is_valid() {
                        *play = Play::ChoseResources {
                            card_index: *card_index,
                            resource_allocation: resource_allocation.clone(),
                        };
                    }
                }
            },
            PlayerAction::Unvalidate => {
                if let Play::ChoseResources { card_index, resource_allocation } = play {
                    let verdict = data.get_card_verdict(*card_index, &resource_allocation);
                    *play = Play::ChoosingResources {
                        card_index: *card_index,
                        resource_allocation: resource_allocation.clone(),
                        verdict,
                    };
                }
            },
        }

        self.maybe_play_cards();
    }

    fn maybe_play_cards(&mut self) {
        let ready_players = self.plays.iter().filter(|p| match p {
            Play::ChoseResources {..} => true,
            Play::NoAction | Play::ChoosingResources {..} => false,
        }).count();
        if ready_players == self.player_count {
            self.play_cards();
        }
    }

    fn play_cards(&mut self) {
        // Place cards on the board
        let player_count = self.player_count;
        let adjancent_players = |i| [(i + player_count - 1) % player_count, (i + 1) % player_count];
        for i in 0..player_count {
            if let Play::ChoseResources { card_index, resource_allocation } = &self.plays[i] {
                let (gold_cost, gold_gain) = self.players[i].get_gold_cost(*card_index, &resource_allocation);
                assert!(gold_gain[1] == 0);
                // Remove card from hand
                let card = self.players[i].hand_cards.remove(*card_index);
                // Add card to board
                self.players[i].board_cards.push(card);
                // Transfer gold
                self.players[i].gold -= gold_cost;
                let [left, right] = adjancent_players(i);
                self.players[left].gold += gold_gain[0];
                self.players[right].gold += gold_gain[2];
            }
            // Reset actions
            self.plays[i] = Play::NoAction;
        }
        // Apply card effects
        for i in 0..self.player_count {
            use CardEffect::*;

            let [left, right] = adjancent_players(i);
            let card = self.players[i].board_cards.last().clone().expect("No card on board");
            match card.effect {
                Resources(ra) => {
                    self.players[left].resource_productions[2].push(ra.clone());
                    self.players[i].resource_productions[1].push(ra.clone());
                    self.players[right].resource_productions[0].push(ra.clone());
                },
                RawMaterialsCost(player) => {
                    for resource in 0..4 {
                        self.players[i].resource_costs[player][resource] = 1;
                    }
                },
                ManufacturedProductsCost => {
                    for player in &[0, 2] {
                        for resource in 4..7 {
                            self.players[i].resource_costs[*player][resource] = 1;
                        }
                    }
                },
                Points(_) | Shields(_) | Science(_) => (),
            }
        }
        // Rotate cards
        let mut remaining_cards: Vec<_> = self.players.iter().map(|player| player.hand_cards.clone()).collect();
        // TODO: check rotation direction
        remaining_cards.rotate_left(1);
        for i in 0..player_count {
            self.players[i].hand_cards = remaining_cards[i].clone();
        }
        // TODO: check age end
        // TODO: check game end
    }
}

/// The state of one player's board and hand.
#[derive(Debug, Clone, Serialize)]
pub struct PlayerData {
    #[serde(skip)]
    pub hand_cards: Vec<Card>,
    board_cards: Vec<Card>,
    resource_productions: [Vec<ResourceArray>; 3],
    resource_costs: [ResourceArray; 3],
    gold: u32,
}

impl PlayerData {
    pub fn get_card_verdict(&self, card: usize, resource_allocation: &ResourceAllocation) -> ResourceAllocationVerdict {
        let mut allocated_resources = [0; 7];
        let mut gold_cost = self.hand_cards[card].gold_cost;
        for player in 0..3 {
            for (production, chosen_resource) in resource_allocation[player].iter().enumerate() {
                dbg!((player, production, chosen_resource));
                dbg!(&self.resource_productions);
                if *chosen_resource > 0 && self.resource_productions[player][production][chosen_resource-1] > 0 {
                    let id = chosen_resource - 1;
                    allocated_resources[id] += 1;
                    gold_cost += self.resource_costs[player][id];
                }
            }
        }

        let card_cost = self.hand_cards[card].resource_cost.clone();
        let mut extra_resources = [0; 7];
        let mut missing_resources = [0; 7];
        for i in 0..7 {
            let all = allocated_resources[i];
            let cost = card_cost[i];
            
            if all < cost {
                missing_resources[i] = cost - all;
            } else if all > cost {
                extra_resources[i] = all - cost;
            }
        }

        let missing_gold = if self.gold < gold_cost {
            gold_cost - self.gold
        } else {
            0
        };

        dbg!(&self.hand_cards);
        dbg!(card, allocated_resources, card_cost, extra_resources, missing_resources);

        ResourceAllocationVerdict {
            extra_resources,
            missing_resources,
            missing_gold,
        }
    }

    pub fn get_gold_cost(&self, card: usize, resource_allocation: &ResourceAllocation) -> (u32, [u32; 3]) {
        let mut gold_cost = self.hand_cards[card].gold_cost;
        let mut gold_gain = [0; 3];
        for player in 0..3 {
            for (production, chosen_resource) in resource_allocation[player].iter().enumerate() {
                if *chosen_resource > 0 && self.resource_productions[player][production][chosen_resource-1] > 0 {
                    let id = chosen_resource - 1;
                    gold_cost += self.resource_costs[player][id];
                    gold_gain[player] += self.resource_costs[player][id];
                }
            }
        }
        (gold_cost, gold_gain)
    }
}

/// A card.
#[derive(Debug, Clone, Serialize)]
pub struct Card {
    pub color: usize,
    pub name: String,
    pub gold_cost: u32,
    pub resource_cost: ResourceArray,
    pub effect: CardEffect,
    pub chaining_targets: Vec<String>,
    pub chaining_sources: Vec<String>,
}

pub const COLOR_BLUE: usize = 0;
pub const COLOR_BROWN: usize = 1;
pub const COLOR_GRAY: usize = 2;
pub const COLOR_GREEN: usize = 3;
pub const COLOR_PURPLE: usize = 4;
pub const COLOR_RED: usize = 5;
pub const COLOR_YELLOW: usize = 6;

pub const LEFT_PLAYER: usize = 0;
pub const RIGHT_PLAYER: usize = 2;
pub const SCIENCE_TABLET: usize = 0;
pub const SCIENCE_COMPASS: usize = 1;
pub const SCIENCE_GEAR: usize = 2;

#[derive(Debug, Clone, Serialize)]
pub enum CardEffect {
    /// Produce one of the following resource.
    Resources(ResourceArray),
    /// Give points.
    Points(u32),
    /// Change the cost of buying raw materials coming from an adjacent player to 1 (left is 0, right is 2).
    RawMaterialsCost(usize),
    /// Change the cost of buying manufactured products from adjacent players to 1.
    ManufacturedProductsCost,
    /// Give military points.
    Shields(u32),
    Science(usize),
}

pub type ResourceArray = [u32; 7];

#[derive(Debug, Clone, Deserialize)]
pub enum PlayerAction {
    /// Choose to play i-th card in the hand
    PickCard(usize),
    /// Cancel playing i-th card
    CancelCard,
    /// Choose to get a resource from a player: (relative player position, resource production id, resource id)
    GetResource(usize, usize, usize),
    /// Validate playing current card
    Validate,
    /// Go back to cost selection screen
    Unvalidate,
}

#[derive(Debug, Clone, Serialize)]
pub enum Play {
    NoAction,
    ChoosingResources {
        card_index: usize,
        resource_allocation: ResourceAllocation,
        verdict: ResourceAllocationVerdict,
    },
    ChoseResources {
        card_index: usize,
        resource_allocation: ResourceAllocation,
    },
}

#[derive(Debug, Clone, Serialize)]
pub struct ResourceAllocationVerdict {
    extra_resources: ResourceArray,
    missing_resources: ResourceArray,
    missing_gold: u32,
}

impl ResourceAllocationVerdict {
    pub fn is_valid(&self) -> bool {
        self.extra_resources.iter().filter(|&&x| x != 0).count() == 0 && self.missing_resources.iter().filter(|&&x| x != 0).count() == 0 && self.missing_gold == 0
    }
}

pub type ResourceAllocation = [Vec<usize>; 3];