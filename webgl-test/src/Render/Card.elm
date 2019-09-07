--module Render.Card exposing (getBackground, getImage, getResourceStripe, getText)
module Render.Card exposing (getText)

import FontInfo exposing (LoadedFontInfo)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Math.Vector4 as Vec4 exposing (vec4, Vec4)
import Render.Font as Font
import Render.VertexList as VertexList

chainTransforms : List (Mat4 -> Mat4) -> Mat4
chainTransforms =
  List.foldr (\t st -> t st) Mat4.identity

getText : LoadedFontInfo -> String -> List (Font.Vertex, Font.Vertex, Font.Vertex)
getText fontInfo str =
  let
    -- rotate text by 90 degrees counter-clockwise
    rotateText = Mat4.rotate (degrees 90) (vec3 0.0 0.0 1.0)
    -- text has a height of 1.0 but it needs to be 0.1 relatively to a card
    scaleText = Mat4.scale3 cardTextHeight cardTextHeight 1.0
    translateText = Mat4.translate cardTextOffset
    transformationMatrix = chainTransforms [ rotateText, scaleText, translateText ]
  in
    Font.renderText fontInfo (vec3 0.0 0.0 0.0) str
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
resourceStripeWidth = 0.08

-- Computed offsets
cardTextOffset : Vec3
cardTextOffset = vec3 ((cardWidth - imageWidth + cardTextHeight) / 2) 0.05 0.001
imageOffset : Vec3
imageOffset = vec3 (cardWidth - imageWidth) 0.0 0.001
resourceStripeOffset : Vec3
resourceStripeOffset = vec3 ((cardWidth - imageWidth - resourceStripeWidth) / 2) (cardHeight - resourceStripeHeight) 0.0005

{-
getBackground : Vec3 -> List (Text.Vertex, Text.Vertex, Text.Vertex)
getBackground color =
  let
    scaleToRectangle = Mat4.scale3 cardWidth cardHeight 1.0
    transformationMatrix = chainTransforms [ scaleToRectangle ]
  in
    square color (vec3 0.0 0.0 0.0)
    |> VertexList.transformPosition transformationMatrix

getImage : Vec3 -> List (Text.Vertex, Text.Vertex, Text.Vertex)
getImage color =
  let
    scaleToRectangle = Mat4.scale3 imageWidth imageHeight 1
    translateToBottomRight = Mat4.translate imageOffset
    transformationMatrix = chainTransforms [ scaleToRectangle, translateToBottomRight ]
  in
    square color (vec3 0.0 0.0 0.0)
    |> VertexList.transformPosition transformationMatrix
  
getResourceStripe : Vec3 -> List (Text.Vertex, Text.Vertex, Text.Vertex)
getResourceStripe color =
  let
    scaleToRectangle = Mat4.scale3 resourceStripeWidth resourceStripeHeight 1
    translate = Mat4.translate resourceStripeOffset
    transformationMatrix = chainTransforms [ scaleToRectangle, translate ]
  in
    square color (vec3 0.0 0.0 0.0)
    |> VertexList.transformPosition transformationMatrix
-}