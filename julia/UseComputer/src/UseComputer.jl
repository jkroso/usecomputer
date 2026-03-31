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

end # module
