function glProgramUniformMatrix4x3fv( program, location, count, transpose, value )

% glProgramUniformMatrix4x3fv  Interface to OpenGL function glProgramUniformMatrix4x3fv
%
% usage:  glProgramUniformMatrix4x3fv( program, location, count, transpose, value )
%
% C function:  void glProgramUniformMatrix4x3fv(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat* value)

% 30-Aug-2012 -- created (generated automatically from header files)

if nargin~=5,
    error('invalid number of arguments');
end

moglcore( 'glProgramUniformMatrix4x3fv', program, location, count, transpose, single(value) );

return
