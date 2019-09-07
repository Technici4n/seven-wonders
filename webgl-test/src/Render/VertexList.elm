module Render.VertexList exposing (..)

import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)

type alias VertexList a = List (a, a, a)

tripletMap : (a -> b) -> (a, a, a) -> (b, b, b)
tripletMap f (a, b, c) = (f a, f b, f c)

map : (a -> b) -> VertexList a -> VertexList b
map f input =
  input
  |> List.map (tripletMap f)

fromFace : a -> a -> a -> a -> VertexList a
fromFace a b c d =
  [ (a, b, c)
  , (c, d, a)
  ]

transformPosition : Mat4 -> VertexList { a | position : Vec3} -> VertexList { a | position : Vec3 }
transformPosition f input =
  input
  |> map (\v -> { v | position = Mat4.transform f v.position })