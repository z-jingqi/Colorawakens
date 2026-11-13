extends Node2D
# Independent memory-ball prototype. All speeds and timings are provisional.
const COLORS = [Color("f27992"), Color("f7ce65"), Color("6ebae9")]
const R = 24.0
const ORIGIN = Vector2(360, 862)
const DRAG_AREA = Rect2(52, 786, 616, 135)
const BG_RECT = Rect2(60, 128, 600, 620)
@export var single_fall_speed = 34.0
@export var additional_ball_speed = 24.0
@export var maximum_fall_speed = 130.0
@export var shot_initial_speed = 230.0
@export var shot_acceleration = 900.0
@export var shot_maximum_speed = 1100.0
var groups: Array = []
var shots: Array = []
var flights: Array = []
var bursts: Array = []
var revealed: Array = []
var queue: Array = []
var rng = RandomNumberGenerator.new()
var drag = false
var pointer = ORIGIN
var drag_origin = ORIGIN
var finger = -1
var reserved = 0
var restored = 0
var missed = 0
var spawn_clock = 0.0
var spawn_index = 0
var cooldown = 0.0
var elapsed = 0.0
var state = "play"
var complete_alpha = 0.0
var demo = false
var demo_clock = 0.0
var demo_end = 0.0
var demo_aim = Vector2.ZERO
var font = ThemeDB.fallback_font
var material_bg: ShaderMaterial
var audio: AudioStreamPlayer
var checks = 0

func _ready():
 var bg = Sprite2D.new()
 bg.texture = load("res://memory/scene.svg")
 bg.position = BG_RECT.position + BG_RECT.size/2
 material_bg = ShaderMaterial.new()
 material_bg.shader = load("res://memory/reveal.gdshader")
 var centers = PackedVector2Array()
 for i in range(12): centers.append(reveal_point(i)/BG_RECT.size)
 material_bg.set_shader_parameter("centers", centers)
 bg.material = material_bg
 bg.z_index = -1
 add_child(bg)
 audio = AudioStreamPlayer.new()
 add_child(audio)
 demo = "--demo-memory" in OS.get_cmdline_user_args()
 reset()
 if "--test-memory" in OS.get_cmdline_user_args(): run_tests.call_deferred()

func reset():
 groups.clear(); shots.clear(); flights.clear(); bursts.clear(); revealed.clear(); queue.clear()
 rng.seed = 271828 if demo else Time.get_ticks_usec()
 for i in range(12): revealed.append(0.0)
 set_meta("bag",[])
 for i in range(3): queue.append(next_color())
 drag = false; finger = -1; pointer = ORIGIN; reserved = 0; restored = 0; missed = 0
 spawn_clock = .3; spawn_index = 0; cooldown = 0; elapsed = 0; complete_alpha = 0; state = "play"
 demo_clock = .7; demo_end = 0

func next_color() -> int:
 # A shuffled three-color bag avoids long unplayable runs without changing previews.
 if not has_meta("bag") or get_meta("bag").is_empty():
  var bag = [0,1,2]
  for i in range(2,0,-1):
   var j = rng.randi_range(0,i)
   var t = bag[i]; bag[i] = bag[j]; bag[j] = t
  set_meta("bag",bag)
 var b: Array = get_meta("bag")
 return b.pop_front()

func reveal_point(i: int) -> Vector2:
 return Vector2(100+(i%3)*200,77.5+floori(i/3.0)*155)

func fall_speed(count: int) -> float:
 return minf(maximum_fall_speed,single_fall_speed+maxi(count-1,0)*additional_ball_speed)

func new_group(p: Vector2, c: int) -> Dictionary:
 return {"p":p,"balls":[{"o":Vector2.ZERO,"c":c}],"pulse":0.0}

func colors_in(g: Dictionary) -> Array:
 var result: Array = []
 for b in g.balls:
  if b.c not in result: result.append(b.c)
 return result

func start_drag(p: Vector2, id: int = -1):
 if state != "play" or drag or cooldown>0 or p.distance_to(ORIGIN)>42: return
 drag = true; finger = id; pointer = ORIGIN; drag_origin = p

func move_drag(p: Vector2):
 if drag: pointer = Vector2(clampf(p.x,DRAG_AREA.position.x+R,DRAG_AREA.end.x-R),ORIGIN.y)

func release_drag(p: Vector2):
 if not drag: return
 move_drag(p)
 if DRAG_AREA.has_point(p) and p.distance_to(drag_origin)>8 and state=="play":
  shots.append({"p":pointer,"speed":shot_initial_speed,"c":queue[0]})
  queue.pop_front(); queue.append(next_color()); cooldown = .18
  tone(440+queue[0]*110,.045)
 cancel_drag()

