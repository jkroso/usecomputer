module UseComputer

using JSON
using Dates

export click, mouse_move, hover, mouse_down, mouse_up, mouse_position,
       drag, type_text, press, scroll, screenshot, display_list, window_list,
       UseComputerError

# ── Error type ──

struct UseComputerError <: Exception
    msg::String
end

Base.showerror(io::IO, e::UseComputerError) = print(io, "UseComputerError: ", e.msg)

# ── Library path ──

const ext = Sys.isapple() ? "dylib" : Sys.iswindows() ? "dll" : "so"
const libpath = joinpath(@__DIR__, "..", "..", "..", "zig-out", "lib", "libusecomputer_c.$ext")

# ── Helpers ──

function last_error()
    ptr = ccall((:uc_last_error, libpath), Ptr{UInt8}, ())
    ptr == C_NULL ? "unknown error" : unsafe_string(ptr)
end

function check(rc::Cint)
    rc != 0 && throw(UseComputerError(last_error()))
    nothing
end

function button_int(button::Symbol)::Cint
    button === :left   && return Cint(0)
    button === :right  && return Cint(1)
    button === :middle && return Cint(2)
    throw(ArgumentError("button must be :left, :right, or :middle, got :$button"))
end

function delay_ms(delay)::Cint
    delay === nothing && return Cint(-1)
    return Cint(Dates.value(Dates.Millisecond(delay)))
end

# ── Mouse ──

function click(x::Real, y::Real; button::Symbol=:left, count::Integer=1)
    rc = ccall((:uc_click, libpath), Cint, (Cdouble, Cdouble, Cint, Cint),
               Cdouble(x), Cdouble(y), button_int(button), Cint(count))
    check(rc)
end

function mouse_move(x::Real, y::Real)
    rc = ccall((:uc_mouse_move, libpath), Cint, (Cdouble, Cdouble), Cdouble(x), Cdouble(y))
    check(rc)
end

function hover(x::Real, y::Real)
    rc = ccall((:uc_hover, libpath), Cint, (Cdouble, Cdouble), Cdouble(x), Cdouble(y))
    check(rc)
end

function mouse_down(; button::Symbol=:left)
    rc = ccall((:uc_mouse_down, libpath), Cint, (Cint,), button_int(button))
    check(rc)
end

function mouse_up(; button::Symbol=:left)
    rc = ccall((:uc_mouse_up, libpath), Cint, (Cint,), button_int(button))
    check(rc)
end

function mouse_position()
    x = Ref{Cdouble}(0.0)
    y = Ref{Cdouble}(0.0)
    rc = ccall((:uc_mouse_position, libpath), Cint, (Ptr{Cdouble}, Ptr{Cdouble}), x, y)
    check(rc)
    return (x=x[], y=y[])
end

function drag(from::Tuple{Real,Real}, to::Tuple{Real,Real};
              cp::Union{Tuple{Real,Real},Nothing}=nothing, button::Symbol=:left)
    has_cp = cp !== nothing ? Cint(1) : Cint(0)
    cp_x = cp !== nothing ? Cdouble(cp[1]) : Cdouble(0)
    cp_y = cp !== nothing ? Cdouble(cp[2]) : Cdouble(0)
    rc = ccall((:uc_drag, libpath), Cint,
               (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cint, Cint),
               Cdouble(from[1]), Cdouble(from[2]),
               Cdouble(to[1]), Cdouble(to[2]),
               cp_x, cp_y, has_cp, button_int(button))
    check(rc)
end

# ── Keyboard ──

function type_text(text::AbstractString; delay::Union{Period,Nothing}=nothing)
    rc = ccall((:uc_type_text, libpath), Cint, (Cstring, Cint), text, delay_ms(delay))
    check(rc)
end

function press(key::AbstractString; count::Integer=1, delay::Union{Period,Nothing}=nothing)
    rc = ccall((:uc_press, libpath), Cint, (Cstring, Cint, Cint), key, Cint(count), delay_ms(delay))
    check(rc)
end

# ── Scroll ──

const DIRECTION_STRINGS = Dict{Symbol,String}(
    :up => "up", :down => "down", :left => "left", :right => "right")

function scroll(direction::Symbol; amount::Integer=3, at::Union{Tuple{Real,Real},Nothing}=nothing)
    dir_str = get(DIRECTION_STRINGS, direction, nothing)
    dir_str === nothing && throw(ArgumentError("direction must be :up, :down, :left, or :right, got :$direction"))
    has_at = at !== nothing ? Cint(1) : Cint(0)
    at_x = at !== nothing ? Cdouble(at[1]) : Cdouble(0)
    at_y = at !== nothing ? Cdouble(at[2]) : Cdouble(0)
    rc = ccall((:uc_scroll, libpath), Cint, (Cstring, Cint, Cdouble, Cdouble, Cint),
               dir_str, Cint(amount), at_x, at_y, has_at)
    check(rc)
end

# ── Screenshot ──

function screenshot(; path::Union{AbstractString,Nothing}=nothing,
                      display::Union{Integer,Nothing}=nothing,
                      window::Union{Integer,Nothing}=nothing)
    c_path = path === nothing ? C_NULL : path
    c_display = display === nothing ? Cint(-1) : Cint(display)
    c_window = window === nothing ? Cint(-1) : Cint(window)
    ptr = ccall((:uc_screenshot, libpath), Ptr{UInt8}, (Cstring, Cint, Cint), c_path, c_display, c_window)
    ptr == C_NULL && throw(UseComputerError(last_error()))
    result = JSON.parse(unsafe_string(ptr))
    ccall((:uc_free, libpath), Cvoid, (Ptr{UInt8},), ptr)
    return result
end

# ── Queries ──

function display_list()
    ptr = ccall((:uc_display_list, libpath), Ptr{UInt8}, ())
    ptr == C_NULL && throw(UseComputerError(last_error()))
    result = JSON.parse(unsafe_string(ptr))
    ccall((:uc_free, libpath), Cvoid, (Ptr{UInt8},), ptr)
    return result
end

function window_list()
    ptr = ccall((:uc_window_list, libpath), Ptr{UInt8}, ())
    ptr == C_NULL && throw(UseComputerError(last_error()))
    result = JSON.parse(unsafe_string(ptr))
    ccall((:uc_free, libpath), Cvoid, (Ptr{UInt8},), ptr)
    return result
end

end # module
