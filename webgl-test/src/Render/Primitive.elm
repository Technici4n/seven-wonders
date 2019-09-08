module Render.Primitive exposing (octogon, square)

import Dict
import FontInfo exposing (LoadedFontInfo)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (vec2, Vec2)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Render.Font exposing (Vertex)
import Render.VertexList as VertexList exposing (VertexList)

whitestUv : LoadedFontInfo -> Vec2
whitestUv fontInfo =
  let (whitex, whitey) = fontInfo.commonInfo.whitestCell
  in
    vec2
      (toFloat whitex / toFloat fontInfo.commonInfo.scaleW)
      (toFloat whitey / toFloat fontInfo.commonInfo.scaleH)

square : LoadedFontInfo -> Vec3 -> VertexList Vertex
square fontInfo color =
  let
    tl = vec3 0.0 1.0 0.0
    tr = vec3 1.0 1.0 0.0
    br = vec3 1.0 0.0 0.0
    bl = vec3 0.0 0.0 0.0
    vertex xyz =
      { color = color
      , position = xyz
      , texturePos = whitestUv fontInfo
      }
    a = vertex tl
    b = vertex tr
    c = vertex br
    d = vertex bl
  in
    VertexList.fromFace a b c d

octogon : LoadedFontInfo -> Vec3 -> VertexList Vertex
octogon fontInfo color =
  let
    size = 1.0
    halfTriangleAngle = degrees 22.5
    halfTriangleSide = size / 2
    halfSide = halfTriangleSide * tan halfTriangleAngle
    vertex xyz =
      { color = color
      , position = xyz
      , texturePos = whitestUv fontInfo
      }
    a = vertex <| vec3 0.0 (0.5 - halfSide) 0.0
    b = vertex <| vec3 0.0 (0.5 + halfSide) 0.0
    c = vertex <| vec3 (0.5 - halfSide) 1.0 0.0
    d = vertex <| vec3 (0.5 + halfSide) 1.0 0.0
    e = vertex <| vec3 1.0 (0.5 + halfSide) 0.0
    f = vertex <| vec3 1.0 (0.5 - halfSide) 0.0
    g = vertex <| vec3 (0.5 + halfSide) 0.0 0.0
    h = vertex <| vec3 (0.5 - halfSide) 0.0 0.0
  in
    [ (a, b, c)
    , (a, c, d)
    , (a, d, e)
    , (a, e, f)
    , (a, f, g)
    , (a, g, h)
    ]