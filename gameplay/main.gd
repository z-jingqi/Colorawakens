extends Node2D
# Simple, deterministic MVP. The independent 3D material study is unchanged.
const COLORS = [Color("ef6c7a"), Color("efbf51"), Color("58a9dc")]
const LAUNCHERS = [Vector2(210, 852), Vector2(360, 852), Vector2(510, 852)]
const LAUNCH_AREA = Rect2(45, 766, 630, 164)
@export var launch_speed = 180.0
@export var shot_acceleration = 850.0
@export var max_shot_speed = 1000.0
const DANGER = 750.0
const RADIUS = 130.0
const LEVELS = [
 {"name":"THE QUIET GARDEN", "target":6, "fall":13.0, "spawn":7.0},
 {"name":"STONE PATH", "target":9, "fall":17.0, "spawn":6.0},
 {"name":"BLOOMING GROVE", "target":12, "fall":20.0, "spawn":5.2}
]
var level = 0
var garden_restored = 0
var level_wait = 0.0
func goal() -> int: return LEVELS[level].target
var blocks: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var cooldowns = [0.0, 0.0, 0.0]
var restored = 0
var lives = 3
var score = 0
var best_chain = 0
var state = "playing"
var drag = -1
var finger = -1
var pointer = Vector2.ZERO
var drag_start = Vector2.ZERO
var demo_drag_target = Vector2.ZERO
var demo_drag_time = 0.0
var spawn_time = 4.0
var elapsed = 0.0
var next_id = 0
var notice = "Move a ball along the bottom. Release to fire up."
var notice_time = 5.0
var wave = 0
var demo = false
var demo_time = 0.0
var demo_next = 0.4
var demo_color = 0
var font: Font = ThemeDB.fallback_font
var checks = 0
var audio: AudioStreamPlayer

func _ready():
 audio = AudioStreamPlayer.new()
 add_child(audio)
 reset()
 demo = "--demo" in OS.get_cmdline_user_args()
 if "--test-gameplay" in OS.get_cmdline_user_args():
  run_tests()

func tone(hz: float):
 if audio == null: return
 var wav = AudioStreamWAV.new()
 wav.format = AudioStreamWAV.FORMAT_16_BITS
 wav.mix_rate = 22050
 var data = PackedByteArray()
 data.resize(4410)
 for i in range(2205):
  var t = float(i)/22050
  var value = sin(TAU*hz*t)*exp(-t*35)*.18
  data.encode_s16(i*2,int(value*32767))
 wav.data = data
 audio.stream = wav
 audio.play()

func add_block(pos: Vector2, hits: Array = [], kind: String = "normal") -> int:
 next_id += 1
 blocks.append({"id":next_id,"p":pos,"hits":hits.duplicate(),"pulse":0.0,"kind":kind,"needed":5 if kind=="hard" else 3})
 return next_id

func reset():
 level=0; garden_restored=0; score=0; best_chain=0
 start_level()

func start_level():
 blocks.clear(); shots.clear(); effects.clear()
 cooldowns = [0.0,0.0,0.0]
 restored = 0; lives = 3
 state = "playing"; drag = -1; finger = -1
 spawn_time = 5.0; elapsed = 0.0; wave = 0; next_id = 0
 notice = "Move a ball along the bottom. Release to fire up."; notice_time = 5.0
 for i in range(3):
  var kind = "normal"
  if level==1 and i==1: kind="hard"
  if level==2 and i==1: kind="bloom"
  add_block(Vector2(260+i*100,220),[],kind)
 if level==1: notice="Stone blocks need 5 hits. Any colors count."
 if level==2: notice="Bloom blocks spread color when restored."
 level_wait=0.0
 queue_redraw()

func launch_position(pos: Vector2) -> Vector2:
 return Vector2(clampf(pos.x, 60, 660), clampf(pos.y, 785, 907))

func launch(index: int, origin: Vector2) -> bool:
 if index < 0 or index >= 3 or state != "playing" or cooldowns[index] > 0: return false
 shots.append({"p":launch_position(origin),"d":Vector2.UP,"speed":launch_speed,"color":index,"trail":[]})
 tone(280+index*70)
 cooldowns[index] = .35
 return true

