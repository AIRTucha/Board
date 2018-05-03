var _airtucha$board$Native_Server = function(){
    const http = require('http');
    const hash = require('object-hash');
    const requests = new Map()
    const toArray = ( array ) => ({ ctor: '_Array', height: 0, table: array })
    const emptyDict = () => ({ ctor: 'RBEmpty_elm_builtin', _0: { ctor: 'LBlack' } } )
    const emptyList = () => ( { ctor: '[]' })
    const empty = () => ( {ctor: 'Empty'})
    const getMethod = (str) => {
        switch(str){
            case "GET": return { ctor: "Get" }
            case "POST": return { ctor: "Post" }
            case "PUT": return { ctor: "Put" }
            case "DELETE": return { ctor: "Delete" }
        }
    }
    const sendContent = handler => request => {
        const res = requests.get(request.id)
        if(!res)
            console.log('\x1b[33m%s\x1b[0m', "Error: " + request.id)
        requests.delete(request.id)
        return function( value ) {
            if(res)
                handler(value, res);
            return { type: 'node', branches: { ctor: '[]' } }
        }
    }
    const https = require('https')
    const sendPlainText = contentType => 
        sendContent(
            ( value, res ) => res.end(value) 
        )
    const getData = (content, contentType) => {
        if(content) {
            if ( "string" == typeof content ) {
                if( contentType == "application/json" )
                    return { 
                        ctor: 'JSON',
                        _0: content
                    }
                else
                    return {
                        ctor: 'Text',
                        _0: contentType,
                        _1: content
                    }
            } else
                return { 
                    ctor: 'Data',
                    _0: contentType,
                    _1: func => func(content)
                }
        } else    
            return {
                ctor: 'Empty',
            }
    }
    const getProtocol = (str) => ({ctor:str ? str.toUpperCase() : "HTTP"})
    const createServer = (port, protocol, reqHandler, closeHandler, options ) => 
        (
            options ? 
                protocol.createServer(reqHandler) 
                : 
                protocol.createServer(options, reqHandler)
        ).on('close', closeHandler)
         .listen(port)
    // setInterval(() => {

    // }, 1000)
    return {
        open: function (port){
            return function(maybeOptions) {
                return function(settings) {
                    const reqHandler = function (req, res) {
                        const timeToLive = 1000
                        const time = (new Date).getTime()
                        const id = hash( {
                            path: req.url, 
                            ip: req.connection.remoteAddress,
                            time: time,
                            ip: req.ip
                        } )
                        const address = req.connection.address()
                        const contentType = req.headers['content-type']
                        const cookies = req.headers['cookies']
                        let content = undefined
                        res.ttl = timeToLive * 1000 + time
                        requests.set( id, res )
                        // console.log('\x1b[33m%s\x1b[0m', "Req :" +id)
                        // console.log(req.url)
                        req
                            .on("data", data => {
                                content = data
                            } )
                            .on("end", () => {
                                const body = {    
                                    url : req.url,
                                    id : id,
                                    time : time,
                                    cookies : cookies || "",
                                    cargo: emptyDict(),
                                    content : getData(content, contentType),
                                    ip : address.address.toString(),
                                    host : req.headers.host,
                                    protocol : getProtocol(req.protocol),
                                    method: getMethod(req.method)
                                }
                                _elm_lang$core$Native_Scheduler.rawSpawn(
                                    settings.onRequest(body)(port)
                                );
                            })
                    }
                    const closeHandler = function () {
                        _elm_lang$core$Native_Scheduler.rawSpawn(settings.onClose(port)(maybeOptions));
                    }
                    if(maybeOptions.ctor == "Nothing")
                        return createServer(port, http, reqHandler, closeHandler)
                    else {
                        const options = Object.keys( maybeOptions._0 ).reduce((obj, key) => {
                            const maybeValue = maybeOptions._0[key]
                            obj[key] = maybeValue.ctor == "Nothing" ? undefined : maybeValue._0
                            return obj
                        }, {})
                        return createServer(port, http, reqHandler, closeHandler, options)
                    }
                  }
            }
        },
        sendData: sendContent( 
            ( value, res ) => value( v => res.end(v) ) 
        ),
        sendText: sendPlainText,
        sendJson: sendPlainText("application/json"),
        sendEmpty: sendContent(
            ( value, res ) => res.end() 
        ),
        close: function (server) {
            server.close();
            return { ctor: '_Tuple0' }
        }
    };
}();

