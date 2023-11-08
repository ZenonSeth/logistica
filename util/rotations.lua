local rots = {}
for i=0,23 do rots[i] = {} end
local function p(a,b,c) return vector.new(a,b,c) end

 rots[0].up=p( 0, 1, 0);  rots[0].forward=p( 0, 0,-1);  rots[0].left=p( 1, 0, 0)
 rots[1].up=p( 0, 1, 0);  rots[1].forward=p(-1, 0, 0);  rots[1].left=p( 0, 0,-1)
 rots[2].up=p( 0, 1, 0);  rots[2].forward=p( 0, 0, 1);  rots[2].left=p(-1, 0, 0)
 rots[3].up=p( 0, 1, 0);  rots[3].forward=p( 1, 0, 0);  rots[3].left=p( 0, 0, 1)

 rots[4].up=p( 0, 0, 1);  rots[4].forward=p( 0, 1, 0);  rots[4].left=p( 1, 0, 0)
 rots[5].up=p( 0, 0, 1);  rots[5].forward=p(-1, 0, 0);  rots[5].left=p( 0, 1, 0)
 rots[6].up=p( 0, 0, 1);  rots[6].forward=p( 0,-1, 0);  rots[6].left=p(-1, 0, 0)
 rots[7].up=p( 0, 0, 1);  rots[7].forward=p( 1, 0, 0);  rots[7].left=p( 0,-1, 0)

 rots[8].up=p( 0, 0,-1);  rots[8].forward=p( 0,-1, 0);  rots[8].left=p( 1, 0, 0)
 rots[9].up=p( 0, 0,-1);  rots[9].forward=p(-1, 0, 0);  rots[9].left=p( 0,-1, 0)
rots[10].up=p( 0, 0,-1); rots[10].forward=p( 0, 1, 0); rots[10].left=p(-1, 0, 0)
rots[11].up=p( 0, 0,-1); rots[11].forward=p( 1, 0, 0); rots[11].left=p( 0, 1, 0)

rots[12].up=p( 1, 0, 0); rots[12].forward=p( 0, 0,-1); rots[12].left=p( 0,-1, 0)
rots[13].up=p( 1, 0, 0); rots[13].forward=p( 0, 1, 0); rots[13].left=p( 0, 0,-1)
rots[14].up=p( 1, 0, 0); rots[14].forward=p( 0, 0, 1); rots[14].left=p( 0, 1, 0)
rots[15].up=p( 1, 0, 0); rots[15].forward=p( 0,-1, 0); rots[15].left=p( 0, 0, 1)

rots[16].up=p(-1, 0, 0); rots[16].forward=p( 0, 0,-1); rots[16].left=p( 0, 1, 0)
rots[17].up=p(-1, 0, 0); rots[17].forward=p( 0,-1, 0); rots[17].left=p( 0, 0,-1)
rots[18].up=p(-1, 0, 0); rots[18].forward=p( 0, 0, 1); rots[18].left=p( 0,-1, 0)
rots[19].up=p(-1, 0, 0); rots[19].forward=p( 0, 1, 0); rots[19].left=p( 0, 0, 1)

rots[20].up=p( 0,-1, 0); rots[20].forward=p( 0, 0,-1); rots[20].left=p(-1, 0, 0)
rots[21].up=p( 0,-1, 0); rots[21].forward=p( 1, 0, 0); rots[21].left=p( 0, 0,-1)
rots[22].up=p( 0,-1, 0); rots[22].forward=p( 0, 0, 1); rots[22].left=p( 1, 0, 0)
rots[23].up=p( 0,-1, 0); rots[23].forward=p(-1, 0, 0); rots[23].left=p( 0, 0, 1)

for i=0,23 do
  rots[i].down = vector.multiply(rots[i].up, -1)
  rots[i].backward = vector.multiply(rots[i].forward, -1)
  rots[i].right = vector.multiply(rots[i].left, -1)
end

local objRot = {
	[0]  = {pitch = 0, yaw = 0, roll = 0},
	[12] = {pitch = 0, yaw = 0, roll = 3},
	[16] = {pitch = 0, yaw = 0, roll = 1},
	[20] = {pitch = 0, yaw = 0, roll = 20},

	[1]  = {pitch = 0, yaw = 1, roll = 0},
	[5]  = {pitch = 0, yaw = 1, roll = 1},
	[9]  = {pitch = 0, yaw = 1, roll = 3},
	[23] = {pitch = 0, yaw = 1, roll = 2},

	[2]  = {pitch = 0, yaw = 2, roll = 0},
	[14] = {pitch = 0, yaw = 2, roll = 1},
	[18] = {pitch = 0, yaw = 2, roll = 3},
	[22] = {pitch = 0, yaw = 2, roll = 2},

	[3]  = {pitch = 0, yaw = 3, roll = 0},
	[7]  = {pitch = 0, yaw = 3, roll = 3},
	[11] = {pitch = 0, yaw = 3, roll = 1},
	[21] = {pitch = 0, yaw = 3, roll = 2},

	[4]  = {pitch = -4.7, yaw = 0, roll = 0},
	[10] = {pitch = -4.7, yaw = 2, roll = 0},
	[13] = {pitch = -4.7, yaw = 1, roll = 0},
	[19] = {pitch = -4.7, yaw = 3, roll = 0},

	[8]  = {pitch = -4.7, yaw = 0, roll = 0},
	[6]  = {pitch = -4.7, yaw = 2, roll = 0},
	[15] = {pitch = -4.7, yaw = 3, roll = 0},
	[17] = {pitch = -4.7, yaw = 1, roll = 0},
}

function logistica.get_rot_directions(param2)
  return rots[param2]
end

function logistica.get_front_face_object_info(param2)
  local rot = objRot[param2]
  local pos = rots[param2]
  if not rot or not pos then return nil end
  rot.x = pos.forward.x
  rot.y = pos.forward.y
  rot.z = pos.forward.z
  return rot
end