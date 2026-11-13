shader_type spatial;
render_mode unshaded, cull_back;
uniform int lobes=1;
uniform vec3 centers[8];
uniform int color_offset=0;
varying vec3 local_p;
varying vec3 world_p;
void vertex(){local_p=VERTEX;world_p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
float smooth_union(float a,float b){
 float h=clamp(.5+.5*(b-a)/.30,0.,1.);
 return mix(b,a,h)-.30*h*(1.-h);
}
float field(vec3 p){
 float d=length(p-centers[0])-.78;
 for(int i=1;i<8;i++){
  if(i>=lobes)break;
  d=smooth_union(d,length(p-centers[i])-.78);
 }
 return d;
}
vec3 palette(int i){
 if(i%5==0)return vec3(.12,.58,1.);
 if(i%5==1)return vec3(1.,.22,.48);
 if(i%5==2)return vec3(1.,.67,.035);
 if(i%5==3)return vec3(.12,1.,.63);
 return vec3(.68,.30,1.);
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
 vec3 incident=normalize((inverse(VIEW_MATRIX*MODEL_MATRIX)*vec4(-VIEW,0.)).xyz);
 vec3 inside=refract(incident,n,1./1.46);
 // March within the same connected implicit surface to its rear boundary.
 float travel=.015;
 for(int i=0;i<48;i++){
  float d=field(local_p+inside*travel);
  if(d>-.001 && i>1)break;
  travel+=max(.005,-d*.85);
 }
 vec3 exit_p=local_p+inside*travel;
 vec3 exit_normal=-normal_at(exit_p);
 float cos_exit=dot(exit_normal,inside);
 float discriminant=1.-1.46*1.46*(1.-cos_exit*cos_exit);
 vec3 exit_ray=refract(inside,exit_normal,1.46);
 // Smooth artistic fallback near total internal reflection: avoid a hard direction jump.
 float exit_weight=smoothstep(.0,.24,discriminant);
 vec3 outgoing=normalize(mix(incident,exit_ray,exit_weight));
 vec3 exit_world=(MODEL_MATRIX*vec4(exit_p,1.)).xyz;
 outgoing=normalize((MODEL_MATRIX*vec4(outgoing,0.)).xyz);
 // Bounded virtual back-plane projection avoids singularities at grazing/backward exits.
 float t=(3.+exit_world.z)/max(-outgoing.z,.45);
 vec3 tint=vec3(0.);
 float weight_sum=0.;
 for(int i=0;i<8;i++){
  if(i>=lobes)break;
  float weight=exp(-distance(local_p,centers[i])*7.);
  tint+=palette(i+color_offset)*weight;
  weight_sum+=weight;
 }
 tint/=max(weight_sum,.00001);
 vec3 world_normal=normalize((MODEL_MATRIX*vec4(n,0.)).xyz);
 vec3 traced_background=backdrop((exit_world+outgoing*t).xy);
 vec3 stable_background=backdrop(world_p.xy-world_normal.xy*.65);
 // A stable lens approximation dominates at compound concave boundaries.
 // Keep only a small exit-ray contribution to suppress false caustic-looking patches.
 vec3 transmitted=mix(stable_background,traced_background,.06)*pow(tint,vec3(.43+.07*clamp(travel,0.,2.)));
 float facing=clamp(dot(n,-incident),0.,1.);
 transmitted+=tint*.16*pow(facing,.6);
 float fresnel=.035+.965*pow(1.-facing,5.);
 vec3 reflect_dir=normalize((MODEL_MATRIX*vec4(reflect(incident,n),0.)).xyz);
 vec3 env=mix(vec3(.035,.06,.08),vec3(.55,.62,.64),clamp(reflect_dir.y*.5+.5,0.,1.));
 env+=vec3(1.,.96,.86)*softbox(reflect_dir,vec3(-.45,1.7,.7),.53,.18)*5.;
 env+=vec3(.65,.84,1.)*softbox(reflect_dir,vec3(1.6,.4,-.8),.44,.13)*1.2;
 ALBEDO=(mix(transmitted,env,fresnel)+tint*.20*pow(1.-facing,2.))*1.15;
}
