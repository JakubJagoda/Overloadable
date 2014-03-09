describe "Overloading functions", ->
    overloadableFunc = null;

    beforeEach ->
        overloadableFunc = new Overloadable();

    it "Should not allow for passing incorrect arguments to 'overload' function", ->
        expect( ->
            overloadableFunc.overload()
        ).toThrow()

        expect( ->
            overloadableFunc.overload([], ->)
        ).toThrow()

        expect( ->
            overloadableFunc.overload([null], null)
        ).toThrow()
