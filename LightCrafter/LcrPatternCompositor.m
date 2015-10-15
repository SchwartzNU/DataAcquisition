% A compositor that arranges a frame by packing a sequence of patterns. 

classdef LcrPatternCompositor < Compositor
    
    properties
        patternRenderer
        vao
        texture
        framebuffer
        renderer
    end
    
    methods
        
        function bindPatternRenderer(obj, renderer)
            obj.patternRenderer = renderer;
        end
        
        function init(obj, canvas)
            init@Compositor(obj, canvas);
            
            vertexData = [ 0  1  0  1,  0  1,  0  1 ...
                           0  0  0  1,  0  0,  0  0 ...
                           1  1  0  1,  1  1,  1  1 ...
                           1  0  0  1,  1  0,  1  0];

            vbo = VertexBufferObject(canvas, GL.ARRAY_BUFFER, single(vertexData), GL.STATIC_DRAW);

            obj.vao = VertexArrayObject(canvas);
            obj.vao.setAttribute(vbo, 0, 4, GL.FLOAT, GL.FALSE, 8*4, 0);
            obj.vao.setAttribute(vbo, 1, 2, GL.FLOAT, GL.FALSE, 8*4, 4*4);
            obj.vao.setAttribute(vbo, 2, 2, GL.FLOAT, GL.FALSE, 8*4, 6*4);

            obj.texture = TextureObject(canvas, 2);
            obj.texture.setImage(zeros(canvas.size(2), canvas.size(1), 4, 'uint8'));
            
            obj.framebuffer = FramebufferObject(canvas);
            obj.framebuffer.attachColor(0, obj.texture);
            
            obj.renderer = Renderer(canvas);
            obj.renderer.projection.orthographic(0, 1, 0, 1);
        end
        
        function drawFrame(obj, stimuli, controllers, frame, frameDuration, time)
            nPatterns = obj.patternRenderer.numPatterns;
            patternDuration = frameDuration / nPatterns;
            
            for pattern = 0:nPatterns-1
                state.frame = frame;
                state.frameDuration = frameDuration;
                state.time = patternDuration * pattern + time;
                state.pattern = pattern;
                state.patternDuration = patternDuration;
                
                obj.evaluateControllers(controllers, state);
                
                % Draw the pattern on to a texture.
                obj.canvas.setFramebuffer(obj.framebuffer);
                obj.canvas.clear();
                obj.drawStimuli(stimuli);
                obj.canvas.resetFramebuffer();
                
                % Pack the pattern into the main framebuffer.
                obj.canvas.enableBlend(GL.SRC_ALPHA, GL.ONE);
                obj.renderer.drawArray(obj.vao, GL.TRIANGLE_STRIP, 0, 4, [1, 1, 1, 1], [], obj.texture, []);
                obj.canvas.resetBlend();
                
                obj.patternRenderer.incrementPatternIndex();
            end
        end
        
    end
    
end