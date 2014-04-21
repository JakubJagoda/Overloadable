describe "Overloading functions", ->
    overloadableFunc = null;

    beforeEach ->
        overloadableFunc = new Overloadable();

    it "Should not allow for passing incorrect arguments to 'overload' function", ->
        expect( ->
            overloadableFunc.overload()
        ).toThrow()

        expect( ->
            overloadableFunc.overload null
        ).toThrow()

        expect( ->
            overloadableFunc.overload null, null
        ).toThrow()
        
    it "Should accept string arguments", ->
        expect( ->
            overloadableFunc.overload "null", ->
        ).not.toThrow()
        
    it "Should accept array arguments", ->
        expect( ->
            overloadableFunc.overload ["null", "null"], ->
        ).not.toThrow()