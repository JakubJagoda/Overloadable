Overloadable = (defaultFunction) ->
    signaturesContainer = []
    overloadableFunction = ->
        
    overloadableFunction.overload = overload.bind signaturesContainer
    overloadableFunction.getDefault = ->
        defaultFunction
    
    overloadableFunction
    
overload = ->
    
@Overloadable = Overloadable