module Render.Image exposing (fragmentShader, loadTexture, render, vertexShader, Vertex)

import Dict exposing (Dict)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (vec2, Vec2)
import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Render.VertexList as VertexList exposing (VertexList)
import Task exposing (Task)
import TextureAtlas exposing (TextureAtlas)
import WebGL exposing (Mesh, Shader)
import WebGL.Texture as Texture exposing (defaultOptions, Texture)

loadTexture : Task Texture.Error Texture
loadTexture =
  Texture.loadWith { defaultOptions | magnify = Texture.nearest, minify = Texture.nearest } "/textures.png"

render : TextureAtlas -> String -> VertexList Vertex
render atlas texture =
  let
    renderWithInfo imageInfo =
      let
        atlasHeight = atlas.common.height
        atlasWidth = atlas.common.width
        uv_tl = vec2 (imageInfo.x1 / atlasWidth) (imageInfo.y1 / atlasHeight)
        uv_tr = vec2 (imageInfo.x2 / atlasWidth) (imageInfo.y1 / atlasHeight)
        uv_br = vec2 (imageInfo.x2 / atlasWidth) (imageInfo.y2 / atlasHeight)
        uv_bl = vec2 (imageInfo.x1 / atlasWidth) (imageInfo.y2 / atlasHeight)
        height = Debug.log "height" <| imageInfo.y2 - imageInfo.y1
        width = Debug.log "width" <| imageInfo.x2 - imageInfo.x1
        xy_tl = vec3 0.0 1.0 0.0
        xy_tr = vec3 (1.0 / height * width) 1.0 0.0
        xy_br = vec3 (1.0 / height * width) 0.0 0.0
        xy_bl = vec3 0.0 0.0 0.0
        v uv xy = Vertex xy uv
        a = v uv_tl xy_tl
        b = v uv_tr xy_tr
        c = v uv_br xy_br
        d = v uv_bl xy_bl
      in
        VertexList.fromFace a b c d
  in
    Dict.get texture atlas.textures
    |> Maybe.map renderWithInfo
    |> Maybe.withDefault []

type alias Vertex =
  { position : Vec3
  , texturePos : Vec2
  }

type alias Uniforms =
  { perspective : Mat4
  , texture : Texture
  }

type alias Varying =
  { vtexturePos : Vec2
  }


vertexShader : Shader Vertex Uniforms Varying
vertexShader =
  [glsl|
    attribute vec3 position;
    attribute vec2 texturePos;
    uniform mat4 perspective;
    varying vec2 vtexturePos;

    void main() {
      gl_Position = perspective * vec4(position, 1.0);
      vtexturePos = texturePos;
    }
  |]

fragmentShader : Shader {} Uniforms Varying
fragmentShader =
  [glsl|
    uniform sampler2D texture;
    precision mediump float;
    varying vec2 vtexturePos;

    void main() {
      gl_FragColor = texture2D(texture, vtexturePos);
    }
  |]