
function lerp (start, stop, time)
  return start * (1 - time) + stop * time
end

function randomFloat (min, max)
  if min == nil then min = 0 end
  if max == nil then max = 1 end
  
  return lerp (min, max, math.random())
end

WeaponBuilder = {
  modname = "", --name of your mod
  weaponname = "", --name of the weapon as used with /giveme modname:weaponname
  description = "", --shows in inventory UI

  inventory_image = "", --self explanitory, also used as visual 3d when no model set
  
  bullet_entity = nil,
  
  bullet_speed = 30, --linear velocity
  bullet_use_gravity = true, --whether gravity applies to the bullet
  
  salvo_count = 1, --how many bullets to fire per trigger
  salvo_delay = 0, --delay in seconds of how long to delay each bullet in a salvo count > 1
  
  spread_max_angle = 0, --angle in radians of maximum spread
  
  bullet_heat = 0, --heat per shot (contributes to spread function)
  inactive_cool_rate = 0, --how much to cool down heat in a second's time
  
  threshold_heat_spread_min = 1, --how much heat allowed before spread
  threshold_heat_spread_max = 2, --how much heat allowed before max spread
  
  threshold_heat_overheat = 3, --how much heat allowed before overheating (stop firing)
  overheat_timeout = 1, --time in seconds of how long weapon inoperable during overheat
  --spread will happen between min and max values for weapon's heat

  --sounds
  sounds = {
    trigger = nil,
    bullet_init = nil,
    bullet_travel_loop = nil,
    bullet_hit = nil,
    bullet_timeout = nil,
    overheat = nil
  },

  heat = 0.0,
  update_last = 0,
  trigger_delay = 0.1,
  is_overheated = false,
  is_overheated_last = false
}

