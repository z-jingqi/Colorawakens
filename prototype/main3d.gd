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
var schedule=[.7,2.5,4.3]
var color_mask:=0
var finish_time:=-1.0
var exploded:=false
var spirals:Array[Dictionary]=[]
var fragments:Array[Dictionary]=[]
var burst_count:=0
var phase_label:Label
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
     var core:Vector3=p.clamp(Vector3(-1.28,-1.28,-.23),Vector3(1.28,1.28,.23))
     var n: Vector3=(p-core).normalized()
     st.set_normal(n)
     st.add_vertex(core+n*.42)
 return st.commit()
func _ready() -> void:
 seed(42)
 marks.resize(16); pigments.resize(16)
 camera=Camera3D.new(); add_child(camera)
 camera.position=Vector3(0,0,13); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=8.8; camera.current=true
 var env:=WorldEnvironment.new(); var e:=Environment.new()
 e.background_mode=Environment.BG_COLOR; e.background_color=Color("111a2c")
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color=Color("b4c4e4"); e.ambient_light_energy=.45
 env.environment=e; add_child(env)
 var key:=DirectionalLight3D.new(); key.rotation_degrees=Vector3(-35,-30,0); key.light_energy=1.15; add_child(key)
 var fill:=OmniLight3D.new(); fill.position=Vector3(3,2,5); fill.light_color=Color("b8dbff"); fill.light_energy=1.3; fill.omni_range=12; add_child(fill)
 block=MeshInstance3D.new(); block.mesh=rounded_mesh(); block.position.y=1.1; add_child(block)
 mat=ShaderMaterial.new(); mat.shader=load("res://prototype/paint3d.gdshader"); block.material_override=mat
 var canvas:=CanvasLayer.new(); add_child(canvas)
 label=Label.new(); label.position=Vector2(38,36); label.add_theme_font_size_override("font_size",23); canvas.add_child(label)
 var help:=Label.new(); help.position=Vector2(38,890); help.text="DRAG + RELEASE     1 / 2 / 3 COLOR     R REPLAY"; help.add_theme_font_size_override("font_size",16); canvas.add_child(help)
 phase_label=Label.new(); phase_label.position=Vector2(38,755); phase_label.add_theme_font_size_override("font_size",19); canvas.add_child(phase_label)
 for i in range(3): sphere(Vector3(-1.8+i*1.8,-3.4,1.1),.25,COLORS[i])
func sphere(pos:Vector3,radius:float,color:Color)->MeshInstance3D:
 var node:=MeshInstance3D.new(); var mesh:=SphereMesh.new(); mesh.radius=radius; mesh.height=radius*2; mesh.radial_segments=20; mesh.rings=10; node.mesh=mesh
 var material:=StandardMaterial3D.new(); material.albedo_color=color; material.roughness=.13; material.metallic=.1; node.material_override=material
 add_child(node); node.position=pos; return node
func sdf(p:Vector3)->float:
 var q:=p.abs()-Vector3(1.28,1.28,.23)
 return Vector3(maxf(q.x,0),maxf(q.y,0),maxf(q.z,0)).length()+minf(maxf(q.x,maxf(q.y,q.z)),0)-.42
func launch(target:Vector3,index:int)->void:
 if finish_time>=0: return
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
 if auto_mode and finish_time<0 and next_shot<schedule.size() and t>=schedule[next_shot]:
  var c:=0 if "--test-repeat" in OS.get_cmdline_user_args() else next_shot%3
  launch(block.to_global(Vector3(-1.1+float(next_shot%3)*1.1,.15,.35)),c); next_shot+=1
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
   if finish_time<0 and sdf(local)<=.015:
    var slot:=count%16; marks[slot]=Vector4(local.x,local.y,local.z,0); pigments[slot]=COLORS[s.color]; count+=1
    color_mask |= 1 << int(s.color)
    if color_mask==7: begin_finish()
    for j in range(18):
     var d:=sphere(point,.025+randf()*.04,COLORS[s.color])
     drops.append({"node":d,"vel":Vector3(randf_range(-2,2),randf_range(-1,2),randf_range(.2,2)),"age":0.})
    hit=true; break
  if hit or n.position.length()>15: n.queue_free(); shots.remove_at(i)
 for i in range(drops.size()-1,-1,-1):
  var d:Dictionary=drops[i]; d.age+=delta; d.vel.y-=4*delta; d.node.position+=d.vel*delta
  d.node.scale=Vector3.ONE*maxf(.01,1.-d.age/.7)
  if d.age>.7: d.node.queue_free(); drops.remove_at(i)
 label.text="COLORAWAKENS\nCHROMATIC AWAKENING"
 update_finish(delta)
 if finish_time<0: phase_label.text="01  /  COLOR THE WORLD"
 if ("--test" in OS.get_cmdline_user_args() or "--test-repeat" in OS.get_cmdline_user_args()) and t>12:
  assert(count==3,"Three demo shots must hit")
  assert(drops.is_empty(),"Transient impact droplets must expire")
  if "--test-repeat" in OS.get_cmdline_user_args():
   assert(not exploded and finish_time<0,"Repeated color must not trigger rainbow")
   assert(color_mask==1)
  else:
   assert(exploded and burst_count==1,"Three unique colors trigger exactly one explosion")
   assert(not block.visible and fragments.is_empty() and spirals.is_empty(),"All burst particles expire")
  print("PASS: three swept hits; distinct/repeated color gate; ordered absorb-color-burst; particle cleanup")
  get_tree().quit()

