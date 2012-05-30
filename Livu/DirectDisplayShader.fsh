varying highp vec2 textureCoordinate;

uniform sampler2D videoFrame;

void main()
{
	highp vec4 color = texture2D(videoFrame, textureCoordinate);
	//highp float x = color.x;
	//color.x = color.z;
	//color.z = color.x;
	gl_FragColor = color.bgra;
}