function WeaponBuilder:new (o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

---Set the weapon info
---@param modname string name of your mod
---@param weaponname string name of the weapon as used with /giveme modname:weaponname
---@param description string shows up in ingame UI
function WeaponBuilder:setInfo (modname, itemid, description)
  self.modname = modname
  self.weaponname = itemid
  self.description = description
  return self
end

---Sets the weapon to use an inventory_image
---@param imagefname string file from your textures/ folder
function WeaponBuilder:useImage (imagefname)
  self.inventory_image = imagefname
  return self
end

function WeaponBuilder:useModel ()
  --error("useModel hasn't been implemented yet")
end

---Set bullet configurations
---@param entity any
---@param speed number velocity magnitude/length
---@param usegravity boolean whether world gravity affects the bullet
function WeaponBuilder:setBulletInfo (entity, speed, usegravity)
  self.bullet_entity = entity
  self.bullet_speed = speed
  self.bullet_use_gravity = usegravity
  return self
end

function WeaponBuilder:setTriggerDelay (delay)
  self.trigger_delay = delay
  return self
end

---Set heat configurations
---@param heat number heat per shot
---@param thresholdspread number when heat reaches this, spreading will occur
---@param thresholdspreadmax number when heat reaches this, spreading will peak
---@param thresholdoverheat number when heat reaches this, weapon ceases to fire
function WeaponBuilder:setHeatInfo (heat, thresholdspread, thresholdspreadmax, thresholdoverheat, coolrate)
  self.bullet_heat = heat
  self.threshold_heat_spread_min = thresholdspread
  self.threshold_heat_spread_max = thresholdspreadmax
  self.threshold_heat_overheat = thresholdoverheat
  self.inactive_cool_rate = coolrate
  return self
end

function WeaponBuilder:setMaxSpread (maxspread)
  self.spread_max_angle = maxspread
  return self
end

---Set the salvo data
---@param count number how many bullets per trigger (salvo)
---@param delay number how long to wait for each bullet
function WeaponBuilder:setSalvo (count, delay)
  self.salvo_count = count
  self.salvo_delay = delay
  return self
end

---Set the sounds the play with this weapon, all are optional
---@param trigger any happens once per weapon trigger
---@param bullet_init any happens per bullet creation (typical fire sound)
---@param bullet_travel_loop any a looped sound that plays at each bullet until destruction
---@param bullet_hit any played on bullet collision destruction
---@param bullet_timeout any played on bullet destruction due to being alive to long
function WeaponBuilder:setSounds (trigger, bullet_init, bullet_travel_loop, bullet_hit, bullet_timeout, overheat)
  self.sounds.trigger = trigger
  self.sounds.bullet_init = bullet_init
  self.sounds.bullet_travel_loop = bullet_travel_loop
  self.sounds.bullet_hit = bullet_hit
  self.sounds.bullet_timeout = bullet_timeout
  self.sounds.overheat = overheat
  return self
end

---Clears the data previously set
function WeaponBuilder:clear ()
  error("not implemented yet")
end

---Returns a minetest tool class ready to be registered
---Alternatively, you can call :register() to do all of this for you
function WeaponBuilder:build ()
  return {
    description = self.description,
    inventory_image = self.inventory_image,
    stack_max = 1,
    range = 0.1,
    -- sounds = self.sounds,
    -- heat = 0.0,
    on_use = function (itemstack, user, pointed_thing)

      local pos = user:get_pos()
      local dir = user:get_look_dir()

      local yaw = user:get_look_yaw()
      local pitch = user:get_look_pitch()

      pos.y = pos.y + 1.5

      --play trigger sound if available
      if (self.sounds.trigger) then
        minetest.sound_play(self.sounds.trigger, {
          pos = pos,
          gain = 1.0,
          max_hear_distance = 32
        }, true)
      end

      --get time enlapsed, works without a constant timer
      local delta = minetest.get_gametime() - self.update_last
      self.update_last = minetest.get_gametime()

      --decrease heat by cooling amount
      self.heat = self.heat -(self.inactive_cool_rate * delta)
      --stop heat from going negative
      if self.heat < 0 then self.heat = 0 end

      self.is_overheated_last = self.is_overheated

      --set overheated if necessary
      if self.heat > self.threshold_heat_overheat then self.is_overheated = true end

      --remove overheated if necessary
      if self.heat < 0.1 then self.is_overheated = false end

      --if overheated, skip firing bullets and play sound if available
      if self.is_overheated then

        --plays the overheat sound only once per overheat event
        if self.is_overheated ~= self.is_overheated_last then
          --play overheat sound if available
          if (self.sounds.overheat) then
            minetest.sound_play(self.sounds.overheat, {
              pos = pos,
              gain = 1.0,
              max_hear_distance = 32
            }, true)
          end
        end

        return
      end

      --get the amount to spread by
      local halfspread = lerp(0, (self.spread_max_angle/2), self.heat / self.threshold_heat_spread_max)

      --fire off several shots
      for i = 1, self.salvo_count, 1 do
        local salvodir = {x=0, y=0, z=0}

        --apply random spread
        salvodir.x = dir.x + randomFloat(-halfspread, halfspread)
        salvodir.y = dir.y + randomFloat(-halfspread, halfspread)
        salvodir.z = dir.z + randomFloat(-halfspread, halfspread)

        --add to heat
        self.heat = self.heat + self.bullet_heat

        --add in delay by multiplying iteration by salvo delay amount
        minetest.after(i * self.salvo_delay, function ()
          
          if (self.sounds.bullet_init) then
            minetest.sound_play(self.sounds.bullet_init, {
              pos = pos,
              gain = 1.0,
              max_hear_distance = 32
            }, true)
          end

          local obj = minetest.add_entity(pos, self.bullet_entity)

          obj:set_velocity({
            x=salvodir.x * self.bullet_speed,
            y=salvodir.y * self.bullet_speed,
            z=salvodir.z * self.bullet_speed
          })
          obj:set_rotation({x=0, y=yaw, z=-pitch})
        end)
      end

    end,
    on_secondary_use = function (itemstack, user, pointed_thing)

    end
  }
end

function WeaponBuilder:register ()
  local id = self.modname .. ":" .. self.weaponname
  minetest.register_tool(id, self:build())
end
