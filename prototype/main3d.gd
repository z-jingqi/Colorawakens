extends Node3D
const COLORS=[Color("f55278"),Color("ffcb4d"),Color("32aaff")]
var block: MeshInstance3D
var mat: ShaderMaterial
var marks:=PackedVector4Array()
var pigments:=PackedColorArray()
var shots: Array[Dictionary]=[]
var drops: Array[Dictionary]=[]
var t:=0.
var count:=0
var next_shot:=0
var auto_mode:=true
var selected:=0
var dragging:=false
var camera: Camera3D
var label: Label
var schedule=[.6,2.6,4.6,6.6,8.6,10.6]
func rounded_mesh() -> ArrayMesh:
 var st:=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var axes=[Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN,Vector3.BACK,Vector3.FORWARD]
 for normal in axes:
  var u:=Vector3.UP.cross(normal).normalized()
  if absf(normal.y)>.9: u=Vector3.RIGHT
  var v:Vector3=normal.cross(u)
  for y in range(24):
   for x in range(24):
    for corner in [Vector2(0,0),Vector2(1,1),Vector2(1,0),Vector2(0,0),Vector2(0,1),Vector2(1,1)]:
     var p:Vector3=normal+u*((x+corner.x)/24.*2.-1.)+v*((y+corner.y)/24.*2.-1.)
     p*=Vector3(1.7,1.7,.65)
     var core:Vector3=p.clamp(Vector3(-1.42,-1.42,-.37),Vector3(1.42,1.42,.37))
     var n: Vector3=(p-core).normalized()
     st.set_normal(n)
     st.add_vertex(core+n*.28)
 return st.commit()
func _ready() -> void:
 seed(42)
 marks.resize(16); pigments.resize(16)
 camera=Camera3D.new(); add_child(camera)
 camera.position=Vector3(0,0,13); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=8.; camera.current=true
 var env:=WorldEnvironment.new(); var e:=Environment.new()
 e.background_mode=Environment.BG_COLOR; e.background_color=Color("101827")
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color("b4c4e4"); e.ambient_light_energy=.45
 env.environment=e; add_child(env)
 var key:=DirectionalLight3D.new(); key.rotation_degrees=Vector3(-35,-30,0); key.light_energy=1.7; add_child(key)
 var fill:=OmniLight3D.new(); fill.position=Vector3(3,2,5); fill.light_color=Color("b8dbff"); fill.light_energy=2.; fill.omni_range=12; add_child(fill)
 block=MeshInstance3D.new(); block.mesh=rounded_mesh(); block.position.y=1.1; add_child(block)
 mat=ShaderMaterial.new(); mat.shader=load("res://prototype/paint3d.gdshader"); block.material_override=mat
 var canvas:=CanvasLayer.new(); add_child(canvas)
 label=Label.new(); label.position=Vector2(38,36); label.add_theme_font_size_override("font_size",23); canvas.add_child(label)
 var help:=Label.new(); help.position=Vector2(38,850); help.text="Drag upward + release to shoot\n1 / 2 / 3 color   •   R reset   •   Space auto\nReal rounded mesh • local-space paint • no fluid solver"; help.add_theme_font_size_override("font_size",16); canvas.add_child(help)
 for i in range(3): sphere(Vector3(-1.8+i*1.8,-3.4,1.1),.25,COLORS[i])
func sphere(pos:Vector3,radius:float,color:Color)->MeshInstance3D:
 var node:=MeshInstance3D.new(); var mesh:=SphereMesh.new(); mesh.radius=radius; mesh.height=radius*2; mesh.radial_segments=20; mesh.rings=10; node.mesh=mesh
 var material:=StandardMaterial3D.new(); material.albedo_color=color; material.roughness=.2; node.material_override=material
 add_child(node); node.position=pos; return node
func sdf(p:Vector3)->float:
 var q:=p.abs()-Vector3(1.42,1.42,.37)
 return Vector3(maxf(q.x,0),maxf(q.y,0),maxf(q.z,0)).length()+minf(maxf(q.x,maxf(q.y,q.z)),0)-.28
func launch(target:Vector3,index:int)->void:
 var start:=Vector3(-1.8+index*1.8,-3.4,3.0)
 var n:=sphere(start,.16,COLORS[index])
 shots.append({"node":n,"vel":(target-start).normalized()*3.,"color":index})
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed:
  if event.keycode>=KEY_1 and event.keycode<=KEY_3: selected=event.keycode-KEY_1
  if event.keycode==KEY_SPACE: auto_mode=not auto_mode
  if event.keycode==KEY_R: get_tree().reload_current_scene()
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed: dragging=true; auto_mode=false
  elif dragging:
   dragging=false
   var origin:=camera.project_ray_origin(event.position)
   if origin.y> -2.8: launch(Vector3(origin.x,origin.y,0),selected)
func _process(delta:float)->void:
 t+=delta
 block.rotation=Vector3(.12,sin(t*.65)*.4,.05*sin(t*.4))
 block.position.x=sin(t*.8)*.22
 if auto_mode and next_shot<schedule.size() and t>=schedule[next_shot]:
  launch(block.to_global(Vector3(-1.25+float(next_shot%3)*1.25,-.1,.35)),next_shot%3); next_shot+=1
 for i in range(mini(count,16)): marks[i].w+=delta
 mat.set_shader_parameter("marks",marks); mat.set_shader_parameter("pigments",pigments); mat.set_shader_parameter("count",mini(count,16))
 for i in range(shots.size()-1,-1,-1):
  var s:Dictionary=shots[i]; var n:MeshInstance3D=s.node; var old:=n.position
  s.vel=(s.vel as Vector3).normalized()*minf((s.vel as Vector3).length()+8.*delta,11.)
  n.position+=s.vel*delta
  var hit:=false
  for k in range(1,9):
   var point:=old.lerp(n.position,k/8.)
   var local:=block.to_local(point)
   if sdf(local)<=.015:
    var slot:=count%16; marks[slot]=Vector4(local.x,local.y,local.z,0); pigments[slot]=COLORS[s.color]; count+=1
    for j in range(18):
     var d:=sphere(point,.025+randf()*.04,COLORS[s.color])
     drops.append({"node":d,"vel":Vector3(randf_range(-2,2),randf_range(-1,2),randf_range(.2,2)),"age":0.})
    hit=true; break
  if hit or n.position.length()>15: n.queue_free(); shots.remove_at(i)
 for i in range(drops.size()-1,-1,-1):
  var d:Dictionary=drops[i]; d.age+=delta; d.vel.y-=4*delta; d.node.position+=d.vel*delta
  d.node.scale=Vector3.ONE*maxf(.01,1.-d.age/.7)
  if d.age>.7: d.node.queue_free(); drops.remove_at(i)
 label.text="COLORAWAKENS\n3D PIGMENT STUDY   /   %02d HITS"%count
 if "--test" in OS.get_cmdline_user_args() and t>13:
  assert(count==6,"Six shots must hit rounded mesh")
  assert(marks[0].w>10,"Paint must persist")
  assert(drops.is_empty(),"Transient splash must expire")
  print("PASS: 3D rounded SDF, six swept hits, persistent local pigment, expired droplets")
  get_tree().quit()
