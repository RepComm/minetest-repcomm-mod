
print("This file will be run at load time!")

dofile(minetest.get_modpath("repcomm") .. "/nodes.lua");

minetest.register_tool("repcomm:wand", {
  description = "RepComm's wand",
  inventory_image = "wand-64.png",
  on_use = function (itemstack, user, pointed_thing)
    local pname = user:get_player_name()
    
    minetest.chat_send_player(pname, pname .. " uses their wand")
    return nil
  end
})

--Import the weapon builder api
dofile (minetest.get_modpath("repcomm") .. "/weapon.lua");

--anonymous function, so we don't pollute global scope
(function ()

  local laser_entity = {
    physical = false,
    timer = 0,
    visual = "cube",
    visual_size = {x=2.5, y=0.04, z=0.04},
    textures = {
      "laser-blue-16.png",
      "laser-blue-16.png",
      "laser-blue-16.png",
      "laser-blue-16.png",
      "laser-blue-16.png",
      "laser-blue-16.png"
    },
    lastpos= {},
    collisionbox = {0, 0, 0, 0, 0, 0},
  }

  laser_entity.on_step = function(self, dtime)
    self.timer = self.timer + dtime
    local pos = self.object:getpos()
    local node = minetest.get_node(pos)

    if self.timer > 0.10 then
      local objs = minetest.get_objects_inside_radius(pos, 1)
      for k, obj in pairs(objs) do
        if obj:get_luaentity() ~= nil then
          if obj:get_luaentity().name ~= "repcomm:laser_entity" and obj:get_luaentity().name ~= "__builtin:item" then
            local damage = 5
            obj:punch(self.object, 1.0, {
              full_punch_interval = 1.0,
              damage_groups= {fleshy = damage},
            }, nil)
            
            self.object:remove()
          end
        else
          local damage = 5
          obj:punch(self.object, 1.0, {
            full_punch_interval = 1.0,
            damage_groups= {fleshy = damage},
          }, nil)
          
          minetest.sound_play({
            name = "laserhit1",
            gain = 1.0
          },{
            pos = self.lastpos,
            gain = 1.0,
            max_hear_distance = 32
          }, true)
          self.object:remove()
        end
      end
    end

    if self.lastpos.x ~= nil then
      if minetest.registered_nodes[node.name].walkable then
        minetest.sound_play({
          name = "laserhit1",
          gain = 1.0
        },{
          pos = self.lastpos,
          gain = 1.0,
          max_hear_distance = 4
        }, true)

        self.object:remove()
      end
    end
    self.lastpos= {x = pos.x, y = pos.y, z = pos.z}
  end

  minetest.register_entity("repcomm:laser_entity", laser_entity)


  local weapbuilder = WeaponBuilder:new({})

  weapbuilder
  :setInfo("repcomm","dh17", "DH17 Blaster")
  :useImage("dh17.png")
  :setSounds(nil, {name = "pew01"}, nil, nil, nil, {name = "weapon_overheat"})
  :setBulletInfo("repcomm:laser_entity", 90, false)
  :setSalvo(3, 0.1)
  :setMaxSpread(3.1/16)
  :setTriggerDelay(0.2)
  :setHeatInfo(0.1, 1, 1.2, 2, 0.4)
  :register()

end)()

-- dofile(minetest.get_modpath("repcomm") .. "/pistol.lua");

minetest.register_on_joinplayer(function(player)
  local pname = player.get_player_name(player)
  minetest.chat_send_player(pname, "hi " .. pname)

  minetest.after(0, function ()
    player:set_sky({
      -- baseColor = 0xFFFFFF00,
      type = "skybox",
      textures = { --order: Y+ (top), Y- (bottom), X- (west), X+ (east), Z+ (north), Z- (south).
        "bespin-sky-top.png",
        "bespin-sky-bottom.png",
        "bespin-sky-h0.png",
        "bespin-sky-h2.png",
        "bespin-sky-h1.png",
        "bespin-sky-h3.png"
      }
    })

    player:set_physics_override({
      speed = 1.5,
      gravity = 1.1,
      jump = 1.1
    })

    --add the gun reticle
    local p_reticle = player:hud_add({
      hud_elem_type = "image",
      position      = {x = 0.5, y = 0.5},
      offset        = {x = 0,   y = 0},
      -- text          = "Hello world!",
      text = "reticule_rifle.png",
      alignment     = {x = 0, y = 0},  -- center aligned
      scale         = {x = 1, y = 1}, -- covered later
    })

    --add the minimap
    -- local p_minimap = player:hud_add({
    --   hud_elem_type = "minimap",
    --   position      = {x = 0.5, y = 0.5},
    --   offset        = {x = 0,   y = 0},
    --   -- text          = "Hello world!",
    --   -- text = "reticule_rifle.png",
    --   alignment     = {x = -0.5, y = 0},  -- center aligned
    --   scale         = {x = 1, y = 1}, -- covered later
    -- })

    player:hud_set_flags({
      crosshair = false,
      minimap = true,
      healthbar = false,
      breathbar = false,
      hotbar = false
    })

  end)
end)

minetest.register_chatcommand("repcomm", {
  privs = {
    interact = true,
  },
  func = function(name, param)
    return true, "You said " .. param .. "!"
  end,
})

dofile(minetest.get_modpath("repcomm") .. "/filltool.lua");
