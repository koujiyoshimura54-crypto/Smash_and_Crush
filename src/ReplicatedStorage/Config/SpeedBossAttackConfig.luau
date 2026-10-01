-- Item-specific Boss -> Player hitbox settings; independent of WalkSpeed.
local C = {
 NONE = {
  ReachScale = 0.25,
  MinReach = 8,
  MaxReach = 14,
  AttackAngle = 104,
  AttackHeight = 3.5,
  VerticalPadding = 1,
 },
 SPEED_BOOST = {
  ReachScale = 0.25,
  MinReach = 8,
  MaxReach = 14,
  AttackAngle = 104,
  AttackHeight = 3.5,
  VerticalPadding = 1,
 },
 SPEED_PREMIUM = {
  ReachScale = 0.25,
  MinReach = 8,
  MaxReach = 14,
  AttackAngle = 104,
  AttackHeight = 3.5,
  VerticalPadding = 1,
 },
}
for _, entry in pairs(C) do table.freeze(entry) end
return table.freeze(C)
