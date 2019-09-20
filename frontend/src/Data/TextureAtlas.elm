module Data.TextureAtlas exposing (CommonInfo, ImageInfo, TextureAtlas, textureAtlasDecoder)

import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder, field, float, index, int, list, string)


textureAtlasDecoder : Decoder TextureAtlas
textureAtlasDecoder =
    Decode.map buildLoadedTextureAtlas decodeRawTextureAtlas


buildLoadedTextureAtlas : RawTextureAtlas -> TextureAtlas
buildLoadedTextureAtlas atlas =
    { textures =
        atlas.images
            |> List.map (\imageInfo -> ( imageInfo.name, imageInfo ))
            |> Dict.fromList
    , common = atlas.metadata
    }


type alias TextureAtlas =
    { textures : Dict String ImageInfo
    , common : CommonInfo
    }


type alias RawTextureAtlas =
    { images : List ImageInfo
    , metadata : CommonInfo
    }


type alias ImageInfo =
    { name : String
    , x1 : Float
    , x2 : Float
    , y1 : Float
    , y2 : Float
    }


type alias CommonInfo =
    { width : Float
    , height : Float
    }


decodeRawTextureAtlas : Decoder RawTextureAtlas
decodeRawTextureAtlas =
    Decode.map2 RawTextureAtlas
        (field "images" (list decodeImageInfo))
        (field "metadata" decodeCommonInfo)


decodeImageInfo : Decoder ImageInfo
decodeImageInfo =
    Decode.map5 ImageInfo
        (field "name" string)
        (field "position" (index 0 (index 0 float)))
        (field "position" (index 1 (index 0 float)))
        (field "position" (index 0 (index 1 float)))
        (field "position" (index 1 (index 1 float)))


decodeCommonInfo : Decoder CommonInfo
decodeCommonInfo =
    Decode.map2 CommonInfo
        (field "size" (index 0 float))
        (field "size" (index 1 float))
