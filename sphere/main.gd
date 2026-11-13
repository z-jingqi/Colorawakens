extends Node3D
var orb: MeshInstance3D
var mat: ShaderMaterial
var elapsed := 0.0
var capture := false

func _ready() -> void:
 capture = "--capture-sphere" in OS.get_cmdline_user_args()
 var camera := Camera3D.new()
 camera.position=Vector3(0,0,5)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=4.9
 add_child(camera)
 var bg := MeshInstance3D.new()
 var plane := QuadMesh.new()
 plane.size=Vector2(6,8)
 bg.mesh=plane
 bg.position.z=-2.0
 var bm:=ShaderMaterial.new()
 bm.shader=load("res://sphere/backdrop.gdshader")
 bg.material_override=bm
 add_child(bg)
 orb=MeshInstance3D.new()
 var sphere:=SphereMesh.new()
 sphere.radius=1.08
 sphere.height=2.16
 sphere.radial_segments=128
 sphere.rings=64
 orb.mesh=sphere
 mat=ShaderMaterial.new()
 mat.shader=load("res://sphere/orb.gdshader")
 orb.material_override=mat
 add_child(orb)
 var ui:=CanvasLayer.new()
 add_child(ui)
 var title:=Label.new()
 title.text="MEMORY / 02"
 title.position=Vector2(0,105)
 title.size=Vector2(720,40)
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_size_override("font_size",19)
 title.modulate=Color(.66,.77,.9)
 ui.add_child(title)
 var footer:=Label.new()
 footer.text="LIGHT HELD IN GLASS"
 footer.position=Vector2(0,800)
 footer.size=Vector2(720,40)
 footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 footer.add_theme_font_size_override("font_size",18)
 footer.modulate=Color(.55,.67,.83)
 ui.add_child(footer)
 if "--test-sphere" in OS.get_cmdline_user_args():
  assert(orb.mesh is SphereMesh)
  assert(mat.shader != null)
  assert(get_tree().current_scene == self)
  print("SPHERE STUDY: 3 checks passed")
  get_tree().quit()

func _process(delta:float)->void:
 elapsed+=delta
 mat.set_shader_parameter("phase",elapsed)
 orb.position.y=sin(elapsed*.75)*.07
 orb.rotation.y=sin(elapsed*.3)*.2
 if capture and elapsed>=8.0:
  get_tree().quit()
