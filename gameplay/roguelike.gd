extends Node2D
# Short-run roguelite. The original gameplay and 3D studies remain independent.
const COLORS = [Color("ef6c7a"), Color("efbf51"), Color("58a9dc")]
const LAUNCHERS = [Vector2(210, 852), Vector2(360, 852), Vector2(510, 852)]
const LAUNCH_AREA = Rect2(45, 766, 630, 164)
@export var launch_speed = 180.0
@export var shot_acceleration = 850.0
@export var max_shot_speed = 1000.0
const DANGER = 750.0
const RADIUS = 130.0
const LEVELS = [
 {"name":"FIRST SPARK", "target":12, "fall":6.0},
 {"name":"COLOR CASCADE", "target":18, "fall":7.0},
 {"name":"BLOOM FACTORY", "target":24, "fall":8.0},
 {"name":"PRISM STORM", "target":30, "fall":9.0},
 {"name":"FULL BLOOM", "target":36, "fall":10.0}
]
const UPGRADES = [
 {"id":"split","name":"SPLIT SEED","desc":"First impact fires 2 extra seeds.","detail":"Each level adds two seeds."},
 {"id":"bounce","name":"RICOCHET","desc":"Shots seek another block on impact.","detail":"Each level adds one bounce."},
 {"id":"spread","name":"COLOR CONTAGION","desc":"Every restored block spreads paint.","detail":"More levels add more color hits."},
 {"id":"radius","name":"BIGGER BLOOMS","desc":"Explosions reach 35 px farther.","detail":"Stacks with color contagion."},
 {"id":"rapid","name":"QUICK HANDS","desc":"Faster shots and shorter cooldown.","detail":"Each level makes firing quicker."},
 {"id":"rainbow","name":"RAINBOW HEART","desc":"Every 4th shot paints all 3 colors.","detail":"Higher levels charge it faster."}
]
var upgrades = {"split":0,"bounce":0,"spread":0,"radius":0,"rapid":0,"rainbow":0}
var offers: Array = []
var rng = RandomNumberGenerator.new()
var pending_hits: Array = []
var chain_count = 0
var chain_timer = 0.0
var fire_count = 0
var choice_time = 0.0
var screen_pulse = 0.0
var demo_end = 0.0
func fire_cooldown() -> float: return maxf(.12,.35-pow(float(upgrades.rapid),.8)*.07)
func blast_radius() -> float: return RADIUS + upgrades.radius*35
func card_rect(i: int) -> Rect2: return Rect2(65,310+i*150,590,132)
func offer_upgrades():
 state="upgrade"; drag=-1; finger=-1; shots.clear(); pending_hits.clear(); choice_time=0
 var ids = range(UPGRADES.size())
 offers.clear()
 for i in range(3):
  var at = rng.randi_range(0,ids.size()-1)
  offers.append(ids[at]); ids.remove_at(at)
func choose_upgrade(i: int):
 if state!="upgrade" or i<0 or i>=offers.size(): return
 var u = UPGRADES[offers[i]]
 upgrades[u.id]+=1
 tone(1100)
 print("UPGRADE wave=",level+1," chosen=",u.id)
 start_level()
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
 if "--test-rogue" in OS.get_cmdline_user_args():
  run_rogue_tests()

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
 rng.randomize()
 if "--demo" in OS.get_cmdline_user_args(): rng.seed=32
 level=0; garden_restored=0; score=0; best_chain=0; fire_count=0
 for key in upgrades: upgrades[key]=0
 blocks.clear(); shots.clear(); effects.clear(); pending_hits.clear()
 restored=0; lives=5; chain_count=0; chain_timer=0
 offer_upgrades()

func start_level():
 blocks.clear(); shots.clear(); effects.clear(); pending_hits.clear()
 cooldowns=[0.0,0.0,0.0]
 restored=0; lives=5; state="playing"; drag=-1; finger=-1
 elapsed=0; next_id=0; level_wait=0; chain_count=0; chain_timer=0
 notice="Drag a ball. Release. Watch the colors spread."; notice_time=3
 var rows = 2+level
 for row in range(rows):
  for col in range(6):
   var kind="normal"
   if level>0 and (col+row*2)%7==2: kind="bloom"
   if level>1 and (col+row*3)%11==4: kind="hard"
   # Pre-painted seeds are visible and make the dense board chain-ready.
   var hits: Array = []
   if (col+row)%3==0: hits=[0,1]
   elif (col+row)%3==1: hits=[1]
   add_block(Vector2(110+col*100,220+row*82),hits,kind)
 queue_redraw()