func cancel_drag():
 drag = false; finger = -1; pointer = ORIGIN

func _input(event):
 if event is InputEventKey and event.pressed:
  if event.keycode == KEY_R: reset()
  if event.keycode == KEY_ESCAPE: toggle_pause()
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if event.pressed:
   if event.position.x>615 and event.position.y<100: toggle_pause()
   elif state=="won" and Rect2(210,550,300,65).has_point(event.position): reset()
   else: start_drag(event.position)
  elif finger==-1: release_drag(event.position)
 if event is InputEventMouseMotion and finger==-1: move_drag(event.position)
 if event is InputEventScreenTouch:
  if event.pressed:
   if event.position.x>615 and event.position.y<100: toggle_pause()
   elif state=="won" and Rect2(210,550,300,65).has_point(event.position): reset()
   else: start_drag(event.position,event.index)
  elif event.index==finger: release_drag(event.position)
 if event is InputEventScreenDrag and event.index==finger: move_drag(event.position)

func toggle_pause():
 if state=="play": state="paused"; cancel_drag()
 elif state=="paused": state="play"

func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and state=="play" and not demo:
  state="paused"; cancel_drag()

func spawn_ball():
 var x = [140,360,570,245,465][spawn_index%5]
 var c = spawn_index%3
 groups.append(new_group(Vector2(x,105),c))
 spawn_index+=1

func _process(dt):
 elapsed+=dt
 if state=="play":
  step(dt)
  if demo: pilot(dt)
 elif state=="won":
  complete_alpha=move_toward(complete_alpha,1.0,dt*.7)
  if demo:
   demo_end+=dt
   if demo_end>3: print("MEMORY_DEMO_COMPLETE restored=",restored," missed=",missed); get_tree().quit()
 update_fx(dt)
 if material_bg:
  material_bg.set_shader_parameter("amounts",PackedFloat32Array(revealed))
  material_bg.set_shader_parameter("complete",complete_alpha)
 queue_redraw()
 if demo and elapsed>100:
  print("MEMORY_DEMO_TIMEOUT restored=",restored); get_tree().quit(1)

func step(dt: float):
 cooldown=maxf(0,cooldown-dt)
 spawn_clock-=dt
 if spawn_clock<=0 and reserved<12:
  spawn_ball(); spawn_clock=2.35
 for g in groups:
  # A size-dependent constant speed, NOT gravity or time acceleration.
  g.p.y+=fall_speed(g.balls.size())*dt
  g.pulse=maxf(0,g.pulse-dt*3)
 for i in range(shots.size()-1,-1,-1):
  var s: Dictionary=shots[i]
  var old: Vector2=s.p
  s.speed=minf(shot_maximum_speed,s.speed+shot_acceleration*dt)
  s.p.y-=s.speed*dt
  var hit_group=-1
  var hit_ball=-1
  var best_t=2.0
  for gi in range(groups.size()):
   for bi in range(groups[gi].balls.size()):
    var center: Vector2=groups[gi].p+groups[gi].balls[bi].o
    var t=segment_hit(old,s.p,center,R*2)
    if t>=0 and t<best_t: best_t=t; hit_group=gi; hit_ball=bi
  if hit_group>=0:
   var g: Dictionary=groups[hit_group]
   var center: Vector2=g.p+g.balls[hit_ball].o
   var contact=old.lerp(s.p,best_t)
   var direction=(contact-center).normalized()
   if direction.length()<.1: direction=Vector2.DOWN
   attach_ball(g,center+direction*(R*1.88),s.c)
   shots.remove_at(i)
   if colors_in(g).size()==3: fuse(hit_group)
  elif s.p.y<60: shots.remove_at(i)
 # Falling clusters also stick when their outer balls meet.
 var merged=true
 var budget=0
 while merged and budget<30:
  merged=false; budget+=1
  for i in range(groups.size()):
   if merged: break
   for j in range(i+1,groups.size()):
    if groups_touch(groups[i],groups[j]):
     merge_groups(i,j); merged=true; break
 for i in range(groups.size()-1,-1,-1):
  var lowest=groups[i].p.y
  for b in groups[i].balls: lowest=maxf(lowest,groups[i].p.y+b.o.y)
  if lowest>756:
   missed+=groups[i].balls.size(); groups.remove_at(i)