# Segment / expanded box collision prevents tunnelling at high speed.
func segment_hit(a: Vector2, b: Vector2, p: Vector2) -> float:
 var lo = 0.0
 var hi = 1.0
 var d = b-a
 for axis in range(2):
  var mn = p[axis]-43.0
  var mx = p[axis]+43.0
  if absf(d[axis]) < .0001:
   if a[axis] < mn or a[axis] > mx: return -1.0
  else:
   var t1 = (mn-a[axis])/d[axis]
   var t2 = (mx-a[axis])/d[axis]
   lo = maxf(lo,minf(t1,t2)); hi = minf(hi,maxf(t1,t2))
   if lo > hi: return -1.0
 return lo

func find_hit(a: Vector2, b: Vector2) -> int:
 var nearest = 2.0
 var id = -1
 for block in blocks:
  var t = segment_hit(a,b,block.p)
  if t >= 0 and t < nearest:
   nearest = t; id = block.id
 return id

func paint(id: int, color_index: int):
 tone(480+color_index*120)
 # FIFO propagation: remove completed blocks before propagating. No duplicate completion.
 var pending = [{"id":id,"color":color_index,"depth":1}]
 var completed = 0
 while not pending.is_empty():
  var entry = pending.pop_front()
  var at = -1
  for i in range(blocks.size()):
   if blocks[i].id == entry.id: at = i; break
  if at < 0: continue
  var block = blocks[at]
  block.hits.append(entry.color); block.pulse = .2
  score += 10
  effects.append({"p":block.p,"age":0.0,"life":.3,"color":COLORS[entry.color],"rainbow":false,"size":45.0})
  if block.hits.size() < block.needed: continue
  var rainbow = block.hits.has(0) and block.hits.has(1) and block.hits.has(2)
  blocks.remove_at(at)
  restored += 1; completed += 1
  if restored<=goal(): garden_restored += 1
  score += 100 + (100 * entry.depth if rainbow else 0)
  best_chain = maxi(best_chain,completed)
  effects.append({"p":block.p,"age":0.0,"life":.8,"color":COLORS[entry.color],"rainbow":rainbow,"size":RADIUS if rainbow else 65.0})
  if rainbow or block.kind=="bloom":
   tone(960)
   notice = "BLOOM!  Nearby blocks gain one color." if block.kind=="bloom" else "RAINBOW!  Nearby blocks gain one color."
   notice_time = 2.3
   for other in blocks:
    if other.p.distance_to(block.p) <= RADIUS:
     pending.append({"id":other.id,"color":entry.color,"depth":entry.depth+1})
  else:
   notice = "Restored!  Any three hits work."; notice_time = 1.5
 if completed > 1:
  notice = "CHAIN x%d   •   Beautiful!" % completed; notice_time = 2.5
 if restored >= goal():
  state = "won" if level==2 else "level_won"; drag = -1; shots.clear()

func simulate(dt: float):
 if state != "playing": return
 elapsed += dt
 for i in range(3): cooldowns[i] = maxf(0,cooldowns[i]-dt)
 for block in blocks:
  block.p.y += (LEVELS[level].fall + minf(elapsed*.08,5.0))*dt
  block.pulse = maxf(0,block.pulse-dt)
 for i in range(blocks.size()-1,-1,-1):
  if blocks[i].p.y + 32 >= DANGER:
   blocks.remove_at(i); lives -= 1
   notice = "A block slipped away. Keep the garden safe."; notice_time = 2
   if lives <= 0:
    state = "lost"; drag = -1; shots.clear(); return
 for i in range(shots.size()-1,-1,-1):
  if i >= shots.size(): continue
  var shot = shots[i]
  var old: Vector2 = shot.p
  shot.speed = minf(max_shot_speed,shot.speed+shot_acceleration*dt)
  shot.p += shot.d*shot.speed*dt
  shot.trail.append(old)
  if shot.trail.size()>8: shot.trail.pop_front()
  var hit = find_hit(old,shot.p)
  if hit >= 0:
   shots.remove_at(i); paint(hit,shot.color)
   if state != "playing": return
  elif shot.p.y < 130 or shot.p.x < 35 or shot.p.x > 685:
   shots.remove_at(i)
 spawn_time -= dt
 if spawn_time <= 0 and blocks.size() < 18:
  wave += 1
  var count = 2 if wave < 4 else 3
  for j in range(count):
   var col = (wave*2+j) % 6
   var kind = "normal"
   if level>=1 and (wave+j)%4==0: kind="hard"
   if level==2 and (wave+j)%3==0: kind="bloom"
   add_block(Vector2(110+col*100,170),[],kind)
  spawn_time = maxf(3.5,LEVELS[level].spawn-elapsed*.015)

