module Board.Router.InternalsTest exposing (..)

{-| Test different combinations of routing functions and HTTP Methods
-}

import Ordeal exposing (Test, success, test, describe, shouldEqual, andTest, failure, all, and)
import Board.Router.Internals exposing(..)
import Board.Shared exposing (..)
import Pathfinder exposing (any, str, int)
import Board.Internals exposing(..)
import List exposing (concat, map)
import Task exposing (succeed, andThen)
import Dict exposing (empty)

{-| Create fake HTTP Request
-}
getRequest : Method -> Request a
getRequest method =
    { url = "example.com"
    , id = "0"
    , time = 0
    , content = Empty
    , cookies = Dict.empty
    , cargo = Dict.empty
    , ip = "0"
    , host = "example"
    , protocol = HTTP
    , method = method
    }

{-| Hardcoded url
-}
url : String
url = "test"


{-| Hardcoded state
-}
model : String
model =
    "model"


{-| Produce text response for specifed Request
-}
response : Request a -> String -> AnswerValue a1 model error
response req str = 
    let 
        res = getResponse req
    in 
        Reply { res | content = Text "text/plain" str }


{-| Produce next response for specifed Request
-}
next : Request a -> String -> AnswerValue a model error
next req str =
    Next { req | content = Text "text/plain" str }


{-| Produce redirect response for any Request
-}
redirect : Request a -> String -> AnswerValue value model error
redirect _ str =
    Redirect str


{-| Test equality for one of internal types of router return value
-}
eqaulValues : Answer value String String -> Answer value String String -> Ordeal.Expectation
eqaulValues sync1 sync2 =
     case sync1 of
        StateLess value1 ->
            case sync2 of
                StateLess value2 ->
                    shouldEqual value1 value2

                StateFull value2 ->
                    failure "The first arg is stateless, while second one is statefull"

        StateFull value1 ->
            case sync2 of
                StateLess value2 ->
                    failure "The first arg is stateless, while second one is statefull"

                StateFull value2 ->
                    let 
                        (model1, answer1) = value1 model
                        (model2, answer2) = value2 model
                        areModelsEqual = shouldEqual model1 model2
                        areAnswersEqual = equal answer1 answer2
                    in  
                        and areModelsEqual areAnswersEqual


{-| Test equality for router return type
-}
equal : Mode String (Answer value String String) -> Mode String (Answer value String String) -> Ordeal.Expectation
equal v1 v2 =
    case v1 of
        Sync sync1 ->
            case v2 of
                Sync sync2 ->
                   eqaulValues sync1 sync2

                Async async2 ->
                    failure "The first arg is sync, while second one is async"

        Async async1 ->
            case v2 of
                Sync sync2 ->
                    failure "The first arg is async, while second one is sync"

                Async async2 ->
                    async1
                        |> andThen ( \ sync1 -> async2 |> Task.map (\ sync2 -> (sync1, sync2) ))
                        |> andTest (\ value ->
                            case value of 
                                Ok (value1, value2) ->
                                    eqaulValues value1 value2
                                
                                Err str ->
                                    failure str
                        )


{-| Turns brief test descript into detailed one to run tests
-}
createTestDesciption description =
    let 
        reply = getResponse >> Reply
        redirectRoute mode _ = 
            url
                |> Redirect
                |> mode
    in
        { router = description.router
        , name = description.name 
        , handlersMode = description.handlersMode
        , tests = 
            [ { name = "Sync Router"
              , responseRoute = reply >> stateLessSync
              , redirectRoute = redirectRoute stateLessSync  
              , nextRoute = nextStateLessSync
              , handlerResult = description.syncRouterResultHandler 
              }
            , { name = "Async Router"
              , responseRoute = reply >> toStatelessAsync
              , redirectRoute = redirectRoute toStatelessAsync
              , nextRoute = stateLessAsyncNext
              , handlerResult = description.asyncRouterResultHandler 
              }
            , { name = "Sync State Router"
              , responseRoute = stateFullSyncRouter response
              , redirectRoute = stateFullSyncRouter redirect
              , nextRoute = stateFullSyncNext
              , handlerResult = description.syncStateRouterResultHandler 
              }
            , { name = "Async State Router"
              , responseRoute = stateFullAsyncRouter response
              , redirectRoute = stateFullAsyncRouter redirect
              , nextRoute = stateFullAsyncNext
              , handlerResult = description.asyncStateRouterResultHandler 
              }
            ]
        }


