function glProgramUniformMatrix4x3dv( program, location, count, transpose, value )

% glProgramUniformMatrix4x3dv  Interface to OpenGL function glProgramUniformMatrix4x3dv
%
% usage:  glProgramUniformMatrix4x3dv( program, location, count, transpose, value )
%
% C function:  void glProgramUniformMatrix4x3dv(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble* value)

% 30-Aug-2012 -- created (generated automatically from header files)

if nargin~=5,
    error('invalid number of arguments');
end

moglcore( 'glProgramUniformMatrix4x3dv', program, location, count, transpose, double(value) );

return
