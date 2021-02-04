
local sounds = {
  stone = {
    footstep = {
      name = "walk_stone"
    }
  }
}

minetest.register_node("repcomm:omnicron", {
  description = "An omnicron crystal",
  tiles = {"omnicron-16.png"},
  -- paramtype = "light",
  light_source = 14,
  groups = {cracky = 3},
  sounds = sounds.stone
})

minetest.register_node("repcomm:bespinfloor", {
  description = "Bespin floor",
  tiles = {"bespin-floor-64.png"},
  paramtype2 = "facedir",
  groups = {cracky = 3},
  sounds = sounds.stone
})

minetest.register_node("repcomm:bespinfloor02", {
  description = "Bespin floor 02",
  tiles = {"bespin-floor-02-64.png"},
  paramtype2 = "facedir",
  groups = {cracky = 3},
  sounds = sounds.stone
})

minetest.register_node("repcomm:bespinshaft", {
  description = "Bespin shaft 02",
  tiles = {"bespin-shaft.png"},
  -- paramtype2 = "facedir",
  groups = {cracky = 3},
  light_source = 12,
  sounds = sounds.stone
})

minetest.register_node("repcomm:bespinedge", {
  description = "Bespin edge",
  paramtype2 = "facedir",
  tiles = {"bespin-edge-64.png"},
  groups = {cracky = 3},
  sounds = sounds.stone
})

minetest.register_node("repcomm:bespininterior01", {
  description = "Bespin interior block 01",
  paramtype2 = "facedir",
  light_source = 12,
  tiles = {
    "bespin-interior-floor-01-64.png",
    "bespin-interior-ceiling-01-64.png",
    "bespin-interior-01-64.png"
  },
  groups = {cracky = 3},
  sounds = sounds.stone
})

minetest.register_node("repcomm:bespininterior02", {
  description = "Bespin interior block 02",
  paramtype2 = "facedir",
  -- light_source = 12,
  tiles = {
    "bespin-interior-floor-02-64.png",
    "bespin-interior-floor-02-64.png",
    "bespin-interior-02-64.png"
  },
  groups = {cracky = 3},
  sounds = sounds.stone
})

minetest.register_node("repcomm:bespinexterior01", {
  description = "Bespin exterior face 01",
  paramtype2 = "facedir",
  -- light_source = 12,
  tiles = {
    "bespin-interior-floor-02-64.png",
    "bespin-interior-floor-02-64.png",
    "bespin-exterior-01-64.png",
    "bespin-exterior-02-64.png",
    "bespin-exterior-03-64.png",
    "bespin-exterior-04-64.png",
  },
  groups = {cracky = 3},
  sounds = sounds.stone
})

minetest.register_node("repcomm:gonk", {
  description = "Gonk droid",
  paramtype2 = "facedir",
  -- light_source = 12,
  paramtype = "light",
	drawtype = "nodebox",
	node_box = {
    type = "fixed",
    fixed = {
      -- main body
      {-0.2, -0.3, -0.3, 0.2, 0.5, 0.3},
      --rim
      {-0.25, 0.1, -0.35, 0.25, 0.15, 0.35},
      --left foot
      {-0.15, -0.5, -0.1, -0.01, -0.3, 0.1},
      --right foot
      {0.15, -0.5, -0.1, 0.01, -0.3, 0.1},

      -- {-0.5, -0.5, -0.5, 0.5, 0.5, -0.4375},
      -- {-0.5, -0.5, 0.4375, 0.5, 0.5, 0.5},
      -- {0.4375, -0.5, -0.5, 0.5, 0.5, 0.5},
    },
  },
  tiles = {
    "gonk.png"
  },
  groups = {cracky = 3},
  sounds = sounds.stone
})

minetest.register_abm({
  nodenames = {"repcomm:gonk"},
  interval = 8.2, -- Run every 10 seconds
  chance = 1, -- Select every 1 in 50 nodes
  action = function(pos, node, active_object_count,active_object_count_wider)
    minetest.sound_play({
      name = "gonk",
      gain = 1.0
    },{
      pos = {x = pos.x, y = pos.y, z = pos.z},
      gain = 0.2,
      max_hear_distance = 8
    }, true)
  -- minetest.set_node(pos, {name = "aliens:grass"})
  end
})
