@use "github.com/jkroso/Rutherford.jl/test" testset @test @catch
@use "./UseComputer" Error ms BUTTONS check Direction
@use Dates Millisecond Second Minute

testset("UseComputer") do
  testset("BUTTONS") do
    @test BUTTONS[:left] == 0
    @test BUTTONS[:right] == 1
    @test BUTTONS[:middle] == 2
    @test @catch(BUTTONS[:invalid]) isa KeyError
  end

  testset("ms") do
    @test ms(nothing) == -1
    @test ms(Millisecond(20)) == 20
    @test ms(Millisecond(0)) == 0
    @test ms(Second(1)) == 1000
    @test ms(Minute(1)) == 60000
  end

  testset("Direction") do
    @test Direction.up isa Direction
    @test Direction.down isa Direction
    @test Direction.left isa Direction
    @test Direction.right isa Direction
    @test nameof(Direction.up) == :up
  end

  testset("Error") do
    err = Error("test error")
    @test err.msg == "test error"
    buf = IOBuffer()
    showerror(buf, err)
    @test String(take!(buf)) == "UseComputerError: test error"
  end
end