func launch_position(pos: Vector2) -> Vector2:
 return Vector2(clampf(pos.x, 60, 660), clampf(pos.y, 785, 907))

func launch(index: int, origin: Vector2) -> bool:
 if index < 0 or index >= 3 or state != "playing" or cooldowns[index] > 0: return false
 shots.append({"p":launch_position(origin),"d":Vector2.UP,"speed":launch_speed,"color":index,"trail":[],"split":true,"bounces":upgrades.bounce,"visited":[],"rainbow":false})
 fire_count+=1
 shots[-1].rainbow = upgrades.rainbow>0 and fire_count % maxi(2,5-upgrades.rainbow)==0
 tone(280+index*70)
 cooldowns[index] = fire_cooldown()
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

func queue_hit(id: int, color: int, delay: float = 0.0):
 if pending_hits.size()<2048:
  pending_hits.append({"id":id,"color":color,"delay":delay})

func paint(id: int, color_index: int):
 var at=-1
 for i in range(blocks.size()):
  if blocks[i].id==id: at=i; break
 if at<0: return
 var block=blocks[at]
 block.hits.append(color_index); block.pulse=.3
 score+=10
 effects.append({"p":block.p,"age":0.0,"life":.22,"color":COLORS[color_index],"rainbow":false,"size":40.0})
 tone(480+color_index*120)
 if block.hits.size()<block.needed: return
 var rainbow=block.hits.has(0) and block.hits.has(1) and block.hits.has(2)
 blocks.remove_at(at)
 restored+=1; garden_restored+=1
 chain_count+=1; chain_timer=1.1; best_chain=maxi(best_chain,chain_count)
 score+=100+chain_count*25
 screen_pulse=minf(.12,screen_pulse+.035)
 effects.append({"p":block.p,"age":0.0,"life":.65,"color":COLORS[color_index],"rainbow":rainbow,"size":blast_radius() if rainbow or upgrades.spread>0 else 70.0})
 tone(600+min(chain_count,14)*65)
 notice="CHAIN x%d   +%d" % [chain_count,100+chain_count*25]; notice_time=2
 if rainbow or block.kind=="bloom" or upgrades.spread>0:
  for other in blocks:
   if other.p.distance_to(block.p)<=blast_radius():
    var hits = maxi(1,upgrades.spread)
    for n in range(hits): queue_hit(other.id,(color_index+n)%3,.085+n*.035)

func impact(shot: Dictionary, id: int):
 var pos: Vector2 = shot.p
 for b in blocks:
  if b.id==id: pos=b.p; break
 if shot.rainbow:
  for c in range(3): paint(id,c)
 else: paint(id,shot.color)
 var visited: Array = shot.visited.duplicate()
 visited.append(id)
 # Secondary seeds cannot split again; bounce budget and visited list bound recursion.
 var targets=blocks.duplicate()
 targets.sort_custom(func(a,b): return a.p.distance_squared_to(pos)<b.p.distance_squared_to(pos))
 var spawned=0
 for b in targets:
  if visited.has(b.id): continue
  if shot.split and spawned<upgrades.split*2:
   shots.append({"p":pos,"d":(b.p-pos).normalized(),"speed":430.0,"color":(shot.color+spawned+1)%3,"trail":[],"split":false,"bounces":upgrades.bounce,"visited":visited.duplicate(),"rainbow":false})
   spawned+=1
  if spawned>=upgrades.split*2: break
 if shot.bounces>0:
  for b in targets:
   if visited.has(b.id): continue
   shots.append({"p":pos,"d":(b.p-pos).normalized(),"speed":500.0,"color":shot.color,"trail":[],"split":false,"bounces":shot.bounces-1,"visited":visited,"rainbow":shot.rainbow})
   break
 # Hard runtime budget prevents pathological upgrades from flooding the frame.
 if shots.size()>180: shots.resize(180)

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
  shot.speed = minf(max_shot_speed,shot.speed+shot_acceleration*(1+upgrades.rapid*.2)*dt)
  shot.p += shot.d*shot.speed*dt
  shot.trail.append(old)
  if shot.trail.size()>8: shot.trail.pop_front()
  var hit = -1
  var nearest=2.0
  for b in blocks:
   if shot.visited.has(b.id): continue
   var t=segment_hit(old,shot.p,b.p)
   if t>=0 and t<nearest: nearest=t; hit=b.id
  if hit >= 0:
   shots.remove_at(i); impact(shot,hit)
   if state != "playing": return
  elif shot.p.y < 130 or shot.p.x < 35 or shot.p.x > 685:
   shots.remove_at(i)
 for i in range(pending_hits.size()-1,-1,-1):
  pending_hits[i].delay-=dt
  if pending_hits[i].delay<=0:
   var e=pending_hits[i]; pending_hits.remove_at(i); paint(e.id,e.color)
 chain_timer=maxf(0,chain_timer-dt)
 if chain_timer==0: chain_count=0
 if blocks.is_empty():
  state="won" if level==LEVELS.size()-1 else "wave_won"
  drag=-1; finger=-1; shots.clear(); pending_hits.clear(); level_wait=0