{-| Partially applied function which verifies correctness of router result for synchronous stateless hanlder
-}
idResult = 
    result identity


{-| Partially applied function which verifies correctness of router result for synchronous stateful hanlder
-}
syncStateHandlerResult =
    result toSyncStateHandler


{-| Test description for synchronous stateless path handler
-}
testsSyncStatelessHandler = 
    createTestDesciption
        { router = syncRouter
        , name = "Sync StateLess Handler" 
        , handlersMode = identity
        , syncRouterResultHandler =
            idResult nextStateLessSync stateLessSync 
        , asyncRouterResultHandler = 
            idResult stateLessAsyncNext toStatelessAsync 
        , syncStateRouterResultHandler =
            syncStateHandlerResult stateFullSyncNext stateFullSync 
        , asyncStateRouterResultHandler =
            syncStateHandlerResult stateFullAsyncNext stateFullAsync 
        }


{-| Test description for asynchronous stateless path handler
-}
testsAsyncStatelessHandler =
    let 
        asyncStateHandlerResult =
            result toAsyncStateHandler
    in
        createTestDesciption
            { router = asyncRouter
            , name = "Async StateLess Handler" 
            , handlersMode = (<<) succeed
            , syncRouterResultHandler =
                idResult nextStateLessSync toStatelessAsync 
            , asyncRouterResultHandler =
                idResult stateLessAsyncNext toStatelessAsync 
            , syncStateRouterResultHandler =
                asyncStateHandlerResult stateFullSyncNext stateFullSync 
            , asyncStateRouterResultHandler = 
                asyncStateHandlerResult stateFullAsyncNext stateFullAsync 
            }


{-| Test description for synchronous stateful path handler
-}
testsSyncStatefullHandler =
    createTestDesciption
        { router = syncStateRouter
        , name = "Sync StateFull Handler" 
        , handlersMode = toStateFullHanlder
        , syncRouterResultHandler =
            syncStateHandlerResult nextStateLessSync stateFullSync 
        , asyncRouterResultHandler =
            syncStateHandlerResult stateLessAsyncNext stateFullAsync 
        , syncStateRouterResultHandler = 
            result (toStateFulRouter stateLessSync >> (toStateFulRouter stateFullSync)) stateFullSyncNext stateFullSync 
        , asyncStateRouterResultHandler =
            result (toAsyncStateHandlerStateFull stateFullSync) stateFullAsyncNext stateFullAsync
        }


{-| Test description for asynchronous stateful path handler
-}
testsAsyncStatefullHandler =
    let
        asyncStateHandlerAsyncStateFullResult = 
            result <| toAsyncStateHandlerStateFull stateFullAsync
    in
        createTestDesciption
            { router = asyncStateRouter
            , name = "Async StateFull Handler" 
            , handlersMode = \ f -> (toStateFullHanlder f) >> succeed
            , syncRouterResultHandler =
                syncStateHandlerResult nextStateLessSync stateFullAsync 
            , asyncRouterResultHandler = 
                syncStateHandlerResult stateLessAsyncNext stateFullAsync 
            , syncStateRouterResultHandler =
                asyncStateHandlerAsyncStateFullResult stateFullSyncNext stateFullSync 
            , asyncStateRouterResultHandler =
                asyncStateHandlerAsyncStateFullResult stateFullAsyncNext stateFullAsync 
            }


