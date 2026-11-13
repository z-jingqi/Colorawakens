extends Node3D
var centers:Array=[]
var cluster:Node3D
var shape:MeshInstance3D
var material:ShaderMaterial
var caption:Label
var elapsed:=0.0
var last_frame_usec:=0
var count:=1
var frame_times:Array[float]=[]
var update_times:Array[float]=[]
var targets:Array=[]
const DURATION:=1.65

func next_center(existing:Array)->Vector3:
 const GAP:=1.40
 if existing.is_empty():return Vector3(-.70,0,0)
 if existing.size()==1:return Vector3(.70,0,0)
 if existing.size()==2:return Vector3(0,sqrt(3.)*.70,0)
 # Intersections of three equal-distance spheres produce candidates touching three neighbors.
 var average:=Vector3.ZERO
 for c in existing:average+=c
 average/=existing.size()
 var best:=Vector3.ZERO
 var best_score:=INF
 for i in range(existing.size()-2):
  for j in range(i+1,existing.size()-1):
   for k in range(j+1,existing.size()):
    var a:Vector3=existing[i]
    var b:Vector3=existing[j]
    var c:Vector3=existing[k]
    var ex:Vector3=(b-a).normalized()
    var d:float=a.distance_to(b)
    var ix:float=ex.dot(c-a)
    var ey:Vector3=c-a-ex*ix
    if ey.length()<.001:continue
    ey=ey.normalized()
    var jy:float=ey.dot(c-a)
    var x:float=d*.5
    var y:float=(ix*ix+jy*jy-2.*ix*x)/(2.*jy)
    var z2:float=GAP*GAP-x*x-y*y
    if z2<0.:continue
    var base:Vector3=a+ex*x+ey*y
    var ez:Vector3=ex.cross(ey)
    for sign_value in [1.,-1.]:
     var candidate:Vector3=base+ez*sqrt(z2)*sign_value
     var valid:=true
     for old in existing:
      if candidate.distance_to(old)<GAP-.001:valid=false
     if not valid:continue
     # Smallest radius about the existing centroid favors compact clusters.
     var score:float=candidate.distance_squared_to(average)
     score-=candidate.z*.0001
     if score<best_score:
      best_score=score
      best=candidate
 assert(is_finite(best_score))
 return best

func configure_material(m:ShaderMaterial,cs:Array)->void:
 var packed:=PackedVector3Array()
 for i in range(8):packed.append(cs[i] if i<cs.size() else Vector3.ZERO)
 m.set_shader_parameter("lobes",cs.size())
 m.set_shader_parameter("centers",packed)

func _ready()->void:
 get_viewport().msaa_3d=Viewport.MSAA_4X
 var camera:=Camera3D.new()
 camera.position=Vector3(0,0,14)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=5.8
 add_child(camera)
 var bg:=MeshInstance3D.new()
 var quad:=QuadMesh.new()
 quad.size=Vector2(14,16)
 bg.mesh=quad
 bg.position.z=-3.
 var bm:=ShaderMaterial.new()
 bm.shader=load("res://joined_glass/backdrop.gdshader")
 bg.material_override=bm
 add_child(bg)
 cluster=Node3D.new()
 add_child(cluster)
 shape=MeshInstance3D.new()
 var proxy:=BoxMesh.new()
 proxy.size=Vector3.ONE*14.
 shape.mesh=proxy
 material=ShaderMaterial.new()
 material.shader=load("res://fusion_glass/glass.gdshader")
 shape.material_override=material
 cluster.add_child(shape)
 var ui:=CanvasLayer.new()
 add_child(ui)
 caption=Label.new()
 caption.position=Vector2(0,75)
 caption.size=Vector2(720,45)
 caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.add_theme_font_size_override("font_size",22)
 caption.modulate=Color(.16,.24,.31)
 ui.add_child(caption)
 var label:=Label.new()
 label.text="LIQUID JOIN / STABLE FINAL SHAPE"
 label.position=Vector2(0,855)
 label.size=Vector2(720,45)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",16)
 label.modulate=Color(.22,.31,.38)
 ui.add_child(label)
 for i in range(5):targets.append(next_center(targets))
 update_scene(0.)
 if "--test-fusion" in OS.get_cmdline_user_args():
  var checks:=0
  for join in range(1,5):
   var last:=state_at(float(join)*3.-DURATION)
   for frame in range(1,100):
    var t:=float(join)*3.-DURATION+float(frame)*DURATION/99.
    var current:=state_at(t)
    var old_centers:Array=last.centers
    var new_centers:Array=current.centers
    assert(new_centers.size()==join+1)
    assert(new_centers[-1].distance_to(old_centers[-1])<.14)
    assert(absf(current.blend-last.blend)<.015)
    assert(current.shift.distance_to(last.shift)<.02)
    last=current
    checks+=4
   assert(last.centers[-1].distance_to(targets[join])<.0001)
   assert(absf(last.blend-.30)<.0001)
   checks+=2
  var stable:=state_at(15.)
  assert(stable.centers.size()==5)
  assert(stable.centers==targets)
  assert(shape.mesh is BoxMesh)
  checks+=3
  print("FUSION: ",checks," checks passed")
  get_tree().quit()