func segment_hit(a: Vector2,b: Vector2,c: Vector2,r: float) -> float:
 var d=b-a
 var f=a-c
 if f.length_squared()<=r*r: return 0
 var aa=d.dot(d)
 if aa<.00001: return -1
 var bb=2*f.dot(d)
 var cc=f.dot(f)-r*r
 var discriminant=bb*bb-4*aa*cc
 if discriminant<0: return -1
 var t=(-bb-sqrt(discriminant))/(2*aa)
 return t if t>=0 and t<=1 else -1

func attach_ball(g: Dictionary,p: Vector2,c: int):
 g.balls.append({"o":p-g.p,"c":c}); g.pulse=1
 tone(550+g.balls.size()*70,.08)

func groups_touch(a: Dictionary,b: Dictionary) -> bool:
 for ba in a.balls:
  for bb in b.balls:
   if (a.p+ba.o).distance_squared_to(b.p+bb.o)<pow(R*1.95,2): return true
 return false

func merge_groups(i: int,j: int):
 var a: Dictionary=groups[i]
 var b: Dictionary=groups[j]
 for ball in b.balls: a.balls.append({"o":b.p+ball.o-a.p,"c":ball.c})
 a.pulse=1
 groups.remove_at(j)
 if colors_in(a).size()==3: fuse(i)

func fuse(index: int):
 var g: Dictionary=groups[index]
 var center: Vector2=g.p
 for b in g.balls: center+=b.o/g.balls.size()
 groups.remove_at(index)
 if reserved>=12: return
 # Temporary art direction: fly into a still-gray background patch automatically.
 var target_index=reserved
 reserved+=1
 flights.append({"from":center,"to":BG_RECT.position+reveal_point(target_index),"t":0.0,"index":target_index})
 for i in range(15):
  bursts.append({"p":center,"v":Vector2.from_angle(i*TAU/15)*rng.randf_range(30,100),"life":.6,"max":.6,"c":COLORS[i%3]})
 tone(940,.14)

func update_fx(dt):
 if state=="paused": return
 for i in range(flights.size()-1,-1,-1):
  flights[i].t+=dt
  if flights[i].t>=1.1:
   var f: Dictionary=flights[i]
   revealed[f.index]=.01
   restored+=1
   for j in range(24): bursts.append({"p":f.to,"v":Vector2.from_angle(j*TAU/24)*rng.randf_range(35,150),"life":.85,"max":.85,"c":Color.from_hsv(float(j)/24,.5,1)})
   flights.remove_at(i); tone(1250,.16)
   if restored==12: state="won"; cancel_drag(); groups.clear(); shots.clear()
 for i in range(12):
  if revealed[i]>0: revealed[i]=minf(1,revealed[i]+dt*1.8)
 for i in range(bursts.size()-1,-1,-1):
  bursts[i].p+=bursts[i].v*dt; bursts[i].v*=pow(.4,dt); bursts[i].life-=dt
  if bursts[i].life<=0: bursts.remove_at(i)

func pilot(dt):
 demo_clock-=dt
 if drag:
  var a=clampf((.30-demo_clock)/.30,0,1)
  move_drag(ORIGIN.lerp(demo_aim,a))
  if demo_clock<=0: release_drag(demo_aim); demo_clock=.55
  return
 if demo_clock>0 or cooldown>0 or not shots.is_empty(): return
 var best=-1.0
 var aim=Vector2.ZERO
 for g in groups:
  if queue[0] in colors_in(g): continue
  var bottom: Vector2=g.p
  for b in g.balls:
   if (g.p+b.o).y>bottom.y: bottom=g.p+b.o
  if bottom.y>640 or bottom.y<135: continue
  var priority=g.balls.size()*1000+bottom.y
  if priority>best: best=priority; aim=Vector2(bottom.x,ORIGIN.y)
 if best<0:
  # No suitable color currently: use an empty side lane, advancing the real queue.
  aim=Vector2(82,ORIGIN.y)
 if absf(aim.x-ORIGIN.x)<9: aim.x+=10
 demo_aim=aim; start_drag(ORIGIN); demo_clock=.30

func tone(hz: float,duration: float):
 if audio==null or "--test-memory" in OS.get_cmdline_user_args(): return
 var wav=AudioStreamWAV.new()
 wav.format=AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate=22050
 var samples=int(duration*22050)
 var data=PackedByteArray(); data.resize(samples*2)
 for i in range(samples):
  var env=pow(1.0-float(i)/samples,2)
  var value=int(sin(float(i)*TAU*hz/22050)*env*2800)
  data.encode_s16(i*2,value)
 wav.data=data; audio.stream=wav; audio.play()

