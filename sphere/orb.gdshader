shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float phase = 0.0;
uniform vec3 absorption = vec3(1.55, 0.36, 0.025);
uniform float ior = 1.46;
varying vec3 p;
void vertex(){ p=VERTEX; }
float panel(vec3 ray, vec3 axis, vec3 up, vec2 size, float softness){
 vec3 right=normalize(cross(up,axis));
 vec3 vup=normalize(cross(axis,right));
 float facing=dot(ray,axis);
 vec2 uv=vec2(dot(ray,right),dot(ray,vup))/max(facing,.001);
 vec2 d=abs(uv)-size;
 float box=length(max(d,vec2(0.)))+min(max(d.x,d.y),0.);
 return (1.-smoothstep(-softness,softness,box))*step(0.,facing);
}
vec3 studio(vec3 d){
 vec3 c=mix(vec3(.10,.16,.32),vec3(.75,.85,1.),smoothstep(-.7,.8,d.y));
 c+=vec3(.90,.94,1.)*panel(d,normalize(vec3(-1.1,1.4,.05)),vec3(0,1,0),vec2(.42,.48),.018)*18.0;
 c+=vec3(.56,.75,1.)*panel(d,normalize(vec3(1.3,.15,.4)),vec3(0,1,0),vec2(.065,.50),.025)*5.0;
 c+=vec3(1.,.66,.35)*panel(d,normalize(vec3(-1.2,-.5,-.5)),vec3(0,1,0),vec2(.12,.4),.05)*1.2;
 c+=vec3(.18,.60,.95)*exp(-pow((d.y+.50)*9.,2.))*.65;
 return c;
}
void fragment(){
 vec3 n=normalize(p);
 vec3 incident=vec3(0,0,-1);
 float face=max(n.z,0.);
 float f0=pow((ior-1.)/(ior+1.),2.);
 float fresnel=f0+(1.-f0)*pow(1.-face,5.);
 vec3 inside=refract(incident,n,1./ior);
 float distance_in=-2.*dot(p,inside);
 vec3 exitpoint=p+inside*distance_in;
 vec3 outdir=refract(inside,-normalize(exitpoint),ior);
 vec3 transmitted=studio(outdir);
 // One internal reflected path adds real curved secondary reflections.
 vec3 bounced=reflect(inside,normalize(exitpoint));
 float second_length=-2.*dot(exitpoint,bounced);
 vec3 second_point=exitpoint+bounced*second_length;
 vec3 second_ray=refract(bounced,-normalize(second_point),ior);
 float internal_f=f0+(1.-f0)*pow(1.-abs(dot(inside,normalize(exitpoint))),5.);
 transmitted+=studio(second_ray)*internal_f*exp(-absorption*second_length)*.35;
 // Back-wall pattern is refracted by both surfaces, rather than blurred on top.
 vec2 back=exitpoint.xy+outdir.xy*((-2.-exitpoint.z)/min(outdir.z,-.15));
 vec2 sample_uv=SCREEN_UV+(back-p.xy)*vec2(1./3.675,-1./4.9);
 transmitted=mix(transmitted,textureLod(screen_tex,clamp(sample_uv,vec2(.001),vec2(.999)),.5).rgb,.25);
 float ribbons=exp(-pow((back.y+.8+.12*sin(back.x*2.+phase*.20))*8.,2.));
 transmitted+=vec3(.12,.55,.9)*ribbons*.55;
 transmitted*=exp(-absorption*distance_in);
 // Clear shell catches sharp rectangular studio reflections.
 vec3 refl=studio(reflect(incident,n));
 vec3 col=transmitted*(1.-fresnel)+refl*fresnel;
 // Luminous pigment is strongest in the lower core, leaving a dark clear cap.
 float core=exp(-dot((n.xy-vec2(.08,-.38))*vec2(2.3,2.5),(n.xy-vec2(.08,-.38))*vec2(2.3,2.5)));
 col+=vec3(.005,.20,.52)*core;
 float ring=length((n.xy-vec2(.06,-.12))*vec2(1.,1.14));
 col+=vec3(.025,.16,.38)*exp(-pow((ring-.48)*14.,2.))*.12;

 // Focused light in the lower interior; its crisp crescent conveys thickness.
 float r=length(n.xy-vec2(.02,.12));
 float crescent=exp(-pow((r-.82)*47.,2.))*smoothstep(.05,.7,-n.y);
 float broad=exp(-pow((r-.78)*12.,2.))*smoothstep(.05,.7,-n.y);
 col+=vec3(.015,.42,.8)*broad*.22+vec3(.12,.9,1.)*crescent*.38;
 float rim=pow(1.-face,10.);
 col+=vec3(.30,.64,1.)*rim*.16;
 // Fine glint; avoid broad white emission that reads as plastic.
 col+=vec3(.9,.97,1.)*pow(max(dot(n,normalize(vec3(-.42,.58,.7))),0.),1000.)*1.3;
 ALBEDO=col;
}
