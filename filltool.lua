
local playerFillData = {}

function vector_copy (from, to)
  to.x = from.x
  to.z = from.z
  to.y = from.y
end

local filltool = {
  description = "filltool",
  inventory_image = "wand-64.png",
  stack_max = 1,
  range = 10,
  on_use = function (itemstack, user, pointed_thing)
    if pointed_thing.type ~= "node" then return end

    local pname = user:get_player_name()
    local blockpos = pointed_thing.under

    local d = playerFillData[pname]

    if d == null then
      d = {
        last = false,
        pointa = {x=0, y=0, z=0},
        pointb = {x=0, y=0, z=0}
      }
    end

    if d.last then
      vector_copy(blockpos, d.pointa)
    else
      vector_copy(blockpos, d.pointb)
    end

    d.last = not d.last

    playerFillData[pname] = d

    minetest.chat_send_player(pname, "Using block " .. dump(blockpos) .. " as a fill coordinate")

  end,
  on_secondary_use = function (itemstack, user, pointed_thing)

  end
}

minetest.register_tool("repcomm:filltool", filltool)


minetest.register_chatcommand("nodelist", {
  privs = {
    interact = true
  },
  func = function(name, param)

    for k, v in pairs(minetest.registered_nodes) do
      
      if k == "" or string.match(k, param) then
        minetest.chat_send_player(name, k)
      else
        -- minetest.chat_send_player(name, k)
      end

    end
    
    return true, "Listed all nodes"
  end
})

function cube_area_get_dimensions (from, to)
  return {
    x=math.abs(from.x -  to.x),
    y=math.abs(from.y - to.y),
    z=math.abs(from.z -  to.z)
  }
end

function cube_area_get_min (from, to)
  return {
    x=math.min(from.x, to.x),
    y=math.min(from.y, to.y),
    z=math.min(from.z, to.z)
  }
end

function cube_area_get_center (from, to)
  local min = cube_area_get_min(from, to)
  local dim = cube_area_get_dimensions(from, to)

  return {
    x=min.x + (dim.x/2),
    y=min.y + (dim.y/2),
    z=min.z + (dim.z/2)
  }
end

function loop_cube_area (from, to, cb)
  local dim = cube_area_get_dimensions(from, to)
  local min = cube_area_get_min(from, to)

  local blockpos = {x=0, y=0, z=0}

  for ix = 0, dim.x, 1 do
    for iy = 0, dim.y, 1 do
      for iz = 0, dim.z, 1 do

        blockpos.x = min.x + ix
        blockpos.y = min.y + iy
        blockpos.z = min.z + iz

        cb(blockpos)
      end
    end
  end
end

function isValidNodeID (nodeid)
  return minetest.registered_nodes[nodeid] ~= nil
end

function isValidNodeIDList (nodeids)
  for i = 1, #nodeids do
    if not isValidNodeID(nodeids[i]) then return false end
  end
  return true
end

function string_split (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end

  local t={}
  
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

function getCommandParams (inputstr)
  local params = {}

  local parts = nil
  local key = nil
  local partcount = 0

  for i = 1, 1,-1 do 
    print(i) 
  end

  for index,str in ipairs(string_split(inputstr, " ")) do 
    parts = string_split(str, "=")

    partcount = #parts
    if partcount == 0 then
      --do nothing, maybe throw an error later?
    elseif partcount >= 1 then
      key = parts[1]
      params[key] = false

      if #parts > 1 then
        local values = string_split(parts[2], ",")

        if #values == 1 then 
          params[key] = values[1]
        elseif #values > 1 then
          params[key] = values
        end
      end
    end
  end

  return params
end

function has_value (tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

minetest.register_chatcommand("test", {
  privs = {
    interact = true
  },
  func = function(name, param)
    local params = getCommandParams(param)
    
    -- for index,str in ipairs(string_split(param, " ")) do 
    --   minetest.chat_send_player(name, str)
    -- end

    return true, dump(params)
  end
})

minetest.register_chatcommand("fill", {
  privs = {
    interact = true
  },
  func = function(name, param)
    
    local params = getCommandParams(param)

    local blocks = params["blocks"]

    if blocks == nil or blocks == false then
      return false, "blocks param was not specified, try adding blocks=blockid0,blockid1"
    end

    if type(blocks) ~= "table" then
      a = {}
      a[1] = blocks
      blocks = a
    end

    for index,blockid in ipairs(blocks) do 
      if not isValidNodeID(blockid) then
        return false, "block id '" .. blockid .. "' is not registered, use /nodelist " .. blockid
      end
    end

    --get the order argument
    local order = params["order"]
    if order == nil then order = "random" end

    --get the replace argument
    local replace = params["replace"]
    --whether to do replace logic
    local doreplace = replace ~= nil and replace ~= false
    --if replace blocks is only one block, make it a table
    if type(replace) ~= "table" then
      a = {}
      a[1] = replace
      replace = a
    end

    local replaceinfo = nil

    local sphere = tonumber(params["sphere"])
    local dosphere = sphere ~= nil and sphere ~= 0

    local d = playerFillData[name]

    local centerpos = cube_area_get_center(d.pointa, d.pointb)

    local counter = 0

    local blocktype = {
      name = "air"
    }

    loop_cube_area(d.pointa, d.pointb, function (blockpos)
      counter = counter + 1

      if order == "iterate" then
        blocktype.name = blocks[ counter % #blocks + 1 ]
      else --default to random
        --get a random block from the array using its length
        blocktype.name = blocks[ math.random( #blocks ) ]
      end

      --whether or not we can set the node
      local can_set = true
      --check that replace rules are met
      if doreplace then
        replaceinfo = minetest.get_node(blockpos)

        if not has_value(replace, replaceinfo.name) then
          can_set = false
        end
      end

      if dosphere then
        if vector.distance(blockpos, centerpos) > sphere then
          can_set = false
        end
      end

      if can_set then
        minetest.set_node(blockpos, blocktype)
      end
    end)

    return true, "filled " .. counter .. " blocks"
  end
})
