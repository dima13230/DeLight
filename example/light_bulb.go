components {
  id: "lightsource"
  component: "/delight/lightsource.script"
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
    id: "offset"
    value: "100.0, 0.0, 0.0"
    type: PROPERTY_TYPE_VECTOR3
  }
  properties {
    id: "radius"
    value: "10.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/builtins/assets/meshes/quad.dae\"\n"
  "material: \"/delight/materials/light_affected_sprite.material\"\n"
  "textures: \"/builtins/graphics/particle_blob.png\"\n"
  "skeleton: \"\"\n"
  "animations: \"\"\n"
  "default_animation: \"\"\n"
  "name: \"{{NAME}}\"\n"
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
