var _airtucha$board$Native_File = function() {
    var scheduler = _elm_lang$core$Native_Scheduler
    var fs = require('fs');
    return {
        read: function(path) {
            return scheduler.nativeBinding(function (callback) {
                fs.readFile(path, function( error, content ) {
                    if (error) 
                        return callback(scheduler.fail(error))
                    else 
                        return callback(scheduler.succeed(content.toString('HEX')))
                })
            })
        },
        write: function(path) {
            return function(data) {
                return scheduler.nativeBinding(function (callback) {
                    fs.writeFile(path, data, function( error ) {
                        if (error) 
                            return callback(scheduler.fail(error))
                        else 
                            return callback(scheduler.succeed( { ctor: '_Tuple0' }))
                    })
                })
            }
        }
    }
}()