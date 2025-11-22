-- @noindex
-- ReArkitekt/core/math.lua
-- Math utility functions

local M = {}

function M.lerp(a, b, t)
  return a + (b - a) * math.min(1.0, t)
end

function M.clamp(value, min, max)
  return math.max(min, math.min(max, value))
end

function M.remap(value, in_min, in_max, out_min, out_max)
  return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min)
end

function M.snap(value, step)
  return math.floor(value / step + 0.5) * step
end

function M.approximately(a, b, epsilon)
  epsilon = epsilon or 0.0001
  return math.abs(a - b) < epsilon
end

return M