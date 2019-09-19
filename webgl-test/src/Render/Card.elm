module Render.Card exposing (render, testCard, Card, CardEffect, RenderParameters)

import Font exposing (Font)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (vec2, Vec2)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Render.CardPart as CardPart
import Render.Image as Image
import Render.Primitive as Primitive
import Render.Text as Text
import Render.VertexList as VertexList exposing (VertexList)
import TextureAtlas exposing (TextureAtlas)

type alias Card =
  { name : String
  , color : CardColor
  , goldCost : Int
  , resourceCost : ResourceArray
  , effect : CardEffect
  , chainingTargets : List String
  , chainingSources : List String
  }

type alias ResourceArray = List Int

type CardEffect
  = SingleResource Int
  | EitherResource (Int, Int)
  | Points Int
  | RawMaterialsCost Int
  | ManufacturedProductsCost
  | Shields Int
  | Science Int

type CardColor
 = Brown
 | Gray
 | Blue
 | Yellow
 | Red
 | Green
 | Purple

testCard : Card
testCard =
  Card
    "Verrerie"
    Gray
    0
    []
    (SingleResource 4)
    []
    []

-- Backgrounds
backgroundGrey : Vec3
backgroundGrey = vec3 0.7 0.7 0.7
backgroundColor : CardColor -> Vec3
backgroundColor color =
  case color of
    Brown -> vec3 0.46 0.20 0.11
    Gray -> vec3 0.7 0.7 0.7
    _ -> Debug.todo "other colors"
-- Resources
resourceClay : Vec3
resourceClay = vec3 0.75 0.1 0.0
resourceWood : Vec3
resourceWood = vec3 0.4 0.2 0.0
resourceOre : Vec3
resourceOre = vec3 0.3 0.2 0.3
resourceStone : Vec3
resourceStone = vec3 0.55 0.50 0.55
resourceGlass : Vec3
resourceGlass = vec3 0.0 0.6 0.8
resourcePapyrus : Vec3
resourcePapyrus = vec3 0.9 0.7 0.3
resourceLoom : Vec3
resourceLoom = vec3 0.9 0.0 0.9
-- Other parts
imageColor : Vec3
imageColor = vec3 0.4 0.4 0.0
resourceStripeColor : Vec3
resourceStripeColor = vec3 0.93 0.78 0.42

type alias RenderParameters =
  { atlas : TextureAtlas
  , font : Font
  }

render : RenderParameters -> Card -> (VertexList Text.Vertex, VertexList Image.Vertex)
render params card =
  let _ = ()
  in
    ( List.concat
      [ CardPart.background params.font (backgroundColor card.color)
      , CardPart.image params.font imageColor
      , CardPart.resourceStripe params.font resourceStripeColor
      , CardPart.text params.font (String.toUpper card.name)
      ]
    , List.concat
      [ renderEffect params.atlas card.effect
      ]
    )

renderResource : TextureAtlas -> Int -> VertexList Image.Vertex
renderResource atlas id =
  case id of
    0 -> Image.render atlas "Clay"
    1 -> Image.render atlas "Wood"
    2 -> Image.render atlas "Ore"
    3 -> Image.render atlas "Stone"
    4 -> Image.render atlas "Glass"
    --5 -> Primitive.octogon font resourcePapyrus
    --6 -> Primitive.octogon font resourceLoom
    _ -> Debug.todo "other resources"

renderEffect : TextureAtlas -> CardEffect -> VertexList Image.Vertex
renderEffect atlas effect =
  case effect of
    SingleResource resource ->
      CardPart.singleResource (renderResource atlas resource)
    EitherResource (r1, r2) ->
      CardPart.eitherResource
        (renderResource atlas r1)
        (Image.render atlas "GoldenSlash")
        (renderResource atlas r2)
    _ -> Debug.todo "other effects"