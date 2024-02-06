components {
  id: "light_sprite"
  component: "/delight/sprite/light_sprite.script"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
  properties {
    id: "normal_map_enabled"
    value: "true"
    type: PROPERTY_TYPE_BOOLEAN
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"walk\"\n"
  "material: \"/delight/materials/light_affected_sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/images/bopz_diff.atlas\"\n"
  "}\n"
  "textures {\n"
  "  sampler: \"normal_map\"\n"
  "  texture: \"/assets/images/bopz_norm.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