func state_at(time:float)->Dictionary:
 var settled:=mini(1+int(time/3.),5)
 var cs:Array=targets.slice(0,settled)
 var shift:=Vector3.ZERO
 for c in cs:shift+=c
 shift/=cs.size()
 var blend:=.30
 var joining:=false
 if settled<5:
  var local_time:=fmod(time,3.)
  if local_time>=3.-DURATION-.00001:
   joining=true
   var u:=clampf((local_time-(3.-DURATION))/DURATION,0.,1.)
   var target:Vector3=targets[settled]
   var approach_direction:Vector3=((target-shift).normalized()+Vector3(.75,1.,0.)).normalized()
   var incoming_from:Vector3=target+approach_direction*5.2
   var ease:=u*u*(3.-2.*u)
   var approach:=smoothstep(0.,.60,u)
   var settle:=smoothstep(.60,1.,u)
   var offset:=lerpf(5.2,.25,approach) if u<.60 else lerpf(.25,0.,settle)
   cs.append(target+(incoming_from-target).normalized()*offset)
   var final_shift:Vector3=(shift*settled+target)/float(settled+1)
   shift=shift.lerp(final_shift,ease)
   # Brief extra curvature only during contact; zero at either endpoint.
   var contact:=clampf((u-.45)/.55,0.,1.)
   blend=.30+.16*sin(PI*contact)*sin(PI*contact)
 return {"centers":cs,"shift":shift,"blend":blend,"joining":joining,"settled":settled}

func update_scene(time:float)->void:
 var state:=state_at(time)
 configure_material(material,state.centers)
 material.set_shader_parameter("union_blend",state.blend)
 shape.position=-state.shift
 count=state.centers.size()
 caption.text=("%d BALLS / LIQUID JOIN" if state.joining else "%d BALLS / SETTLED") % count
 cluster.rotation.y=maxf(0.,time-9.)*.32
 cluster.rotation.x=sin(maxf(0.,time-9.)*.25)*.18

func _process(delta:float)->void:
 elapsed+=delta
 var begin:=Time.get_ticks_usec()
 var wall_frame_ms:=float(begin-last_frame_usec)/1000. if last_frame_usec>0 else delta*1000.
 last_frame_usec=begin
 update_scene(elapsed)
 if "--benchmark-fusion" in OS.get_cmdline_user_args() and elapsed>2.:
  frame_times.append(wall_frame_ms)
  update_times.append(float(Time.get_ticks_usec()-begin)/1000.)
 if elapsed>=21.:
  if "--benchmark-fusion" in OS.get_cmdline_user_args():
   frame_times.sort()
   var mean:=0.
   var update_mean:=0.
   for v in frame_times:mean+=v
   for v in update_times:update_mean+=v
   mean/=frame_times.size()
   update_mean/=update_times.size()
   print("FUSION BENCHMARK frames=",frame_times.size()," mean_frame_ms=",mean," approx_fps=",1000./mean," p95_ms=",frame_times[int(frame_times.size()*.95)]," mean_script_update_ms=",update_mean)
   get_tree().quit()
  elif "--capture-fusion" in OS.get_cmdline_user_args():get_tree().quit()