func _process(dt):
 if demo:
  demo_time += dt
  if demo_time > 120:
   get_tree().quit(); return
  if state=="level_won":
   level_wait+=dt
   if level_wait>1.8: level+=1; start_level()
  if state=="won":
   level_wait+=dt
   if level_wait>3: get_tree().quit(); return
  if drag >= 0:
   demo_drag_time += dt
   pointer = LAUNCHERS[drag].lerp(demo_drag_target, clampf(demo_drag_time/.5,0,1))
   if demo_drag_time >= .7: release(pointer)
  if state == "playing" and drag < 0 and demo_time > demo_next and not blocks.is_empty():
   # Real launch path and collisions; the demo only selects target/color.
   var target = blocks[0]
   for b in blocks:
    if b.p.y > target.p.y: target = b
   var c = demo_color % 3
   if demo_color < 6:
    var desired = demo_color % 3 + 1
    c = int(demo_color / 3)
    for b in blocks:
     if b.id == desired: target = b
   elif demo_color == 6:
    c = 2
    for b in blocks:
     if b.id == 2: target = b
   press(LAUNCHERS[c])
   demo_drag_target = Vector2(target.p.x, 788)
   demo_drag_time = 0.0
   demo_color += 1; demo_next = demo_time + .9
 simulate(dt)
 if state != "paused":
  notice_time = maxf(0,notice_time-dt)
  for i in range(effects.size()-1,-1,-1):
   effects[i].age += dt
   if effects[i].age >= effects[i].life: effects.remove_at(i)
 queue_redraw()

func press(pos: Vector2):
 if Rect2(603,37,70,48).has_point(pos):
  if state == "playing": state = "paused"
  elif state == "paused": state = "playing"
  drag = -1; return
 if state in ["won","lost","level_won"]:
  if Rect2(225,530,270,64).has_point(pos):
   if state=="level_won": level+=1; start_level()
   elif state=="lost":
    garden_restored-=mini(restored,goal())
    start_level()
   else: reset()
  return
 if state == "paused":
  if Rect2(225,530,270,64).has_point(pos): state = "playing"
  return
 for i in range(3):
  if pos.distance_to(LAUNCHERS[i]) < 48 and cooldowns[i] <= 0:
   drag = i; pointer = pos; drag_start = pos; return

func release(pos: Vector2):
 if drag >= 0:
  if pos.distance_to(drag_start) >= 16 and LAUNCH_AREA.has_point(pos): launch(drag,pos)
 drag = -1; finger = -1

func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  drag=-1; finger=-1
  if state=="playing": state="paused"

func _input(event):
 if event is InputEventScreenTouch:
  if event.pressed and finger < 0:
   finger = event.index; press(event.position)
  elif not event.pressed and event.index == finger: release(event.position)
 elif event is InputEventScreenDrag and event.index == finger: pointer = event.position
 elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and finger < 0:
  if event.pressed: press(event.position)
  else: release(event.position)
 elif event is InputEventMouseMotion and finger < 0: pointer = event.position
 elif event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_R: reset()
  if event.keycode == KEY_ESCAPE:
   if state == "playing": state = "paused"
   elif state == "paused": state = "playing"
   drag = -1

func text_at(s: String, p: Vector2, size: int, color = Color("344b52")):
 draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func rounded(rect: Rect2, color: Color, radius = 18):
 var box = StyleBoxFlat.new()
 box.bg_color = color
 box.set_corner_radius_all(radius)
 draw_style_box(box,rect)

