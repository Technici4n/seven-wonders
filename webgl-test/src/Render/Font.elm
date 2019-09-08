module Render.Font exposing (fragmentText, loadTexture, renderText, vertexText, Vertex)

import Dict as Dict
import FontInfo exposing (CharInfo, CommonInfo, LoadedFontInfo)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (vec2, Vec2)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Render.VertexList as VertexList exposing (VertexList)
import Task exposing (Task)
import WebGL exposing (Mesh, Shader)
import WebGL.Texture as Texture exposing (defaultOptions, Texture)

loadTexture : Task Texture.Error Texture
loadTexture =
  Texture.loadWith { defaultOptions | minify = Texture.nearest } "/font.png"


renderText : LoadedFontInfo -> Vec3 -> String -> VertexList Vertex
renderText fontInfo color text =
  let
    initialState = ([], 0)
    appendLetter charInfo (triangles, totalAdvance) =
      ( List.concat
        [ triangles
        , renderLetter fontInfo color charInfo totalAdvance
        ]
      , totalAdvance + charInfo.xadvance
      )
  in
    text
    |> String.toList
    |> List.filterMap (\char -> Dict.get (String.fromChar char) fontInfo.dict)
    |> List.foldl appendLetter initialState
    |> Tuple.first

renderLetter : LoadedFontInfo -> Vec3 -> CharInfo -> Int -> VertexList Vertex
renderLetter info color charInfo totalAdvance =
  let
    imageHeight = toFloat info.commonInfo.scaleH
    imageWidth = toFloat info.commonInfo.scaleW
    x = toFloat charInfo.x
    y = toFloat charInfo.y
    width = toFloat charInfo.width
    height = toFloat charInfo.height
    uv_tl = vec2 (x / imageWidth) (y / imageHeight)
    uv_tr = vec2 ((x+width) / imageWidth) (y / imageHeight)
    uv_br = vec2 ((x+width) / imageWidth) ((y+height) / imageHeight)
    uv_bl = vec2 (x / imageWidth) ((y+height) / imageHeight)
    lineHeight = toFloat info.commonInfo.lineHeight
    xy_tl = vec2 (0.0) (height / lineHeight)
    xy_tr = vec2 (width / lineHeight) (height / lineHeight)
    xy_br = vec2 (width / lineHeight) (0.0)
    xy_bl = vec2 (0.0) (0.0)
    offset =
      vec3
        ((toFloat <| totalAdvance + charInfo.xoffset) / lineHeight)
        ((toFloat <| charInfo.yoffset) / lineHeight)
        0.0
    toVec3 v2 =
      let xy = Vec2.toRecord v2
      in vec3 xy.x xy.y 0.0
    vertex uv xy =
      { color = color
      , position = Vec3.add (toVec3 xy) offset
      , texturePos = uv
      }
    a = vertex uv_tl xy_tl
    b = vertex uv_tr xy_tr
    c = vertex uv_br xy_br
    d = vertex uv_bl xy_bl
  in
    VertexList.fromFace a b c d

type alias Vertex =
  { color : Vec3
  , position : Vec3
  , texturePos : Vec2
  }

type alias Uniforms =
  { perspective : Mat4
  , texture : Texture
  }

type alias Varying =
  { vcolor : Vec3
  , vtexturePos : Vec2
  }

vertexText : Shader Vertex Uniforms Varying
vertexText =
  [glsl|
    attribute vec3 color;
    attribute vec3 position;
    attribute vec2 texturePos;
    uniform mat4 perspective;
    varying vec3 vcolor;
    varying vec2 vtexturePos;

    void main() {
      gl_Position = perspective * vec4(position, 1.0);
      vcolor = color;
      vtexturePos = texturePos;
    }
  |]

fragmentText : Shader {} Uniforms Varying
fragmentText =
  [glsl|
    uniform sampler2D texture;
    precision lowp float;
    varying vec3 vcolor;
    precision mediump float;
    varying vec2 vtexturePos;
    float buffer = 0.5;
    float gamma = 0.2;

    void main() {
      float dist = texture2D(texture, vtexturePos).a;
      float alpha = smoothstep(buffer - gamma, buffer + gamma, dist);
      gl_FragColor = vec4(vcolor.rgb, alpha);
    }
  |]