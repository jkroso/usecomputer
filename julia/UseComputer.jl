@use "github.com/JuliaIO/JSON.jl" parse
@use "github.com/jkroso/Prospects.jl/Enum" @Enum
@use Dates Millisecond Second

struct Error <: Exception
  msg::String
end
Base.showerror(io::IO, e::Error) = print(io, "UseComputerError: ", e.msg)

const ext = Sys.isapple() ? "dylib" : Sys.iswindows() ? "dll" : "so"
const lib = joinpath(@__DIR__, "..", "zig-out", "lib", "libusecomputer_c.$ext")
const BUTTONS = Dict(:left => Cint(0), :right => Cint(1), :middle => Cint(2))

function lasterror()
  ptr = @ccall lib.uc_last_error()::Ptr{UInt8}
  ptr == C_NULL ? "unknown error" : unsafe_string(ptr)
end

check(rc::Cint) = rc == 0 || throw(Error(lasterror()))
ms(::Nothing) = Cint(-1)
ms(d::Dates.Period) = Cint(Dates.value(Millisecond(d)))

# Mouse

function click(x::Real, y::Real; button::Symbol=:left, count::Integer=1)
  check(@ccall lib.uc_click(Cdouble(x)::Cdouble, Cdouble(y)::Cdouble,
                             BUTTONS[button]::Cint, Cint(count)::Cint)::Cint)
end

move(x::Real, y::Real) =
  check(@ccall lib.uc_mouse_move(Cdouble(x)::Cdouble, Cdouble(y)::Cdouble)::Cint)

hover(x::Real, y::Real) =
  check(@ccall lib.uc_hover(Cdouble(x)::Cdouble, Cdouble(y)::Cdouble)::Cint)

hold(; button::Symbol=:left) =
  check(@ccall lib.uc_mouse_down(BUTTONS[button]::Cint)::Cint)

release(; button::Symbol=:left) =
  check(@ccall lib.uc_mouse_up(BUTTONS[button]::Cint)::Cint)

function position()
  x = Ref{Cdouble}(0.0)
  y = Ref{Cdouble}(0.0)
  check(@ccall lib.uc_mouse_position(x::Ptr{Cdouble}, y::Ptr{Cdouble})::Cint)
  (x=x[], y=y[])
end

function drag(from::Tuple{Real,Real}, to::Tuple{Real,Real};
              cp::Union{Tuple{Real,Real},Nothing}=nothing, button::Symbol=:left)
  check(@ccall lib.uc_drag(
    Cdouble(from[1])::Cdouble, Cdouble(from[2])::Cdouble,
    Cdouble(to[1])::Cdouble, Cdouble(to[2])::Cdouble,
    Cdouble(cp !== nothing ? cp[1] : 0)::Cdouble,
    Cdouble(cp !== nothing ? cp[2] : 0)::Cdouble,
    Cint(cp !== nothing)::Cint, BUTTONS[button]::Cint)::Cint)
end

# Keyboard

type(text::AbstractString; delay::Union{Dates.Period,Nothing}=nothing) =
  check(@ccall lib.uc_type_text(text::Cstring, ms(delay)::Cint)::Cint)

press(key::AbstractString; count::Integer=1, delay::Union{Dates.Period,Nothing}=nothing) =
  check(@ccall lib.uc_press(key::Cstring, Cint(count)::Cint, ms(delay)::Cint)::Cint)

# Scroll

@Enum Direction up down left right

function scroll(direction::Direction; amount::Integer=3, at::Union{Tuple{Real,Real},Nothing}=nothing)
  check(@ccall lib.uc_scroll(
    String(nameof(direction))::Cstring, Cint(amount)::Cint,
    Cdouble(at !== nothing ? at[1] : 0)::Cdouble,
    Cdouble(at !== nothing ? at[2] : 0)::Cdouble,
    Cint(at !== nothing)::Cint)::Cint)
end

# Screenshot & queries

function readjson(ptr::Ptr{UInt8})
  ptr == C_NULL && throw(Error(lasterror()))
  result = parse(unsafe_string(ptr))
  @ccall lib.uc_free(ptr::Ptr{UInt8})::Cvoid
  result
end

function screenshot(; path::Union{AbstractString,Nothing}=nothing,
                      display::Union{Integer,Nothing}=nothing,
                      window::Union{Integer,Nothing}=nothing)
  readjson(@ccall lib.uc_screenshot(
    (path === nothing ? C_NULL : path)::Cstring,
    Cint(something(display, -1))::Cint,
    Cint(something(window, -1))::Cint)::Ptr{UInt8})
end

displays() = readjson(@ccall lib.uc_display_list()::Ptr{UInt8})
windows() = readjson(@ccall lib.uc_window_list()::Ptr{UInt8})