func label(text: String,p: Vector2,size: int=20,color: Color=Color("dbe7ef")):
 draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func pill(rect: Rect2,color: Color,radius: float=16):
 var style=StyleBoxFlat.new(); style.bg_color=color
 style.set_corner_radius_all(int(radius)); draw_style_box(style,rect)

func orb(p: Vector2,c: Color,r: float=R,alpha: float=1.0):
 draw_circle(p+Vector2(0,4),r+3,Color(0,0,0,.16*alpha))
 draw_circle(p,r,Color(c.darkened(.18),alpha))
 draw_circle(p+Vector2(-2,-3),r*.89,Color(c,alpha))
 draw_circle(p+Vector2(-5,-7),r*.57,Color(c.lightened(.15),alpha))
 draw_arc(p,r*.87,3.4,5.5,20,Color(1,1,1,.42*alpha),1.5,true)
 draw_circle(p+Vector2(-r*.29,-r*.34),r*.15,Color(1,1,1,.78*alpha))

func rainbow(p: Vector2,r: float):
 orb(p,Color("d2e6ee"),r)
 for i in range(6):
  var c=Color.from_hsv(float(i)/6,.55,1)
  draw_arc(p,r*.75,i*TAU/6,(i+1)*TAU/6,12,c,r*.45,true)
 draw_circle(p+Vector2(-5,-7),r*.17,Color(1,1,1,.9))

func _draw():
 # The scene sprite is at z=-1; foreground panels never obscure its reveal.
 pill(Rect2(28,25,664,83),Color("192536"),22)
 label("COLORAWAKENS",Vector2(52,56),16,Color("a2b8cc"))
 label("A memory in bloom",Vector2(52,87),26)
 label(str(restored)+" / 12",Vector2(516,76),24,Color("f3dca0"))
 label("II" if state!="paused" else ">",Vector2(640,75),25)
 draw_rect(BG_RECT.grow(3),Color("8ea6b0"),false,2)
 # Dark vignette gives foreground balls contrast while preserving the picture.
 for g in groups:
  for b in g.balls:
   var p: Vector2=g.p+b.o
   for other in g.balls:
    var q: Vector2=g.p+other.o
    if p.distance_to(q)<R*2.3: draw_line(p,q,Color("c2cbd2"),13,true)
  for b in g.balls: orb(g.p+b.o,COLORS[b.c],R*(1+g.pulse*.055))
  if g.balls.size()>1:
   var p: Vector2=g.p+Vector2(34,-35)
   label("v "+str(int(fall_speed(g.balls.size()))),p,13,Color("ffffff"))
 for s in shots:
  draw_line(s.p,s.p+Vector2(0,30),Color(COLORS[s.c],.4),8,true)
  orb(s.p,COLORS[s.c])
 for f in flights:
  var t=clampf(f.t/1.1,0,1)
  var p: Vector2=f.from.lerp(f.to,smoothstep(.1,1,t))+Vector2(sin(t*PI)*38,-sin(t*PI)*50)
  draw_arc(p,32*(1-t)+12,elapsed*2,elapsed*2+TAU*.8,32,Color("fff0c9"),2,true)
  rainbow(p,lerpf(29,10,t))
 for b in bursts:
  draw_circle(b.p,3.5*float(b.life)/b.max,Color(b.c,float(b.life)/b.max))
 draw_line(Vector2(60,756),Vector2(660,756),Color("92a8bb"),1,true)
 pill(Rect2(28,778,664,158),Color("192536"),24)
 label("NEXT",Vector2(74,815),13,Color("96aec3"))
 orb(Vector2(96,860),COLORS[queue[1]],18)
 orb(Vector2(151,860),COLORS[queue[2]],14)
 label("1",Vector2(92,898),12,Color("a2b8cc")); label("2",Vector2(148,898),12,Color("a2b8cc"))
 if drag:
  for y in range(150,790,18): draw_line(Vector2(pointer.x,y),Vector2(pointer.x,y+7),Color(1,1,1,.32),1.5,true)
  draw_arc(ORIGIN,29,0,TAU,40,Color("567087"),1.5,true)
  orb(pointer,COLORS[queue[0]],27)
 else:
  draw_circle(ORIGIN,38,Color("2a3d53")); orb(ORIGIN,COLORS[queue[0]],27)
 label("DRAG  /  RELEASE",Vector2(272,921),13,Color("b4c8d7"))
 label("3 colors",Vector2(535,845),16)
 label("1 memory",Vector2(535,873),16,Color("f3dca0"))
 if elapsed<6 and state=="play":
  pill(Rect2(102,705,516,35),Color(0.06,.1,.15,.87),12)
  label("Stick different colors together to awaken the picture",Vector2(116,729),16)
 if state=="paused":
  draw_rect(Rect2(0,0,720,960),Color(0,0,0,.55)); label("PAUSED",Vector2(282,452),36)
  label("Tap II / press Esc to continue",Vector2(220,495),18)
 if state=="won" and demo_end>1.5 or state=="won" and not demo:
  pill(Rect2(138,364,444,260),Color(.07,.12,.19,.94),26)
  label("MEMORY AWAKENED",Vector2(189,422),28,Color("f8dfa3"))
  label("A quiet afternoon, in full color.",Vector2(203,467),19)
  pill(Rect2(210,550,300,56),Color("a4d8ca"),18)
  label("Play again",Vector2(300,586),22,Color("153c48"))