func _draw():
 var progress = clampf(float(garden_restored)/27,0,1)
 draw_rect(Rect2(0,0,720,960),Color("e9eced").lerp(Color("d7eef3"),progress))
 # The garden gradually gains color; this is intentionally simple placeholder art.
 draw_circle(Vector2(590,205),50,Color("dadddf").lerp(Color("fff0b3"),progress))
 draw_colored_polygon(PackedVector2Array([Vector2(0,670),Vector2(130,600),Vector2(260,650),Vector2(420,580),Vector2(720,660),Vector2(720,960),Vector2(0,960)]),Color("d2d8d6").lerp(Color("a1cbbb"),progress))
 draw_circle(Vector2(90,745),145,Color("c5ceca").lerp(Color("81b69e"),progress))
 draw_circle(Vector2(590,795),200,Color("cbd3cc").lerp(Color("94c5a2"),progress))
 for i in range(15):
  var p = Vector2(35+i*47,700+sin(i*2.3)*34)
  draw_line(p+Vector2(0,23),p,Color("9aa9a0").lerp(Color("4d9777"),progress),2)
  for j in range(5):
   draw_circle(p+Vector2.from_angle(j*TAU/5)*5,5,Color("c0c7c3").lerp(COLORS[i%3],progress))
  draw_circle(p,3,Color("f6e8ad"))
 rounded(Rect2(30,26,660,104),Color(1,1,1,.75),23)
 text_at("COLORAWAKENS",Vector2(52,61),24)
 text_at("%02d  /  %s" % [level+1,LEVELS[level].name],Vector2(52,86),13,Color("718489"))
 rounded(Rect2(52,104,410,8),Color("dce2e2"),4)
 if progress>0: rounded(Rect2(52,104,410*progress,8),Color("69bfa3"),4)
 text_at("%d / %d" % [mini(restored,goal()),goal()],Vector2(480,113),17)
 text_at("II" if state == "playing" else ">",Vector2(628,70),23)
 text_at("LIFE  " + "●".repeat(maxi(0,lives)),Vector2(52,158),15)
 text_at("%05d" % score,Vector2(580,158),19)
 if drag >= 0 and state == "playing":
  var from = launch_position(pointer)
  var to = from + Vector2.UP*1100
  var hit = find_hit(from,to)
  for block in blocks:
   if block.id == hit:
    rounded(Rect2(block.p-Vector2(41,41),Vector2(82,82)),Color(1,1,1,.8),22)
    to = block.p
  var dist = from.distance_to(to)
  var d = (to-from).normalized()
  for k in range(1,int(dist/22)):
   draw_circle(from+d*k*22,2.6,Color(COLORS[drag],.6))
 for block in blocks:
  var p: Vector2 = block.p
  var scale = 1+block.pulse*.25
  rounded(Rect2(p-Vector2(34,29)*scale,Vector2(68,68)*scale),Color(0.2,.3,.3,.1),17)
  rounded(Rect2(p-Vector2(34,34)*scale,Vector2(68,68)*scale),Color("d6dce2") if block.kind=="hard" else (Color("e4f5dd") if block.kind=="bloom" else Color("f7f8f5")),17)
  draw_line(p+Vector2(-19,-20),p+Vector2(19,-20),Color("e1e6e2"),2)
  for j in range(block.needed):
   var c = COLORS[block.hits[j]] if j<block.hits.size() else Color("d2d9d7")
   draw_circle(p+Vector2((j-(block.needed-1)*.5)*12,5),5,c)
  if block.kind=="hard": text_at("5",p+Vector2(-5,-9),13)
  elif block.kind=="bloom": text_at("+",p+Vector2(-6,-8),18,Color("579d65"))
 for shot in shots:
  for j in range(shot.trail.size()): draw_circle(shot.trail[j],2+j*.7,Color(COLORS[shot.color],.08+j*.025))
  draw_circle(shot.p,11,COLORS[shot.color]); draw_circle(shot.p+Vector2(-3,-3),3,Color(1,1,1,.6))
 for effect in effects:
  var q: float = effect.age/effect.life
  var size: float = effect.size*(.2+q*.8)
  var c: Color = effect.color
  if effect.rainbow:
   for j in range(3): draw_arc(effect.p,size+j*5,j*TAU/3,(j+1)*TAU/3,24,Color(COLORS[j],1-q),3)
  else: draw_arc(effect.p,size,0,TAU,32,Color(c,(1-q)*.65),2)
  for j in range(10):
   var cp = effect.p+Vector2.from_angle(j*TAU/10)*size*.8
   draw_circle(cp,4*(1-q),Color(COLORS[j%3] if effect.rainbow else c,1-q))
 draw_dashed_line(Vector2(45,DANGER),Vector2(675,DANGER),Color("9d7776"),1.5,8)
 rounded(Rect2(35,784,650,146),Color(1,1,1,.83),27)
 text_at(notice if notice_time > 0 else "3 hits restore  •  Red + yellow + blue = rainbow",Vector2(58,811),16)
 for i in range(3):
  var p: Vector2 = LAUNCHERS[i]
  draw_arc(p,29,0,TAU,48,Color(COLORS[i],.3),3)
  if cooldowns[i] <= 0 and drag != i:
   draw_circle(p,23,COLORS[i]); draw_circle(p+Vector2(-6,-7),6,Color(1,1,1,.45))
  elif cooldowns[i] > 0: draw_arc(p,23,-PI/2,-PI/2+TAU*(1-cooldowns[i]/.35),32,COLORS[i],3)
  text_at(["RED","YELLOW","BLUE"][i],p+Vector2(-21,49),12)
 if drag>=0:
  var p = launch_position(pointer)
  draw_circle(p,23,COLORS[drag])
  draw_circle(p+Vector2(-6,-7),6,Color(1,1,1,.45))
  if not LAUNCH_AREA.has_point(pointer): text_at("Release outside the bottom to cancel",Vector2(190,740),16)
 text_at("MOVE BALL • RELEASE TO FIRE UP",Vector2(230,950),12,Color("6c8580"))
 if demo: text_at("GAMEPLAY DEMO",Vector2(263,190),13,Color("718489"))
 if state != "playing":
  draw_rect(Rect2(0,0,720,960),Color(.12,.23,.25,.38))
  rounded(Rect2(145,335,430,300),Color("f7fbf7"),30)
  var title = "Garden awakened" if state == "won" else ("Area restored" if state=="level_won" else ("Try again" if state == "lost" else "Take a breath"))
  text_at(title,Vector2(196,407),32)
  text_at("Score %d   •   Best chain %d" % [score,best_chain],Vector2(205,452),19)
  text_at("%d blocks restored" % restored,Vector2(251,488),17)
  rounded(Rect2(225,530,270,64),Color("6aae98"),18)
  text_at("NEXT AREA" if state=="level_won" else ("CONTINUE" if state == "paused" else ("RETRY AREA" if state=="lost" else "PLAY AGAIN")),Vector2(290,570),19,Color.WHITE)

