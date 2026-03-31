# Read-only operations that are safe to run on any desktop.
# Requires: zig build c-api

@use "../UseComputer" position displays windows

println("── Mouse position ──")
pos = position()
println("  x=$(pos.x), y=$(pos.y)")

println("\n── Displays ──")
for d in displays()
  println("  #$(d["index"]): $(d["name"]) $(d["width"])×$(d["height"]) (primary=$(d["isPrimary"]))")
end

println("\n── Windows (first 10) ──")
for w in first(windows(), 10)
  println("  [$(w["ownerName"])] $(w["title"]) — $(w["width"])×$(w["height"]) at ($(w["x"]),$(w["y"]))")
end
