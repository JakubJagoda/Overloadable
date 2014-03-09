describe "Library constructor", ->
    overloadableFunc = null
    spiedFunction = jasmine.createSpy()

    beforeEach ->
        overloadableFunc = new Overloadable()

    it "Should construct a function", ->
        expect(typeof overloadableFunc).toBe "function"

    it "Should have overload property, also a function", ->
        expect(typeof overloadableFunc.overload).toBe "function"

    describe "Default function", ->
        it "should throw error when default function isn't undefined or a function", ->           
            for item in [7, "foo", true, null, {}]
                expect(->
                    new Overloadable item
                ).toThrow()
            
            expect(-> 
                new Overloadable(->)
            ).not.toThrow()
            
            expect(->
                new Overloadable
            ).not.toThrow()
            
        it "should be able to return a default function", ->
            defaultFunction = ->
            overloadableFunction = new Overloadable defaultFunction
            expect(overloadableFunction.getDefault()).toBe defaultFunction 
