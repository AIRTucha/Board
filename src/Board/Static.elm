module Board.Static exposing (..)

import Pathfinder exposing (..)
import Task
import Board.Shared exposing (..)
import Basics exposing (..)
import Board.File exposing(read, getContentType)
import Board.Status exposing (..)
import Dict
import Board.Router exposing (..)


static basePath prefix router =
    router
        |> get (basePath </> str) (getFile prefix)


getFile prefix (param, req) =
    let 
        next = req
            |> Next
            |> Task.succeed
    in
        case param of 
            StrParam path ->
                prefix ++ path
                    |> read
                    |> Task.map (makeResponse path req)
                    |> Task.map Reply
                    |> Task.onError (onGetFileError next)
            
            _ ->
                next


onGetFileError value _ =
    value


makeResponse path req file = 
    let 
        res = getResponse req
    in
        { res
        | content = Data (getContentType path) file
        , status = custom 200
        , header =  Dict.insert "Server" "test" <| Dict.insert "Cache-Control" "public" res.header
        , id = req.id
        }