func _process(dt):
 screen_pulse=maxf(0,screen_pulse-dt)
 if state=="wave_won":
  level_wait+=dt
  if level_wait>1.6: level+=1; offer_upgrades()
 if demo:
  demo_time+=dt
  if demo_time>180: get_tree().quit(); return
  if state=="upgrade":
   choice_time+=dt
   if choice_time>2.2:
    var preferred=["split","spread","bounce","spread","radius"][level]
    var chosen=0
    for i in range(offers.size()):
     if UPGRADES[offers[i]].id==preferred: chosen=i
    choose_upgrade(chosen)
  if state in ["won","lost"]:
   demo_end+=dt
   if demo_end>3:
    print("DEMO_END state=",state," wave=",level+1," best_chain=",best_chain," restored=",garden_restored)
    get_tree().quit(); return
  if drag>=0:
   demo_drag_time+=dt
   pointer=LAUNCHERS[drag].lerp(demo_drag_target,clampf(demo_drag_time/.18,0,1))
   if demo_drag_time>=.25: release(pointer)
  if state=="playing" and drag<0 and demo_time>demo_next and not blocks.is_empty():
   var target=blocks[0]
   for b in blocks:
    if b.p.y>target.p.y: target=b
   var c=demo_color%3
   for missing in range(3):
    if not target.hits.has(missing): c=missing; break
   if cooldowns[c]<=0:
    press(LAUNCHERS[c]); demo_drag_target=Vector2(target.p.x,790); demo_drag_time=0
    demo_color+=1; demo_next=demo_time+.38
 simulate(dt)
 if state != "paused":
  notice_time = maxf(0,notice_time-dt)
  for i in range(effects.size()-1,-1,-1):
   effects[i].age += dt
   if effects[i].age >= effects[i].life: effects.remove_at(i)
 queue_redraw()

