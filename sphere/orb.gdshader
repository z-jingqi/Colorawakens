shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float phase = 0.0;
uniform vec3 absorption = vec3(1.55, 0.36, 0.025);
uniform float ior = 1.46;
// Disk-area studio lights, softened by the surface roughness footprint.
float disk_light(vec3 ray, vec3 axis, float radius, float blur){
 float angle=acos(clamp(dot(ray,normalize(axis)),-1.,1.));
 return 1.-smoothstep(radius-blur,radius+blur,angle);
}
vec3 studio(vec3 d){
 vec3 c=mix(vec3(.12,.17,.25),vec3(.56,.64,.75),smoothstep(-.8,.9,d.y));
 c+=vec3(.85,.93,1.)*disk_light(d,vec3(-.85,1.2,.7),.32,.065)*24.;
 c+=vec3(.58,.79,1.)*disk_light(d,vec3(1.5,.6,-.35),.24,.07)*1.5;
 c+=vec3(1.,.76,.5)*disk_light(d,vec3(-1.,.6,-1.5),.35,.10)*1.4;
 return c;
}
void fragment(){
 vec3 n=normalize(NORMAL);
 vec3 surface=n*1.08;
 vec3 incident=vec3(0,0,-1);
 float face=max(n.z,0.);
 float f0=pow((ior-1.)/(ior+1.),2.);
 float fresnel=f0+(1.-f0)*pow(1.-face,5.);
 vec3 inside=refract(incident,n,1./ior);
 float distance_in=-2.*dot(surface,inside);
 vec3 exitpoint=surface+inside*distance_in;
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
 vec2 sample_uv=SCREEN_UV+(back-surface.xy)*vec2(1./3.675,-1./4.9);
 transmitted=mix(transmitted,textureLod(screen_tex,clamp(sample_uv,vec2(.001),vec2(.999)),.5).rgb,.25);
 transmitted*=exp(-absorption*distance_in);
 // The shell reflects the same environment used by transmitted rays.
 vec3 refl=studio(reflect(incident,n));
 vec3 col=transmitted*(1.-fresnel)+refl*fresnel;
 // Gentle internal body color only; no painted rings or independent white glint.
 float core=exp(-dot((n.xy-vec2(.08,-.38))*vec2(2.3,2.5),(n.xy-vec2(.08,-.38))*vec2(2.3,2.5)));
 col+=vec3(.002,.06,.15)*core;
 // A soft highlight shoulder avoids flat clipped-white patches in Compatibility output.
 ALBEDO=col/(vec3(1.)+col*.30);
}
