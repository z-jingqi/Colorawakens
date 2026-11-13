shader_type spatial;
render_mode unshaded, cull_back;
uniform vec3 tint=vec3(.24,.70,.96);
varying vec3 local_p;
varying vec3 world_p;
void vertex(){local_p=VERTEX;world_p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
vec3 backdrop(vec2 p){
 vec3 col=mix(vec3(.08,.13,.17),vec3(.35,.44,.46),clamp(.5+p.y*.12,0.,1.));
 float ribbon=exp(-pow((p.x-.35*sin(p.y*.75))/.30,2.));
 col+=vec3(.26,.30,.28)*ribbon;
 float other=exp(-pow((p.x+1.6+.1*p.y)/.12,2.));
 return col+vec3(.16,.18,.15)*other;
}
float softbox(vec3 d,vec3 axis,float rad,float edge){
 return 1.-smoothstep(rad-edge,rad+edge,acos(clamp(dot(d,normalize(axis)),-1.,1.)));
}
void fragment(){
 vec3 n=normalize(local_p);
 vec3 incident=vec3(0.,0.,-1.);
 vec3 inside=refract(incident,n,1./1.46);
 float travel=-2.*dot(local_p,inside);
 vec3 exit_p=local_p+inside*travel;
 vec3 outgoing=refract(inside,-normalize(exit_p),1.46);
 vec3 exit_world=world_p-local_p+exit_p;
 float t=(-3.-exit_world.z)/min(outgoing.z,-.001);
 vec3 transmitted=backdrop((exit_world+outgoing*t).xy);
 // Beer-Lambert absorption: clear at the edge, gentle body color.
 transmitted*=pow(clamp(tint,vec3(.001),vec3(1.)),vec3(max(travel,0.)*.22));
 float facing=clamp(n.z,0.,1.);
 float fresnel=.035+.965*pow(1.-facing,5.);
 vec3 reflect_dir=reflect(incident,n);
 vec3 env=mix(vec3(.035,.06,.08),vec3(.55,.62,.64),clamp(reflect_dir.y*.5+.5,0.,1.));
 env+=vec3(1.,.96,.86)*softbox(reflect_dir,vec3(-.8,1.3,1.),.33,.07)*6.;
 env+=vec3(.65,.84,1.)*softbox(reflect_dir,vec3(1.6,.4,-.8),.44,.13)*1.2;
 vec3 col=mix(transmitted,env,fresnel);
 ALBEDO=col*1.35;
}
