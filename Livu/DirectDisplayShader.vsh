uniform mat4    uMvp;

attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 textureCoordinate;

void main()
{
	//gl_Position = position;
	
	vec4 tposition = vec4(position.xyz, 1.);
	gl_Position = uMvp * tposition;
	
	textureCoordinate = inputTextureCoordinate.xy;
}