func press(pos: Vector2):
 if state=="upgrade":
  for i in range(offers.size()):
   if card_rect(i).has_point(pos): choose_upgrade(i); return
  return
 if state=="wave_won": return
 if Rect2(603,37,70,48).has_point(pos):
  if state == "playing": state = "paused"
  elif state == "paused": state = "playing"
  drag = -1; return
 if state in ["won","lost"]:
  if Rect2(225,530,270,64).has_point(pos):
   reset()
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
 var progress = clampf(float(garden_restored)/120,0,1)
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
 text_at("WAVE %02d  /  %s" % [level+1,LEVELS[level].name],Vector2(52,86),13,Color("718489"))
 rounded(Rect2(52,104,410,8),Color("dce2e2"),4)
 if progress>0: rounded(Rect2(52,104,410*progress,8),Color("69bfa3"),4)
 text_at("%d / %d" % [restored,goal()],Vector2(480,113),17)
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
  elif cooldowns[i] > 0: draw_arc(p,23,-PI/2,-PI/2+TAU*(1-cooldowns[i]/fire_cooldown()),32,COLORS[i],3)
  text_at(["RED","YELLOW","BLUE"][i],p+Vector2(-21,49),12)
 if drag>=0:
  var p = launch_position(pointer)
  draw_circle(p,23,COLORS[drag])
  draw_circle(p+Vector2(-6,-7),6,Color(1,1,1,.45))
  if not LAUNCH_AREA.has_point(pointer): text_at("Release outside the bottom to cancel",Vector2(190,740),16)
 text_at("MOVE BALL • RELEASE TO FIRE UP",Vector2(230,950),12,Color("6c8580"))
 if demo: text_at("ROGUELITE DEMO",Vector2(263,190),13,Color("718489"))
 var ability_labels=[]
 for u in UPGRADES:
  if upgrades[u.id]>0: ability_labels.append(u.name+" "+str(upgrades[u.id]))
 text_at("  /  ".join(ability_labels.slice(0,3)),Vector2(52,718),13,Color("335c69"))
 text_at("  /  ".join(ability_labels.slice(3)),Vector2(52,737),13,Color("335c69"))
 if chain_count>1 and chain_timer>0:
  rounded(Rect2(255,192,210,50),Color(.12,.26,.31,.85),18)
  text_at("CHAIN  x%d" % chain_count,Vector2(280,227),30,Color("fff0b3"))
 if screen_pulse>0: draw_rect(Rect2(0,0,720,750),Color(1,1,1,screen_pulse))
 if state=="upgrade":
  draw_rect(Rect2(0,0,720,960),Color(.08,.17,.22,.88))
  text_at("GROW YOUR COMBO",Vector2(125,215),36,Color.WHITE)
  text_at("Choose one. It lasts for this run.",Vector2(175,255),21,Color("b6d6d9"))
  for i in range(offers.size()):
   var u=UPGRADES[offers[i]]
   var r=card_rect(i)
   rounded(r,Color("eef7f0"),22)
   draw_circle(r.position+Vector2(42,41),19,COLORS[i])
   text_at(str(i+1),r.position+Vector2(36,48),20,Color.WHITE)
   text_at(u.name+"  Lv."+str(upgrades[u.id]+1),r.position+Vector2(78,43),24)
   text_at(u.desc,r.position+Vector2(25,81),20)
   text_at(u.detail,r.position+Vector2(25,110),16,Color("6c8580"))
  text_at("WAVE %d / 5   •   New run, new combinations" % (level+1),Vector2(125,824),18,Color.WHITE)
 elif state != "playing":
  draw_rect(Rect2(0,0,720,960),Color(.12,.23,.25,.38))
  rounded(Rect2(145,335,430,300),Color("f7fbf7"),30)
  var title = "Garden awakened" if state == "won" else ("Wave cleared!" if state=="wave_won" else ("Try again" if state == "lost" else "Take a breath"))
  text_at(title,Vector2(196,407),32)
  text_at("Score %d   •   Best chain %d" % [score,best_chain],Vector2(205,452),19)
  text_at("%d blocks restored" % restored,Vector2(251,488),17)
  rounded(Rect2(225,530,270,64),Color("6aae98"),18)
  text_at("UPGRADE NEXT" if state=="wave_won" else ("CONTINUE" if state == "paused" else ("NEW RUN" if state=="lost" else "PLAY AGAIN")),Vector2(290,570),19,Color.WHITE)

func check(ok: bool, label: String):
 checks += 1
 if not ok:
  push_error("FAIL: "+label); get_tree().quit(1)
  assert(ok,label)

func test_board():
 reset(); start_level(); blocks.clear(); effects.clear(); pending_hits.clear()

