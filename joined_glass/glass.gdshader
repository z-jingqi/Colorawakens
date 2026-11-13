shader_type spatial;
render_mode unshaded, cull_back;
uniform int lobes=1;
uniform sampler2D memory_tex: source_color, filter_linear_mipmap;
varying vec3 local_p;
varying vec3 world_p;
void vertex(){local_p=VERTEX;world_p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
float smooth_union(float a,float b){
 float h=clamp(.5+.5*(b-a)/.30,0.,1.);
 return mix(b,a,h)-.30*h*(1.-h);
}
float field(vec3 p){
 if(lobes==1)return length(p)-.78;
 float y=lobes==3 ? -.42 : 0.;
 float d=smooth_union(length(p-vec3(-.70,y,0.))-.78,length(p-vec3(.70,y,0.))-.78);
 if(lobes==3)d=smooth_union(d,length(p-vec3(0.,.80,0.))-.78);
 return d;
}
vec3 normal_at(vec3 p){
 vec2 e=vec2(.002,0.);
 return normalize(vec3(field(p+e.xyy)-field(p-e.xyy),field(p+e.yxy)-field(p-e.yxy),field(p+e.yyx)-field(p-e.yyx)));
}
vec3 backdrop(vec2 p){
 vec3 col=mix(vec3(.40,.49,.58),vec3(.78,.84,.88),clamp(.5+p.y*.12,0.,1.));
 col+=vec3(.18,.18,.16)*exp(-pow((p.x-.35*sin(p.y*.75))/.30,2.));
 return col+vec3(.08,.09,.09)*exp(-pow((p.x+1.6+.1*p.y)/.12,2.));
}
float softbox(vec3 d,vec3 axis,float rad,float edge){
 return 1.-smoothstep(rad-edge,rad+edge,acos(clamp(dot(d,normalize(axis)),-1.,1.)));
}
void fragment(){
 vec3 n=normal_at(local_p);
 vec3 incident=vec3(0.,0.,-1.);
 vec3 inside=refract(incident,n,1./1.46);
 // March within the same connected implicit surface to its rear boundary.
 float travel=.015;
 for(int i=0;i<48;i++){
  float d=field(local_p+inside*travel);
  if(d>-.001 && i>1)break;
  travel+=max(.005,-d*.85);
 }
 vec3 exit_p=local_p+inside*travel;
 vec3 outgoing=refract(inside,-normal_at(exit_p),1.46);
 if(length(outgoing)<.1)outgoing=inside;
 vec3 exit_world=world_p-local_p+exit_p;
 float t=(-3.-exit_world.z)/min(outgoing.z,-.001);
 vec3 tint=vec3(.12,.58,1.);
 if(lobes>=2)tint=mix(tint,vec3(1.,.22,.48),smoothstep(-.4,.4,local_p.x));
 if(lobes==3)tint=mix(tint,vec3(1.,.67,.035),smoothstep(.05,.65,local_p.y));
 vec3 transmitted=backdrop((exit_world+outgoing*t).xy)*pow(tint,vec3(travel*.38));
 float facing=clamp(n.z,0.,1.);
 vec3 center=vec3(0.);
 if(lobes>=2){
  float cy=lobes==3 ? -.42 : 0.;
  center=local_p.x<0. ? vec3(-.70,cy,0.) : vec3(.70,cy,0.);
  if(lobes==3 && distance(local_p,vec3(0.,.80,0.))<distance(local_p,center))center=vec3(0.,.80,0.);
 }
 vec2 inner=(local_p-center).xy;
 vec2 curved=inner*(.78+.45*dot(inner,inner));
 vec2 memory_uv=vec2(.5+curved.x*.65,.5-curved.y*.65);
 memory_uv+=vec2(center.x*.075,center.y*.045);
 vec3 memory=textureLod(memory_tex,clamp(memory_uv,vec2(.01),vec2(.99)),1.2).rgb;
 // An authored interior memory layer, not a physically traced scene.
 memory=mix(memory,vec3(dot(memory,vec3(.2126,.7152,.0722))),.18);
 memory*=mix(vec3(1.),tint,.40);
 float mask=1.-smoothstep(.42,.73,length(inner));
 transmitted=mix(transmitted,memory*1.30,mask*.53);
 transmitted+=tint*.12*pow(facing,.6);
 float fresnel=.035+.965*pow(1.-facing,5.);
 vec3 reflect_dir=reflect(incident,n);
 vec3 env=mix(vec3(.035,.06,.08),vec3(.55,.62,.64),clamp(reflect_dir.y*.5+.5,0.,1.));
 env+=vec3(1.,.96,.86)*softbox(reflect_dir,vec3(-.45,1.7,.7),.53,.18)*5.;
 env+=vec3(.65,.84,1.)*softbox(reflect_dir,vec3(1.6,.4,-.8),.44,.13)*1.2;
 ALBEDO=(mix(transmitted,env,fresnel)+tint*.20*pow(1.-facing,2.))*1.15;
}
