Overloadable = (defaultFunction) ->
    if typeof defaultFunction isnt 'function' and typeof defaultFunction isnt 'undefined'
    then throw new TypeError 'If passed, argument defaultFunction must be a function'
    
    signaturesContainer = []
    overloadableFunction = ->
        invoke.call this, signaturesContainer, arguments, defaultFunction
        
    overloadableFunction.overload = overload.bind signaturesContainer
    overloadableFunction.getDefault = ->
        defaultFunction
    
    overloadableFunction
    
overload = ->
invoke = (signaturesContainer, argumentsList, defaultFunction) ->
    if defaultFunction then defaultFunction.apply(this, argumentsList)
    else throw new Error
    
@Overloadable = Overloadable