shader_type spatial;
render_mode unshaded;
void fragment(){
 vec2 q=UV;
 vec3 col=mix(vec3(.025,.045,.07),vec3(.18,.25,.28),q.y);
 col+=vec3(.08,.11,.11)*exp(-dot((q-vec2(.5,.5))*3.,(q-vec2(.5,.5))*3.));
 // Quiet softly lit background ribbons provide cues to visible transmission.
 float ribbon=exp(-pow((q.x-.50-.12*sin(q.y*5.))*38.,2.));
 col+=vec3(.16,.22,.24)*ribbon*.45;
 ALBEDO=col;
}