func check(ok: bool,why: String):
 checks+=1
 if not ok: push_error("FAILED: "+why); get_tree().quit(1)

func run_tests():
 set_process(false)
 check(queue.size()==3,"current plus two previews")
 check(fall_speed(2)>fall_speed(1),"joined speed increases")
 check(fall_speed(8)<=maximum_fall_speed,"speed capped")
 groups=[new_group(Vector2(200,200),0)]; spawn_clock=999
 step(.5); var y=groups[0].p.y; step(.5)
 check(is_equal_approx(groups[0].p.y-y,single_fall_speed*.5),"single constant speed")
 attach_ball(groups[0],groups[0].p+Vector2(0,45),0)
 var p=groups[0].p.y; step(.5); y=groups[0].p.y; step(.5)
 check(is_equal_approx(y-p,fall_speed(2)*.5) and is_equal_approx(groups[0].p.y-y,fall_speed(2)*.5),"joined speed constant over time")
 check(colors_in(groups[0]).size()==1,"same colors not distinct")
 attach_ball(groups[0],groups[0].p+Vector2(40,0),1)
 check(colors_in(groups[0]).size()==2,"three balls with two colors not fusion")
 attach_ball(groups[0],groups[0].p+Vector2(-40,0),2)
 fuse(0)
 check(groups.is_empty() and flights.size()==1 and reserved==1,"three colors become one flight")
 update_fx(1.2)
 check(restored==1 and revealed[0]>0,"flight reveals background")
 reset(); set_meta("bag",[])
 var old=queue.duplicate()
 start_drag(ORIGIN); move_drag(Vector2(540,845)); release_drag(Vector2(540,845))
 check(shots.size()==1 and shots[0].p.x==540,"released horizontal position")
 check(queue[0]==old[1] and queue[1]==old[2] and queue.size()==3,"queue advances correctly")
 var x=shots[0].p.x; var speed=shots[0].speed; spawn_clock=999; step(.1)
 check(shots[0].p.x==x and shots[0].speed>speed,"vertical accelerated shot")
 cooldown=0; start_drag(ORIGIN); release_drag(Vector2(500,500))
 check(shots.size()==1,"outside cancel")
 start_drag(ORIGIN); release_drag(ORIGIN)
 check(shots.size()==1,"tap cancels")
 start_drag(ORIGIN,3); toggle_pause()
 check(not drag and finger==-1 and state=="paused","pause cancels touch")
 toggle_pause(); check(state=="play","resume")
 check(segment_hit(Vector2(0,100),Vector2(0,-100),Vector2.ZERO,10)>=0,"swept hit no tunneling")
 check(segment_hit(Vector2(50,100),Vector2(50,-100),Vector2.ZERO,10)<0,"swept miss")
 reset(); spawn_clock=999
 groups=[new_group(Vector2(200,250),0),new_group(Vector2(200,295),1)]
 step(.001)
 check(groups.size()==1 and groups[0].balls.size()==2,"falling groups merge")
 groups.append(new_group(groups[0].p+Vector2(43,0),2)); step(.001)
 check(groups.is_empty() and flights.size()==1,"falling merge fuses three colors")
 reset(); spawn_clock=999; groups=[new_group(Vector2(200,755),0)]; step(.1)
 check(missed==1 and groups.is_empty(),"miss cleaned up without blocking progress")
 reset()
 for i in range(12):
  groups=[new_group(Vector2(200,200),0)]; fuse(0)
 update_fx(1.2)
 check(restored==12 and state=="won","all patches win")
 reset(); check(restored==0 and reserved==0 and state=="play","restart resets")
 print("MEMORY_TESTS_PASSED ",checks)
 get_tree().quit()
