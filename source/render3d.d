module render3d;

import arsd.simpledisplay : OpenGlShader, glBufferDataSlice;
import bindbc.opengl;
import inmath.linalg;

struct Render3D
{
	uint VAO, VBO, EBO;
	OpenGlShader shader;
	mat4 projection;
	mat4 view;

	void setupContext()
	{
		// now you can create the shaders, etc.

		shader = new OpenGlShader(
			OpenGlShader.Source(GL_VERTEX_SHADER, `
				#version 330 core
				layout (location = 0) in vec3 aPos;

				uniform mat4 mvp;

				void main() {
					gl_Position = mvp * vec4(aPos.x, aPos.y, aPos.z, 1.0);
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
			1.0f, 1.0f, 1.0f, // top right back
			1.0f, -1.0f, 1.0f, // bottom right back
			-1.0f, -1.0f, 1.0f, // bottom left back
			-1.0f, 1.0f, 1.0f, // top left back
			1.0f, 1.0f, -1.0f, // top right front
			1.0f, -1.0f, -1.0f, // bottom right front
			-1.0f, -1.0f, -1.0f, // bottom left front
			-1.0f, 1.0f, -1.0f, // top left front
		];
		uint[] indices = [ // note that we start from 0!
			0, 1, 3, // first Triangle back
			1, 2, 3, // second Triangle back
			4, 5, 7, // first Triangle front
			4, 5, 6, // second Triangle front
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
		projection = mat4.perspective(width, height, 30.0, 0.01, 100.0);
		view = mat4.lookAt(vec3(0, 4.0, -10.0), vec3.zero, vec3(0, 1, 0));

		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		glUseProgram(shader.shaderProgram);
		// the shader helper class has methods to set uniforms too
		auto mvp = projection * view * mat4.identity.rotateY(3.1415926 * 0.25);
		glUniformMatrix4fv(shader.uniforms.mvp.id, 1, GL_TRUE, mvp.ptr);
		shader.uniforms.mycolor.opAssign(1.0, 1.0, 0, 1.0);

		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 12, GL_UNSIGNED_INT, null);
	}
}
