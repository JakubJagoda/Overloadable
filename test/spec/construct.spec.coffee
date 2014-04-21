describe "Library constructor", ->
    overloadableFunc = null

    beforeEach ->
        overloadableFunc = new Overloadable()
        
    describe ".prototype", ->
        propertyList = ["_invoke", "getDefault", "match", "overload"]
        it "should have all the properties non-enumerable", ->
            expect(Object.keys(Overloadable.prototype)).toEqual([])
        
        it "should have all the properties non-configurable", ->
            for property in propertyList
                expect( ->
                    Object.defineProperty Overloadable.prototype, property,
                        enumerable: true
                ).toThrow()
                
            expect(Object.keys(Overloadable)).toEqual([])
            
        it "should have all the properties non-writable", ->
            for property in propertyList
                oldValue = Overloadable.prototype[property]
                Overloadable.prototype[property] = null
                expect(Overloadable.prototype[property]).toEqual(oldValue)

    it "should construct a function", ->
        expect(typeof overloadableFunc).toBe "function"
        
    describe "Donstructed functions", ->
        it "should have a proper public api", ->
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