{-| Test routing over estiblished list of cases
-}
testCheckerAndMethod { router, name, handlersMode, tests } (chekcer, method, confName) =
  let 
    req = getRequest method
    runTests req cases =
        let 
            handlerResult = cases.handlerResult req chekcer 
            getHandler hanlder (param, req) =
                case param of
                    StrParam str ->
                        hanlder req str
                    
                    _ -> 
                        Next req
            toNext = 
                handlersMode <| getHandler next
        in
            describe cases.name
                [ test "Router Response" (   
                    router chekcer any toNext (cases.responseRoute) req
                        |> equal (cases.responseRoute req)
                )
                , test "Router Redirect" (
                    router chekcer any toNext (cases.redirectRoute) req
                        |> equal (cases.redirectRoute req)
                )
                , describe "Router Next"
                    [ test "Handler Redirect" ( 
                        router chekcer str (handlersMode <| getHandler redirect) cases.nextRoute req
                            |> equal (handlerResult redirect )
                    )
                    , test "Handler Reply" ( 
                        router chekcer str (handlersMode <| getHandler response) cases.nextRoute req
                            |> equal (handlerResult response ) 
                    ) 
                    , test "Handler Next" (
                        router chekcer str toNext cases.nextRoute req
                            |> equal (handlerResult next )  
                    ) 
                    , test "Hanler URL does not match" ( 
                        router chekcer int toNext cases.nextRoute req
                            |> equal (cases.nextRoute req)  
                    )
                    ]
                ]
  in
    describe ( name ++ ": " ++ confName ) <| map ( runTests { req | url = url } ) tests
    
        
{- Test router for different HTTP method combinations
-}
routerInternals : Test
routerInternals =
    let 
        jounMethodToChecker (checker, checkerName) (method, methodName) =
            (checker, method, "Expects " ++ checkerName ++ ", received " ++ methodName)
        joinCheckerToMethods checkerTuple =
            [ ( Get, "Get" )
            , ( Post, "Post" )
            , ( Put, "Put" )
            , ( Delete, "Delete" )
            ]
                |> map (jounMethodToChecker checkerTuple)
        methodTestCases =
            [ ( isGet, "Get" )
            , ( isPost, "Post" )
            , ( isPut, "Put" )
            , ( isDelete, "Delete" )
            , ( anyMethod, "Any" )
            ] 
                |> map joinCheckerToMethods
                |> concat
    in
        describe "Router Interlan logic" <|
            (map (testCheckerAndMethod testsSyncStatelessHandler) methodTestCases) ++
            (map (testCheckerAndMethod testsAsyncStatelessHandler) methodTestCases) ++
            (map (testCheckerAndMethod testsSyncStatefullHandler) methodTestCases) ++ 
            (map (testCheckerAndMethod testsAsyncStatefullHandler) methodTestCases)


-- Varios small functions which are used at test descriptions

{-| Combine several functions, it is utilized for verification of routing
-}
result : (a -> b -> String -> c) -> (b -> d) -> (c -> d) -> b -> (b -> Bool) -> a -> d
result mode mismatchHandler matchMode req checker =
    let 
        getResult matchHandler =
            if checker req then 
                matchMode <| matchHandler req url
            else 
                mismatchHandler req
    in
        mode >> getResult


toStateFullHanlder handler args model =
    (model, handler args)
    

toStatelessAsync =
    succeed >> stateLessAsync


toStateFulRouter mode reqToValue req str model =
    (model, mode <| reqToValue req str )


toSyncStateHandler =
    toStateFulRouter stateLessSync


stateFullSyncRouter reqToValue req = 
    stateFullSync <| toSyncStateHandler reqToValue req req.url


stateLessAsyncNext = 
    Next >> toStatelessAsync


stateFullSyncNext =
    stateFullSyncRouter next


stateFullAsyncRouter reqToValue req = 
    stateFullAsync <| toSyncStateHandler reqToValue req req.url


stateFullAsyncNext =
    stateFullAsyncRouter next


toAsyncStateHandler =
    toStateFulRouter (toStatelessAsync)


toAsyncStateHandlerStateFull mode handler = 
    toStateFulRouter mode (\ a s m -> (m, stateLessSync <| handler a s))