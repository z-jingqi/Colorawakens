shader_type spatial;
render_mode unshaded;
void fragment(){
 vec2 q=UV;
 vec3 col=mix(vec3(.018,.028,.065),vec3(.10,.15,.24),q.y);
 float halo=exp(-length((q-vec2(.5,.5))*vec2(2.,1.6))*3.);
 col+=vec3(.035,.09,.17)*halo;
 for(int i=0;i<12;i++){
  float f=float(i);
  vec2 c=vec2(.13+fract(sin(f*12.4)*437.1)*.74,.1+fract(sin(f*7.8)*491.3)*.8);
  float r=.007+.012*fract(sin(f*21.)*13.);
  float d=length(q-c);
  col+=vec3(.16,.26,.36)*exp(-pow(d/r,2.))*.35;
 }
 ALBEDO=col;
}