func begin_finish()->void:
 if finish_time>=0: return
 finish_time=0.
 for arm in range(3):
  var n:=MeshInstance3D.new()
  var m:=StandardMaterial3D.new()
  m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  m.vertex_color_use_as_albedo=true
  m.cull_mode=BaseMaterial3D.CULL_DISABLED
  n.material_override=m
  add_child(n)
  spirals.append({"node":n,"arm":arm})

func ribbon_point(arm:int,u:float,a:float)->Vector3:
 var progress:=clampf(a/1.65,0.,1.)
 var radius:float=(3.4-u*1.8)*pow(1.-progress,1.05)
 var angle:float=arm*TAU/3.+u*4.8+a*5.
 return block.position+Vector3(cos(angle)*radius,sin(angle)*radius*.83,.96+sin(angle)*.12)

func update_finish(delta:float)->void:
 if finish_time<0: return
 finish_time+=delta
 var a:=finish_time
 if a<1.65:
  phase_label.text="02  /  DRAWING COLOR IN"
  for s in spirals:
   var st:=SurfaceTool.new()
   st.begin(Mesh.PRIMITIVE_TRIANGLES)
   for j in range(64):
    for corner in [Vector2(0,-1),Vector2(1,-1),Vector2(1,1),Vector2(0,-1),Vector2(1,1),Vector2(0,1)]:
     var u:float=(j+corner.x)/64.
     var p:=ribbon_point(s.arm,u,a)
     var tangent:Vector3=(ribbon_point(s.arm,u+.001,a)-p).normalized()
     var across:=Vector3(-tangent.y,tangent.x,0.)
     var width:float=(.006+.075*pow(u,.8))*smoothstep(0.,.15,a)*minf(1.,(1.65-a)*6.)
     st.set_color(COLORS[s.arm].lerp(Color.WHITE,.18+u*.25))
     st.add_vertex(p+across*width*corner.y)
   s.node.mesh=st.commit()
  mat.set_shader_parameter("awaken",smoothstep(.3,1.65,a)*.8)
 elif a<2.65:
  phase_label.text="03  /  FULL SPECTRUM"
  for s in spirals: s.node.queue_free()
  spirals.clear()
  mat.set_shader_parameter("awaken",1.)
  mat.set_shader_parameter("energy",smoothstep(1.65,2.65,a))
  block.scale=Vector3.ONE*(1.+.08*sin((a-1.65)*PI))
 elif not exploded:
  explode()
 if exploded:
  phase_label.text="04  /  COLOR RELEASED"
  for i in range(fragments.size()-1,-1,-1):
   var f:Dictionary=fragments[i]
   f.age+=delta; f.vel.y-=.65*delta
   f.node.position+=f.vel*delta
   f.node.rotation+=f.spin*delta
   var life:float=f.life
   f.node.scale=Vector3.ONE*pow(maxf(0.,1.-f.age/life),.7)
   if f.age>=life: f.node.queue_free(); fragments.remove_at(i)

func explode()->void:
 exploded=true; burst_count+=1; block.visible=false
 for i in range(200):
  var start:=Vector3(randf_range(-1.6,1.6),randf_range(-1.6,1.6),randf_range(-.4,.55))
  var color:=Color.from_hsv(fposmod(start.x*.14+start.y*.17+.55,1.),.75,1.)
  var n:=sphere(block.to_global(start),randf_range(.025,.11),color)
  var m:=n.material_override as StandardMaterial3D
  m.emission_enabled=true; m.emission=color; m.emission_energy_multiplier=.6
  var dir:=Vector3(start.x,start.y,randf_range(-.6,1.6)).normalized()
  fragments.append({"node":n,"vel":dir*randf_range(1.3,4.2),"age":0.,"life":randf_range(1.4,2.5),"spin":Vector3(randf(),randf(),randf())*3.})
