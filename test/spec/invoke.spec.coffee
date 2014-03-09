describe "Overloadad functions", ->
    overloadableFunction = null
    spiedFunction = jasmine.createSpy()

    describe "Default function", ->
        it "should throw error when default function isn't undefined or a function", ->           
            for item in [7, "foo", true, null, {}]
                expect(-> new Overloadable item).toThrow()
            
            expect(-> 
                new Overloadable(->)
            ).not.toThrow()
            
            expect(->
                new Overloadable
            ).not.toThrow()
            
        it "should throw error when called without any overloads and a default function", ->
            overloadableFunction = new Overloadable
            expect(overloadableFunction).toThrow()

        it "should not throw error when called without any overloads but with a default function", ->
            overloadableFunction = new Overloadable spiedFunction
            expect(overloadableFunction).not.toThrow()
            expect(spiedFunction).toHaveBeenCalled()
            
        it "should be able to return a default function", ->
            defaultFunction = ->
            overloadableFunction = new Overloadable defaultFunction
            expect(overloadableFunction.getDefault()).toBe(defaultFunction)
            
        it "should call the default function preserving this value", ->
            object = {}
            thisValues = []
            
            defaultFunction = ->
                thisValues.push this
                
            defaultFunction.call object
            
            overloadableFunction = new Overloadable defaultFunction
            overloadableFunction.call object
            
            expect(thisValues[0]).toBe thisValues[1]
            
        it "should call the default function preserving original arguments list", ->
            overloadableFunction = new Overloadable spiedFunction
            overloadableFunction 7, true, "foo"
            
            expect(spiedFunction).toHaveBeenCalledWith 7, true, "foo"

    describe "String arguments", ->
        testedTypesAndExamples = 
            number: 7
            boolean: true
            string: "foo"
            object: {}
            array: []
            function: ->
            regexp: /\./
        
        beforeEach ->
            overloadableFunction = new Overloadable
            spiedFunction.reset()
            
        getOtherTypeThan = (type) ->
            types = Object.getOwnPropertyNames testedTypesAndExamples
            randomType = type
                    
            while randomType is type
                randomType = types[Math.floor(Math.random() * types.length)]

            randomType
        
        for type, typeExample of testedTypesAndExamples 
            do (type, typeExample) ->
                anotherType = getOtherTypeThan type
                anotherTypeExample = testedTypesAndExamples[anotherType]
                           
                it "should match argument of type '#{type}'", ->
                    overloadableFunction.overload [type], spiedFunction
                    overloadableFunction typeExample
            
                    expect(spiedFunction).toHaveBeenCalled()
                    expect(spiedFunction).toHaveBeenCalledWith typeExample
                
                it "shouldn't match argument of type '#{type}' when given
                    argument of another type (randomly got '#{anotherType}')", ->
                    overloadableFunction.overload [type], spiedFunction
                
                    expect(->
                        overloadableFunction anotherTypeExample
                    ).toThrow()
                
                    expect(spiedFunction).not.toHaveBeenCalled()
               
                it "should choose correct signature when there are more than one", ->            
                    overloadableFunction.overload [type], spiedFunction
                    overloadableFunction.overload [anotherTypeExample], ->
                
                    overloadableFunction typeExample
                
                    expect(spiedFunction).toHaveBeenCalled()
                    expect(spiedFunction).toHaveBeenCalledWith typeExample
        return