func check(ok: bool, label: String):
 checks += 1
 if not ok:
  push_error("FAIL: "+label); get_tree().quit(1)
  assert(ok,label)

func run_tests():
 blocks.clear()
 var id = add_block(Vector2(300,300))
 paint(id,0); paint(id,0)
 check(blocks[0].hits.size()==2,"Repeated colors count")
 paint(id,0)
 check(restored==1 and blocks.is_empty(),"Three same colors restore")
 reset(); blocks.clear()
 var a=add_block(Vector2(300,300),[0,1]); add_block(Vector2(400,300),[0,1]); add_block(Vector2(500,300),[0,1]); var far=add_block(Vector2(650,300))
 paint(a,2)
 check(restored==3 and best_chain==3,"Three-block rainbow chain")
 check(blocks.size()==1 and blocks[0].id==far and blocks[0].hits.is_empty(),"Radius limits propagation")
 reset(); blocks.clear(); add_block(Vector2(300,400)); add_block(Vector2(300,250))
 check(find_hit(Vector2(300,850),Vector2(300,150))==blocks[0].id,"Nearest swept target")
 check(find_hit(Vector2(500,850),Vector2(500,150))==-1,"Miss path")
 check(launch_position(Vector2(-100,950))==Vector2(60,907),"Launch position clamps safely")
 check(launch(0,Vector2(300,300)),"Launcher fires")
 check(not launch(0,Vector2(300,300)),"Same-color cooldown")
 check(launch(1,Vector2(300,300)),"Independent cooldown")
 state="paused"; var y=blocks[0].p.y; simulate(1)
 check(blocks[0].p.y==y,"Pause freezes simulation")
 check(not launch(2,Vector2(300,300)),"Pause blocks firing")
 reset(); blocks.clear()
 for x in [200,300,400]: add_block(Vector2(x,719))
 simulate(.01)
 check(state=="lost" and lives==0,"Three misses end game")
 reset(); blocks.clear(); restored=goal()-1; id=add_block(Vector2(300,300),[0,0]); paint(id,0)
 check(state=="level_won" and restored==goal(),"Target completes garden")
 reset()
 check(lives==3 and restored==0 and shots.is_empty() and blocks.size()==3,"Replay resets state")
 press(LAUNCHERS[0]); release(LAUNCHERS[0])
 check(shots.is_empty(),"Tap cancels without shot")
 press(LAUNCHERS[1]); release(Vector2(350,788))
 check(shots.size()==1 and drag==-1,"Drag release launches and clears")
 check(shots[0].p==Vector2(350,788) and shots[0].d==Vector2.UP,"Release position fires vertically, not from launcher")
 reset(); press(LAUNCHERS[0]); release(Vector2(600,400))
 check(shots.is_empty() and cooldowns[0]==0,"Release outside bottom cancels without cooldown")
 press(LAUNCHERS[0]); release(Vector2(600,850))
 check(shots.size()==1 and shots[0].p.x==600,"Horizontal-only drag is valid")
 var start_speed = shots[0].speed
 simulate(.1)
 check(shots[0].speed>start_speed and shots[0].p.x==600,"Upward shot accelerates without lateral movement")
 for i in range(10):
  shots[0].p.y=850
  simulate(.1)
 check(shots[0].speed==max_shot_speed,"Speed capped at adjustable maximum")
 reset(); press(LAUNCHERS[0]); press(Vector2(630,60)); release(Vector2(400,800))
 check(state=="paused" and shots.is_empty(),"Pause during drag cancels")
 reset()
 var touch=InputEventScreenTouch.new(); touch.index=2; touch.position=LAUNCHERS[2]; touch.pressed=true; _input(touch)
 var move=InputEventScreenDrag.new(); move.index=2; move.position=Vector2(120,790); _input(move)
 touch.position=move.position; touch.pressed=false; _input(touch)
 check(shots.size()==1 and shots[0].p==Vector2(120,790) and finger==-1,"Touch drag releases from chosen location")
 reset(); blocks.clear(); id=add_block(Vector2(360,400)); launch(1,Vector2(360,400))
 for i in range(60): simulate(1.0/60)
 check(blocks[0].hits.size()==1 and shots.is_empty(),"Actual accelerated projectile paints once")
 reset(); blocks.clear(); id=add_block(Vector2(300,300),[],"hard")
 for i in range(4): paint(id,0)
 check(blocks.size()==1 and blocks[0].hits.size()==4,"Hard block survives four hits")
 paint(id,0)
 check(blocks.is_empty() and restored==1,"Hard block restores after five hits")
 reset(); blocks.clear(); id=add_block(Vector2(300,300),[0,0],"bloom"); var neighbor=add_block(Vector2(400,300))
 paint(id,0)
 check(blocks.size()==1 and blocks[0].id==neighbor and blocks[0].hits==[0],"Bloom spreads final color even without rainbow")
 reset(); garden_restored=6; restored=6; state="level_won"
 press(Vector2(360,560))
 check(level==1 and garden_restored==6 and restored==0 and lives==3,"Next area keeps garden and resets round")
 check(blocks[1].kind=="hard","Second area introduces hard blocks")
 level=2; start_level(); blocks.clear(); restored=goal()-1; id=add_block(Vector2(300,300),[0,0]); paint(id,0)
 check(state=="won","Third area completes campaign")
 reset(); garden_restored=10; level=1; restored=4; state="lost"; press(Vector2(360,560))
 check(level==1 and garden_restored==6 and restored==0,"Retry retains earlier-area garden only")
 reset(); var mouse=InputEventMouseButton.new(); mouse.button_index=MOUSE_BUTTON_LEFT; mouse.position=LAUNCHERS[0]; mouse.pressed=true; _input(mouse)
 mouse.position=Vector2(570,800); mouse.pressed=false; _input(mouse)
 check(shots.size()==1 and shots[0].p==Vector2(570,800),"Mouse drag fires from released position")
 reset(); press(LAUNCHERS[0]); _notification(NOTIFICATION_APPLICATION_FOCUS_OUT); release(Vector2(300,800))
 check(state=="paused" and drag==-1 and shots.is_empty(),"Focus loss cancels drag and pauses")
 audio.stop()
 audio.stream = null
 print("GAMEPLAY_TESTS_PASS ",checks)
 get_tree().quit()
