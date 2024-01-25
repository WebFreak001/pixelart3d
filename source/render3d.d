module render3d;

import arsd.simpledisplay : OpenGlShader, glBufferDataSlice;
import bindbc.opengl;

struct Render3D
{
	uint VAO, VBO, EBO;
	OpenGlShader shader;

	void setupContext()
	{
		// now you can create the shaders, etc.

		shader = new OpenGlShader(
			OpenGlShader.Source(GL_VERTEX_SHADER, `
				#version 330 core
				layout (location = 0) in vec3 aPos;
				void main() {
					gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
				}
			`),
			OpenGlShader.Source(GL_FRAGMENT_SHADER, `
				#version 330 core
				out vec4 FragColor;
				uniform vec4 mycolor;
				void main() {
					FragColor = mycolor;
				}
			`),
		);
		// and do whatever other setup you want.
		float[] vertices = [
			1.0f, 1.0f, 0.0f, // top right
			1.0f, -1.0f, 0.0f, // bottom right
			-1.0f, -1.0f, 0.0f, // bottom left
			-1.0f, 1.0f, 0.0f // top left
		];
		uint[] indices = [ // note that we start from 0!
			0, 1, 3, // first Triangle
			1, 2,
			3 // second Triangle
		];
		glGenVertexArrays(1, &VAO);
		// bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
		glBindVertexArray(VAO);
		glGenBuffers(1, &VBO);
		glBindBuffer(GL_ARRAY_BUFFER, VBO);
		glBufferDataSlice(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, null);
		glEnableVertexAttribArray(0);
		glGenBuffers(1, &EBO);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
		glBufferDataSlice(GL_ELEMENT_ARRAY_BUFFER, indices, GL_STATIC_DRAW);
		glBindVertexArray(0);
	}

	void redraw(int width, int height)
	{
		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		glUseProgram(shader.shaderProgram);
		// the shader helper class has methods to set uniforms too
		shader.uniforms.mycolor.opAssign(1.0, 1.0, 0, 1.0);

		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
	}
}
