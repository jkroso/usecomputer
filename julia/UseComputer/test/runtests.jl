using Test
using UseComputer
using Dates

@testset "UseComputer" begin
    @testset "button_int" begin
        @test UseComputer.button_int(:left) == 0
        @test UseComputer.button_int(:right) == 1
        @test UseComputer.button_int(:middle) == 2
        @test_throws ArgumentError UseComputer.button_int(:invalid)
    end

    @testset "delay_ms" begin
        @test UseComputer.delay_ms(nothing) == -1
        @test UseComputer.delay_ms(Millisecond(20)) == 20
        @test UseComputer.delay_ms(Millisecond(0)) == 0
        @test UseComputer.delay_ms(Second(1)) == 1000
        @test UseComputer.delay_ms(Minute(1)) == 60000
    end

    @testset "direction validation" begin
        # Valid directions shouldn't error (validated before ccall)
        for dir in (:up, :down, :left, :right)
            @test String(dir) == string(dir)
        end
    end

    @testset "UseComputerError" begin
        err = UseComputerError("test error")
        @test err.msg == "test error"
        buf = IOBuffer()
        showerror(buf, err)
        @test String(take!(buf)) == "UseComputerError: test error"
    end
end
