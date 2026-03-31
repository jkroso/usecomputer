# Basic example — read-only operations that are safe to run on any desktop.
# Requires: zig build c-api (to build libusecomputer_c)

using UseComputer

println("── Mouse position ──")
pos = mouse_position()
println("  x=$(pos.x), y=$(pos.y)")

println("\n── Displays ──")
for d in display_list()
    println("  #$(d["index"]): $(d["name"]) $(d["width"])×$(d["height"]) (primary=$(d["isPrimary"]))")
end

println("\n── Windows (first 10) ──")
for w in first(window_list(), 10)
    println("  [$(w["ownerName"])] $(w["title"]) — $(w["width"])×$(w["height"]) at ($(w["x"]),$(w["y"]))")
end
