describe 'Overloadad functions', ->
    overloadableFunction = null
    spiedFunction = jasmine.createSpy()

    describe 'Default function', ->
        it 'should throw error when default function isn\'t undefined or a function', ->           
            for item in [7, 'foo', true, null, {}]
                expect(-> new Overloadable item).toThrow()
            
            expect(-> 
                new Overloadable(->)
            ).not.toThrow()
            
            expect(->
                new Overloadable
            ).not.toThrow()
            
        it 'should throw error when called without any overloads and a default function', ->
            overloadableFunction = new Overloadable
            expect(overloadableFunction).toThrow()

        it 'should not throw error when called without any overloads but with a default function', ->
            overloadableFunction = new Overloadable spiedFunction
            expect(overloadableFunction).not.toThrow()
            expect(spiedFunction).toHaveBeenCalled()
            
        it 'should be able to return a default function', ->
            defaultFunction = ->
            overloadableFunction = new Overloadable defaultFunction
            expect(overloadableFunction.getDefault()).toBe(defaultFunction)
            
        it 'should call the default function preserving this value', ->
            object = {}
            thisValues = []
            
            defaultFunction = ->
                thisValues.push this
                
            defaultFunction.call object
            
            overloadableFunction = new Overloadable defaultFunction
            overloadableFunction.call object
            
            expect(thisValues[0]).toBe thisValues[1]
            
        it 'should call the default function preserving original arguments list', ->
            overloadableFunction = new Overloadable spiedFunction
            overloadableFunction 7, true, 'foo'
            
            expect(spiedFunction).toHaveBeenCalledWith 7, true, 'foo'
