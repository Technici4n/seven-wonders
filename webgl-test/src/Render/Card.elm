module Render.Card exposing (render, Card, CardEffect)

type alias Card =
  { name : String
  , goldCost : Int
  , resourceCost : ResourceArray
  , effect : CardEffect
  , chainingTargets : List String
  , chainingSources : List String
  }

type alias ResourceArray = List Int

type CardEffect
  = Resources ResourceArray
  | Points Int
  | RawMaterialsCost Int
  | ManufacturedProductsCost
  | Shields Int
  | Science Int