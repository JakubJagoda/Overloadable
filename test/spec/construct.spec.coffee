describe "Library constructor", ->
    overloadableFunc = null

    beforeEach ->
        overloadableFunc = new Overloadable()

    it "Should construct a function", ->
        expect(typeof overloadableFunc).toBe "function"

    it "Should have a proper public api", ->
        publicApi = ["overload", "getDefault", "match"]
        for method in publicApi
            expect(typeof overloadableFunc[method]).toBe "function"

    describe "Default function", ->
        it "should throw error when default function isn't undefined, null or a function", ->           
            for item in [7, "foo", true, {}]
                expect(->
                    new Overloadable item
                ).toThrow()
            
            expect(-> 
                new Overloadable(->)
            ).not.toThrow()
            
            expect(->
                new Overloadable
            ).not.toThrow()
            
            expect(->
                new Overloadable null
            ).not.toThrow()
            
        it "should be able to return a default function", ->
            defaultFunction = ->
            overloadableFunction = new Overloadable defaultFunction
            expect(overloadableFunction.getDefault()).toBe defaultFunction 
