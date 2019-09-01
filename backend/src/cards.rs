use crate::game::{Card, CardEffect, ResourceArray, RIGHT_PLAYER, LEFT_PLAYER, SCIENCE_COMPASS, SCIENCE_GEAR, SCIENCE_TABLET};

/// The CardRegistry produces the card for the games depending on the age and the number of players.
#[derive(Debug, Clone)]
pub struct CardRegistry {
    cards: [Vec<Card>; 3],
}

impl CardRegistry {
    pub fn generate_cards(&self, age: usize, player_count: usize) -> Vec<Card> {
        self.cards[age][0..(player_count*7)].to_vec()
    }

    pub fn new() -> CardRegistry {
        use CardEffect::*;
        Self {
            cards: [
                // AGE ONE
                vec![
                    // ** THREE PLAYERS
                    // *** BROWN CARDS
                    CardBuilder::new("Chantier", Resources([0, 1, 0, 0, 0, 0, 0])),
                    CardBuilder::new("Cavité", Resources([0, 0, 0, 1, 0, 0, 0])),
                    CardBuilder::new("Bassin argileux", Resources([1, 0, 0, 0, 0, 0, 0])),
                    CardBuilder::new("Filon", Resources([0, 0, 1, 0, 0, 0, 0])),
                    CardBuilder::new("Fosse argileuse", Resources([1, 0, 1, 0, 0, 0, 0])).with_cost_gold(1),
                    CardBuilder::new("Exploitation forestière", Resources([0, 1, 0, 1, 0, 0, 0])).with_cost_gold(1),
                    // *** GRAY CARDS
                    CardBuilder::new("Métier à tisser", Resources([0, 0, 0, 0, 0, 0, 1])),
                    CardBuilder::new("Verrerie", Resources([0, 0, 0, 0, 1, 0, 0])),
                    CardBuilder::new("Presse", Resources([0, 0, 0, 0, 0, 1, 0])),
                    // *** BLUE CARDS
                    CardBuilder::new("Bains", Points(3)).with_cost_stone(1),
                    CardBuilder::new("Autel", Points(2)),
                    CardBuilder::new("Théâtre", Points(2)),
                    // *** YELLOW CARDS
                    CardBuilder::new("Comptoir est", RawMaterialsCost(RIGHT_PLAYER)),
                    CardBuilder::new("Comptoir ouest", RawMaterialsCost(LEFT_PLAYER)),
                    CardBuilder::new("Marché", ManufacturedProductsCost),
                    // *** RED CARDS
                    CardBuilder::new("Palissade", Shields(1)).with_cost_wood(1),
                    CardBuilder::new("Caserne", Shields(1)).with_cost_ore(1),
                    CardBuilder::new("Tour de garde", Shields(1)).with_cost_clay(1),
                    // *** GREEN CARDS
                    CardBuilder::new("Officine", Science(SCIENCE_COMPASS)).with_cost_loom(1),
                    CardBuilder::new("Atelier", Science(SCIENCE_GEAR)).with_cost_glass(1),
                    CardBuilder::new("Scriptorium", Science(SCIENCE_TABLET)).with_cost_papyrus(1),

                ].into_iter().map(|cb| cb.build()).collect(),
                vec![],
                vec![],
            ],
        }
    }
}

struct CardBuilder {
    card: Card,
}

impl CardBuilder {
    pub fn new<S: ToString>(name: S, effect: CardEffect) -> CardBuilder {
        Self {
            card: Card {
                name: name.to_string(),
                gold_cost: 0,
                resource_cost: [0; 7],
                effect,
                chaining_targets: vec![],
                chaining_sources: vec![],
            }
        }
    }

    pub fn with_cost_clay(mut self, resource_cost: u32) -> Self {
        self.card.resource_cost[0] = resource_cost;
        self
    }
    pub fn with_cost_wood(mut self, resource_cost: u32) -> Self {
        self.card.resource_cost[1] = resource_cost;
        self
    }
    pub fn with_cost_ore(mut self, resource_cost: u32) -> Self {
        self.card.resource_cost[2] = resource_cost;
        self
    }
    pub fn with_cost_stone(mut self, resource_cost: u32) -> Self {
        self.card.resource_cost[3] = resource_cost;
        self
    }
    pub fn with_cost_glass(mut self, resource_cost: u32) -> Self {
        self.card.resource_cost[4] = resource_cost;
        self
    }
    pub fn with_cost_papyrus(mut self, resource_cost: u32) -> Self {
        self.card.resource_cost[5] = resource_cost;
        self
    }
    pub fn with_cost_loom(mut self, resource_cost: u32) -> Self {
        self.card.resource_cost[6] = resource_cost;
        self
    }
    pub fn with_cost(mut self, resource_cost: ResourceArray) -> Self {
        self.card.resource_cost = resource_cost;
        self
    }
    pub fn with_cost_gold(mut self, gold_cost: u32) -> Self {
        self.card.gold_cost = gold_cost;
        self
    }
    pub fn with_chaining_source(mut self, source: String) -> Self {
        self.card.chaining_sources.push(source);
        self
    }
    pub fn with_chaining_target(mut self, target: String) -> Self {
        self.card.chaining_targets.push(target);
        self
    }
    pub fn build(self) -> Card {
        self.card
    }
}