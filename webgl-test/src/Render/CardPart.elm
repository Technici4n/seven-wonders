module Render.CardPart exposing (background, eitherResource, image, resourceCost, resourceStripe, singleResource, text)

import Font exposing (Font)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Math.Vector4 as Vec4 exposing (vec4, Vec4)
import Render.Primitive as Primitive
import Render.Text as Text exposing (Vertex)
import Render.VertexList as VertexList exposing (PositionVertexList, VertexList)

chainTransforms : List (Mat4 -> Mat4) -> Mat4
chainTransforms =
  List.foldr (\t st -> t st) Mat4.identity

text : Font -> String -> VertexList Vertex
text font str =
  let
    -- rotate text by 90 degrees counter-clockwise
    rotateText = Mat4.rotate (degrees 90) (vec3 0.0 0.0 1.0)
    -- text has a height of 1.0 but it needs to be 0.1 relatively to a card
    scaleText = Mat4.scale3 cardTextHeight cardTextHeight 1.0
    translateText = Mat4.translate cardTextOffset
    transformationMatrix = chainTransforms [ rotateText, scaleText, translateText ]
  in
    Text.render font (vec3 0.0 0.0 0.0) str
    |> VertexList.transformPosition transformationMatrix

-- Card parameters
cardHeight : Float
cardHeight = 1.0
cardWidth : Float
cardWidth = 0.7
imageHeight : Float
imageHeight = 0.8
imageWidth : Float
imageWidth = 0.5
cardTextHeight : Float
cardTextHeight = 0.08
resourceStripeHeight : Float
resourceStripeHeight = 0.2
resourceStripeWidth : Float
resourceStripeWidth = 0.05
resourceHeight : Float
resourceHeight = 0.06
resourceWidth : Float
resourceWidth = resourceHeight
resourceSpacing : Float
resourceSpacing = 0.01
firstResourceSpacing : Float
firstResourceSpacing = 0.02

-- Computed offsets
cardTextOffset : Vec3
cardTextOffset = vec3 ((cardWidth - imageWidth + cardTextHeight) / 2) 0.05 0.001
imageOffset : Vec3
imageOffset = vec3 (cardWidth - imageWidth) 0.0 0.001
resourceStripeOffset : Vec3
resourceStripeOffset = vec3 ((cardWidth - imageWidth - resourceStripeWidth) / 2) (cardHeight - resourceStripeHeight) 0.0005
firstResourceOffset : Vec3
firstResourceOffset = vec3 ((cardWidth - imageWidth - resourceWidth) / 2) (cardHeight - resourceHeight - firstResourceSpacing) 0.001
relativeResourceOffset : Vec3
relativeResourceOffset = vec3 0.0 ( -1 * (resourceHeight + resourceSpacing) ) 0.0

-- Common card parts
background : Font -> Vec3 -> VertexList Vertex
background font color =
  let
    scaleToRectangle = Mat4.scale3 cardWidth cardHeight 1.0
    transformationMatrix = chainTransforms [ scaleToRectangle ]
  in
    Primitive.square font color
    |> VertexList.transformPosition transformationMatrix

image : Font -> Vec3 -> VertexList Vertex
image font color =
  let
    scaleToRectangle = Mat4.scale3 imageWidth imageHeight 1
    translateToBottomRight = Mat4.translate imageOffset
    transformationMatrix = chainTransforms [ scaleToRectangle, translateToBottomRight ]
  in
    Primitive.square font color
    |> VertexList.transformPosition transformationMatrix

resourceStripe : Font -> Vec3 -> VertexList Vertex
resourceStripe font color =
  let
    scaleToRectangle = Mat4.scale3 resourceStripeWidth resourceStripeHeight 1
    translate = Mat4.translate resourceStripeOffset
    transformationMatrix = chainTransforms [ scaleToRectangle, translate ]
  in
    Primitive.square font color
    |> VertexList.transformPosition transformationMatrix

resourceCost : List (VertexList Vertex) -> VertexList Vertex
resourceCost polygons =
  let
    scale = Mat4.scale3 resourceWidth resourceHeight 1
    appendPolygon polygon (triangles, offset) =
      ( List.concat
        [ triangles
        , polygon
          |> VertexList.transformPosition (chainTransforms [ scale, Mat4.translate offset ])
        ]
      , Vec3.add offset relativeResourceOffset
      )
  in
    polygons
    |> List.foldl appendPolygon ([], firstResourceOffset)
    |> Tuple.first

-- Effects
singleResourceSize : Float
singleResourceSize = 0.1
eitherResourceSpacing : Float
eitherResourceSpacing = 0.06
slashWidth = 0.25 * singleResourceSize
-- Computed
singleResourceOffset : Vec3
singleResourceOffset = vec3 (cardWidth - imageWidth + (imageWidth - singleResourceSize) / 2) (imageHeight + (cardHeight - imageHeight - singleResourceSize) / 2) 0.001
eitherResourceFirstOffset : Vec3
eitherResourceFirstOffset = vec3 (cardWidth - imageWidth + (imageWidth - 2 * singleResourceSize - eitherResourceSpacing) / 2) (imageHeight + (cardHeight - imageHeight - singleResourceSize) / 2) 0.001
eitherResourceSecondOffset : Vec3
eitherResourceSecondOffset = Vec3.add eitherResourceFirstOffset <| vec3 (singleResourceSize + eitherResourceSpacing) 0.0 0.0
eitherResourceSlashOffset : Vec3
eitherResourceSlashOffset = vec3 (cardWidth - imageWidth + (imageWidth - slashWidth) / 2) (imageHeight + (cardHeight - imageHeight - singleResourceSize) / 2) 0.001

singleResource : PositionVertexList a -> PositionVertexList a
singleResource polygon =
  polygon
  |> VertexList.transformPosition
    (chainTransforms
      [ Mat4.scale3 singleResourceSize singleResourceSize 1.0
      , Mat4.translate singleResourceOffset
      ])

eitherResource : PositionVertexList a -> PositionVertexList a -> PositionVertexList a -> PositionVertexList a
eitherResource poly1 slash poly2 =
  let
    scale = Mat4.scale3 singleResourceSize singleResourceSize 1.0
  in
    List.concat
      [ poly1
        |> VertexList.transformPosition
          (chainTransforms
            [ scale
            , Mat4.translate eitherResourceFirstOffset
            ])
      , slash
        |> VertexList.transformPosition
          (chainTransforms
            [ scale
            , Mat4.translate eitherResourceSlashOffset
            ])
      , poly2
        |> VertexList.transformPosition
          (chainTransforms
            [ scale
            , Mat4.translate eitherResourceSecondOffset
            ])
      ]