func run_rogue_tests():
 check(state=="upgrade" and offers.size()==3,"Run starts with three choices")
 check(offers[0]!=offers[1] and offers[1]!=offers[2] and offers[0]!=offers[2],"Offers unique")
 var selected=UPGRADES[offers[0]].id
 choose_upgrade(0)
 check(upgrades[selected]==1 and state=="playing","Choice grants actual ability")
 check(blocks.size()==12,"First wave has 12 blocks")
 var before=upgrades.duplicate(); choose_upgrade(0)
 check(upgrades==before,"Double choice cannot grant twice")
 test_board()
 var id=add_block(Vector2(300,300))
 paint(id,0); paint(id,0); paint(id,0)
 check(restored==1 and blocks.is_empty(),"Repeated colors restore")
 test_board(); id=add_block(Vector2(300,300),[0,1]); add_block(Vector2(400,300),[0,1]); add_block(Vector2(500,300),[0,1])
 paint(id,2)
 check(restored==1 and pending_hits.size()>0,"Chain is delayed rather than instant")
 for i in range(30): simulate(.016)
 check(restored==3 and best_chain==3,"Delayed rainbow chain completes all three")
 test_board(); upgrades.spread=1
 id=add_block(Vector2(300,300),[0,0]); add_block(Vector2(400,300))
 paint(id,0); simulate(.1)
 check(blocks[0].hits==[0],"Contagion spreads even monochrome completion")
 test_board(); upgrades.spread=2
 id=add_block(Vector2(300,300),[0,0]); add_block(Vector2(400,300))
 paint(id,0); simulate(.14)
 check(blocks[0].hits.size()==2,"Contagion level stacks")
 test_board(); upgrades.radius=2
 check(blast_radius()==200,"Blast radius stacks")
 test_board(); upgrades.split=1; upgrades.bounce=1
 id=add_block(Vector2(300,300)); add_block(Vector2(400,300)); add_block(Vector2(500,300)); add_block(Vector2(600,300))
 launch(0,Vector2(300,800)); var shot=shots.pop_back(); impact(shot,id)
 check(shots.size()==3,"Split and ricochet interact")
 check(not shots[0].split and shots[0].bounces==1,"Split child gets bounce but cannot split recursively")
 check(shots[2].bounces==0,"Ricochet consumes bounce budget")
 check(shots[0].visited.has(id),"Secondary cannot re-hit origin")
 test_board(); upgrades.rainbow=1
 for i in range(4): cooldowns[0]=0; launch(0,Vector2(300,800))
 check(shots[-1].rainbow and not shots[0].rainbow,"Fourth launch becomes rainbow")
 id=add_block(Vector2(300,300)); impact(shots[-1],id)
 check(restored==1,"Rainbow shot paints three colors")
 test_board(); add_block(Vector2(100,300)); upgrades.rapid=2
 check(fire_cooldown()<.35,"Quick hands reduces cooldown")
 press(LAUNCHERS[0]); release(Vector2(600,850))
 check(shots.size()==1 and shots[0].p==Vector2(600,850) and shots[0].d==Vector2.UP,"Drag release launches vertically at chosen position")
 simulate(.1)
 check(shots[0].speed>launch_speed and shots[0].p.x==600,"Shot accelerates without horizontal drift")
 test_board(); press(LAUNCHERS[0]); release(Vector2(600,400))
 check(shots.is_empty() and cooldowns[0]==0,"Outside release cancels")
 test_board(); press(LAUNCHERS[0]); _notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(state=="paused" and drag==-1,"Focus loss pauses and cancels drag")
 test_board(); id=add_block(Vector2(300,300)); state="paused"; simulate(1)
 check(blocks[0].p.y==300 and not launch(0,Vector2(300,800)),"Pause freezes and blocks launches")
 test_board(); var touch=InputEventScreenTouch.new(); touch.index=2; touch.position=LAUNCHERS[2]; touch.pressed=true; _input(touch)
 touch.position=Vector2(120,790); touch.pressed=false; _input(touch)
 check(shots.size()==1 and finger==-1 and shots[0].p.x==120,"Touch launch route")
 test_board(); upgrades.split=2; garden_restored=12; level=1; start_level()
 check(upgrades.split==2 and garden_restored==12 and blocks.size()==18,"Upgrades and garden carry between waves")
 check(lives==5,"New wave replenishes lives")
 test_board(); id=add_block(Vector2(300,300),[0,0,0,0],"hard"); paint(id,1)
 check(restored==1,"Hard block completes in five hits")
 test_board(); id=add_block(Vector2(300,300),[0,0],"bloom"); add_block(Vector2(400,300)); paint(id,0); simulate(.1)
 check(blocks[0].hits.size()==1,"Bloom block spreads without upgrade")
 test_board(); simulate(.01)
 check(state=="wave_won","Empty board completes wave")
 test_board(); level=4; simulate(.01)
 check(state=="won","Final wave wins run")
 test_board()
 for i in range(5): add_block(Vector2(100+i*100,719))
 simulate(.01)
 check(state=="lost" and lives==0,"Five misses end run")
 reset()
 check(upgrades.split==0 and upgrades.spread==0 and garden_restored==0 and state=="upgrade","Fresh run clears temporary power and progress")
 var outcomes={}
 for n in range(20): offer_upgrades(); outcomes[str(offers)]=true
 check(outcomes.size()>1,"Choices vary across rolls")
 audio.stop(); audio.stream=null
 print("ROGUE_TESTS_PASS ",checks)
 get_tree().quit()
