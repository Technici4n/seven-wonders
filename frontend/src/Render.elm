module Render exposing (mergeParts, toEntities, transformPosition, ScenePart)

import A_Model exposing (Textures)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Render.Image as Image
import Render.Text as Text
import Render.VertexList as VertexList exposing (VertexList)
import WebGL
import WebGL.Settings
import WebGL.Settings.Blend as Blend
import WebGL.Settings.DepthTest as DepthTest

type alias ScenePart =
  { images : VertexList Image.Vertex
  , text : VertexList Text.Vertex
  }

mergeParts : List ScenePart -> ScenePart
mergeParts =
  List.foldl (\sp {images, text} -> {images=images++sp.images,text=text++sp.text}) {images=[],text=[]}

transformPosition : Mat4 -> ScenePart -> ScenePart
transformPosition f sp =
  { images = VertexList.transformPosition f sp.images
  , text = VertexList.transformPosition f sp.text
  }

entityParameters : List WebGL.Settings.Setting
entityParameters =
  [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha
  , DepthTest.default
  ]

toEntities : Textures -> List ScenePart -> List WebGL.Entity
toEntities textures parts =
  let
    perspective = Mat4.makeOrtho2D 0.0 (16/9) 0.0 1.0
    drawImages =
      WebGL.entityWith
        entityParameters
        Image.vertexShader
        Image.fragmentShader
        (WebGL.triangles <| List.concat <| List.map (\p -> p.images) parts)
        { perspective = perspective, texture = textures.atlas }
    drawText =
      WebGL.entityWith
        entityParameters
        Text.vertexShader
        Text.fragmentShader
        (WebGL.triangles <| List.concat <| List.map (\p -> p.text) parts)
        { perspective = perspective, texture = textures.text }
  in
    [ drawImages
    , drawText
    ]