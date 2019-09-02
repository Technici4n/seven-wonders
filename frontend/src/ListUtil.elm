module ListUtil exposing (..)

import Array

enumerate : List a -> List (Int, a)
enumerate = List.indexedMap Tuple.pair

findIndex : a -> List a -> Maybe Int
findIndex target list =
  list
  |> enumerate
  |> List.filter (\(i, element) -> element == target)
  |> List.map Tuple.first
  |> get 0

get : Int -> List a -> Maybe a
get index = Array.fromList >> Array.get index