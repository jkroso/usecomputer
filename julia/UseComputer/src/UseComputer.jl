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
    ptr = @ccall libpath.uc_last_error()::Ptr{UInt8}
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
    rc = @ccall libpath.uc_click(Cdouble(x)::Cdouble, Cdouble(y)::Cdouble,
                                  button_int(button)::Cint, Cint(count)::Cint)::Cint
    check(rc)
end

function mouse_move(x::Real, y::Real)
    rc = @ccall libpath.uc_mouse_move(Cdouble(x)::Cdouble, Cdouble(y)::Cdouble)::Cint
    check(rc)
end

function hover(x::Real, y::Real)
    rc = @ccall libpath.uc_hover(Cdouble(x)::Cdouble, Cdouble(y)::Cdouble)::Cint
    check(rc)
end

function mouse_down(; button::Symbol=:left)
    rc = @ccall libpath.uc_mouse_down(button_int(button)::Cint)::Cint
    check(rc)
end

function mouse_up(; button::Symbol=:left)
    rc = @ccall libpath.uc_mouse_up(button_int(button)::Cint)::Cint
    check(rc)
end

function mouse_position()
    x = Ref{Cdouble}(0.0)
    y = Ref{Cdouble}(0.0)
    rc = @ccall libpath.uc_mouse_position(x::Ptr{Cdouble}, y::Ptr{Cdouble})::Cint
    check(rc)
    return (x=x[], y=y[])
end

function drag(from::Tuple{Real,Real}, to::Tuple{Real,Real};
              cp::Union{Tuple{Real,Real},Nothing}=nothing, button::Symbol=:left)
    has_cp = cp !== nothing ? Cint(1) : Cint(0)
    cp_x = cp !== nothing ? Cdouble(cp[1]) : Cdouble(0)
    cp_y = cp !== nothing ? Cdouble(cp[2]) : Cdouble(0)
    rc = @ccall libpath.uc_drag(Cdouble(from[1])::Cdouble, Cdouble(from[2])::Cdouble,
                                 Cdouble(to[1])::Cdouble, Cdouble(to[2])::Cdouble,
                                 cp_x::Cdouble, cp_y::Cdouble,
                                 has_cp::Cint, button_int(button)::Cint)::Cint
    check(rc)
end

# ── Keyboard ──

function type_text(text::AbstractString; delay::Union{Period,Nothing}=nothing)
    rc = @ccall libpath.uc_type_text(text::Cstring, delay_ms(delay)::Cint)::Cint
    check(rc)
end

function press(key::AbstractString; count::Integer=1, delay::Union{Period,Nothing}=nothing)
    rc = @ccall libpath.uc_press(key::Cstring, Cint(count)::Cint, delay_ms(delay)::Cint)::Cint
    check(rc)
end

# ── Scroll ──

function scroll(direction::Symbol; amount::Integer=3, at::Union{Tuple{Real,Real},Nothing}=nothing)
    direction in (:up, :down, :left, :right) || throw(ArgumentError("direction must be :up, :down, :left, or :right, got :$direction"))
    has_at = at !== nothing ? Cint(1) : Cint(0)
    at_x = at !== nothing ? Cdouble(at[1]) : Cdouble(0)
    at_y = at !== nothing ? Cdouble(at[2]) : Cdouble(0)
    rc = @ccall libpath.uc_scroll(String(direction)::Cstring, Cint(amount)::Cint,
                                   at_x::Cdouble, at_y::Cdouble, has_at::Cint)::Cint
    check(rc)
end

# ── Screenshot ──

function screenshot(; path::Union{AbstractString,Nothing}=nothing,
                      display::Union{Integer,Nothing}=nothing,
                      window::Union{Integer,Nothing}=nothing)
    c_path = path === nothing ? C_NULL : path
    c_display = display === nothing ? Cint(-1) : Cint(display)
    c_window = window === nothing ? Cint(-1) : Cint(window)
    ptr = @ccall libpath.uc_screenshot(c_path::Cstring, c_display::Cint, c_window::Cint)::Ptr{UInt8}
    ptr == C_NULL && throw(UseComputerError(last_error()))
    result = JSON.parse(unsafe_string(ptr))
    @ccall libpath.uc_free(ptr::Ptr{UInt8})::Cvoid
    return result
end

# ── Queries ──

function display_list()
    ptr = @ccall libpath.uc_display_list()::Ptr{UInt8}
    ptr == C_NULL && throw(UseComputerError(last_error()))
    result = JSON.parse(unsafe_string(ptr))
    @ccall libpath.uc_free(ptr::Ptr{UInt8})::Cvoid
    return result
end

function window_list()
    ptr = @ccall libpath.uc_window_list()::Ptr{UInt8}
    ptr == C_NULL && throw(UseComputerError(last_error()))
    result = JSON.parse(unsafe_string(ptr))
    @ccall libpath.uc_free(ptr::Ptr{UInt8})::Cvoid
    return result
end

end # module
