module App exposing (..)

import Platform
import Server exposing (ReqValue, Request(Get), Content, response, Response)
import Task
import File exposing(read)
import Path.Generic exposing (takeExtension)
import String exposing (toLower)
import Debug exposing (log)
import Console exposing(println)
import Bytes exposing(Bytes)
import Pathfinder exposing (..)
import Board exposing (..)

urlParser url =
    if url == "/" then 
        "./public/index.html" 
    else 
        "./public" ++ url

main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


typeParser : String -> String
typeParser path =
    case toLower << takeExtension <| path of
        ".html" ->
            "text/html"

        ".js" ->
            "text/javascript"
        
        ".json" ->
            "application/json"

        ".png" ->
            "image/png"
        
        ".jpg" ->
            "image/jpg"

        ".gif" ->
            "image/gif"

        ".wav" ->
            "audio/wav'"
        
        ".mp4" ->
            "video/mp4"
        
        ".woff" ->
            "application/font-woff"
        
        ".ttf" ->
            "application/font-ttf"
        
        ".eot" ->
            "application/vnd.ms-fontobject"

        ".otf" ->
            "application/font-otf"
        
        ".svg" ->
            "application/image/svg+xml"
        
        _  ->
            "application/octet-stream'"


type alias Model =
    Int


init : ( Model, Cmd Msg )
init =
    ( 0, Cmd.none )


type Msg
    = Input Server.Message
    | Send Response
 

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Input request ->
            case request of 
                Ok req ->
                    case server req of
                        _ ->
                            (model, Cmd.none)

                Err msg ->
                    log msg ( model, Cmd.none)

        Send res ->
            Server.send res
                |> (\ _ -> ( model, Cmd.none) )

server = 
    empty 
        -- |> get (p "/") (getFile "") getIndex
        -- |> get (p "/public/") (getFile "") getIndex
        -- |> get (p "/public") (getFile "") getIndex
        -- |> get (p "/public/index.html") (getFile "") getIndex
        -- |> get (p "/public/app.js") getApp
        -- |> get (p "/public/styles.css") getStyles
        |> use any (redirect "/")

-- getIndex _ =
--     getFile "./public/index.html" 


-- getApp _ =
--     getFile "./public/app.js" 


-- getStyles _ =
--     getFile "./public/styles.css" 


redirect str _ =
    Board.Async <| Task.succeed <| Board.Redirect str

-- getFile path (param, req)  =
--     path
--         |> read
--         |> Task.map (makeResponse req)
--         |> Task.map Board.Reply
--         |> Board.Async


makeResponse req file = 
    let 
        res = response
    in
        { res
        | content = Server.File "test" file
        , id = req.id
        } 


subscriptions : Model -> Sub Msg
subscriptions model =
    Server.listen 8080 Input
    
    