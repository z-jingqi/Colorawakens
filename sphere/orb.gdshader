shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float phase = 0.0;
uniform vec3 tint : source_color = vec3(0.018,0.32,0.95);
varying vec3 p;
void vertex(){p=VERTEX;}
float cloud(vec3 q) {
 return sin(q.x*3.1+sin(q.y*2.7))*sin(q.y*3.4+sin(q.z*3.2))*sin(q.z*2.8+sin(q.x*2.));
}
void fragment(){
 vec3 n=normalize(NORMAL);
 vec3 v=normalize(VIEW);
 float facing=clamp(dot(n,v),0.,1.);
 float edge=pow(1.-facing,2.3);
 vec2 warp=n.xy*(0.025+facing*0.025);
 vec3 bg=textureLod(screen_tex,SCREEN_UV-warp,1.3).rgb;
 vec3 q=p*2.0+vec3(sin(phase*.4)*.18,phase*.12,0.);
 float mist=cloud(q)*.5+.5;
 float inner=pow(max(0.,1.-length(p.xy-vec2(.10,-.32))*.64),3.);
 float caustic=exp(-pow((length(p.xy-vec2(-.04,.18))-.78)*13.,2.))*smoothstep(.05,.9,-p.y);
 vec3 col=mix(bg,tint,.32+.32*mist);
 col+=tint*(.13+.28*mist)*facing;
 col+=vec3(.02,.58,1.)*inner*.38;
 col+=vec3(.10,.7,1.)*caustic*.65;
 // Broad studio softbox reflection and small sharp glint.
 float box=exp(-pow((n.x+.38)*7.,2.)-pow((n.y-.55)*12.,2.));
 float glint=pow(max(dot(n,normalize(vec3(-.43,.65,.64))),0.),160.);
 float side=pow(max(dot(n,normalize(vec3(.85,.18,.32))),0.),60.);
 col+=vec3(.75,.91,1.)*box*.7+vec3(.9,.98,1.)*glint*2.2;
 col+=vec3(.23,.48,1.)*side*.35;
 col=mix(col,vec3(.21,.64,1.),edge*.35);
 col+=vec3(.19,.48,1.)*pow(1.-facing,8.)*.24;
 ALBEDO=col;
}
