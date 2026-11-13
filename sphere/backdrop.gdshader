shader_type spatial;
render_mode unshaded;
void fragment(){
 vec2 q=UV;
 vec3 c=mix(vec3(.035,.045,.075),vec3(.22,.26,.32),q.y);
 float light=exp(-dot((q-vec2(.40,.58))*vec2(3.,3.),(q-vec2(.40,.58))*vec2(3.,3.)));
 c+=vec3(.10,.12,.16)*light;
 c+=vec3(.06,.035,.018)*exp(-length((q-vec2(.1,.4))*4.));
 for(int i=0;i<8;i++){
  float k=float(i);
  vec2 pos=vec2(.15+fract(sin(k*17.+4.)*97.)*.70,.13+fract(sin(k*7.+5.)*43.)*.74);
  float d=length((q-pos)*vec2(.75,1.));
  float rad=.009+.006*fract(k*.721);
  c+=vec3(.20,.24,.30)*exp(-pow(d/rad,2.))*.30;
 }
 ALBEDO=c;
}
