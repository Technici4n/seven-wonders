module Rectangle exposing (Rectangle, center, scaleTo, translate)


type alias Rectangle =
    { width : Float
    , height : Float
    , xpos : Float
    , ypos : Float
    }


elementsBounds : List Rectangle -> Maybe Rectangle
elementsBounds elements =
    let
        bounds =
            Maybe.map4 (\a b c d -> ( ( a, b ), ( c, d ) ))
                (elements |> List.map .xpos |> List.minimum)
                (elements |> List.map .ypos |> List.minimum)
                (elements |> List.map (\e -> e.xpos + e.width) |> List.maximum)
                (elements |> List.map (\e -> e.ypos + e.height) |> List.maximum)
    in
    Maybe.map
        (\( ( minx, miny ), ( maxx, maxy ) ) ->
            { width = maxx - minx
            , height = maxy - miny
            , xpos = minx
            , ypos = miny
            }
        )
        bounds


epsilon : Float
epsilon =
    1.0e-9


isEmpty : Rectangle -> Bool
isEmpty rect =
    abs rect.height < epsilon || abs rect.width < epsilon


translate : ( Float, Float ) -> Rectangle -> Rectangle
translate ( x, y ) source =
    { source
        | xpos = source.xpos + x
        , ypos = source.ypos + y
    }


scale : ( Float, Float ) -> Rectangle -> Rectangle
scale ( xfactor, yfactor ) source =
    { source
        | width = source.width * xfactor
        , height = source.height * yfactor
    }


transform : Rectangle -> Rectangle -> Rectangle -> Rectangle
transform from to source =
    source
        |> translate ( to.xpos - from.xpos, to.ypos - from.ypos )
        |> scale ( to.width / from.width, to.height / from.height )


{-| Rescale all the elements, so they fit in the given rectangle.
-}
scaleTo : Rectangle -> List Rectangle -> List Rectangle
scaleTo target elements =
    case elementsBounds elements of
        Just bounds ->
            if not (isEmpty bounds) then
                elements
                    |> List.map (transform bounds target)

            else
                []

        Nothing ->
            []


{-| Rescale then center all elements.
-}
center : Rectangle -> List Rectangle -> List Rectangle
center target elements =
    Debug.log "center" <|
        case elementsBounds (Tuple.first <| Debug.log "(elements, target)" ( elements, target )) of
            Just bounds ->
                if isEmpty bounds then
                    []

                else if bounds.width / bounds.height < target.width / target.height then
                    let
                        ratio =
                            target.height / bounds.height

                        transformRectangle element =
                            { width = element.width * ratio
                            , height = element.height * ratio
                            , xpos = (element.xpos - bounds.xpos) * ratio + target.xpos + (target.width - bounds.width * ratio) / 2
                            , ypos = (element.ypos - bounds.ypos) * ratio + target.ypos
                            }
                    in
                    List.map transformRectangle elements

                else
                    let
                        ratio =
                            target.width / bounds.width

                        transformRectangle element =
                            { width = element.width * ratio
                            , height = element.height * ratio
                            , xpos = (element.xpos - bounds.xpos) * ratio + target.xpos
                            , ypos = (element.ypos - bounds.ypos) * ratio + target.ypos + (target.height - bounds.height * ratio) / 2
                            }
                    in
                    List.map transformRectangle elements

            Nothing ->
                []
