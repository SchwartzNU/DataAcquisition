% A player that draws all frames to memory prior to playback.

classdef PrerenderedPlayer < Player
    
    properties (Access = private)
        renderedFrames
    end
    
    methods
        
        function obj = PrerenderedPlayer(presentation)
            obj = obj@Player(presentation);
        end
        
        function info = play(obj, canvas)
            obj.prerender(canvas);
            info = obj.replay(canvas);
        end
        
        function prerender(obj, canvas)
            frameRate = canvas.window.monitor.refreshRate;
            nFrames = floor(obj.presentation.duration * frameRate) + 1;
            
            obj.renderedFrames = cell(1, nFrames);
            
            obj.compositor.init(canvas);
            
            stimuli = obj.presentation.stimuli;
            controllers = obj.presentation.controllers;
            
            for i = 1:length(stimuli)
                stimuli{i}.init(canvas);
            end
            
            frame = 0;
            frameDuration = 1 / canvas.window.monitor.refreshRate;
            time = frame * frameDuration;
            while time <= obj.presentation.duration
                canvas.clear();
                
                obj.compositor.drawFrame(stimuli, controllers, frame, frameDuration, time);
                
                obj.renderedFrames{frame + 1} = canvas.getPixelData(0, 0, canvas.size(1), canvas.size(2), false);
                
                canvas.window.pollEvents();
                
                frame = frame + 1;
                time = frame * frameDuration;
            end
        end
        
        function info = replay(obj, canvas)            
            flipTimer = FlipTimer();
            
            % Each vertex position is followed by a texture coordinate and a mask coordinate.
            vertexData = [ 0  1  0  1,  0  1,  0  1 ...
                           0  0  0  1,  0  0,  0  0 ...
                           1  1  0  1,  1  1,  1  1 ...
                           1  0  0  1,  1  0,  1  0];

            vbo = VertexBufferObject(canvas, GL.ARRAY_BUFFER, single(vertexData), GL.STATIC_DRAW);

            vao = VertexArrayObject(canvas);
            vao.setAttribute(vbo, 0, 4, GL.FLOAT, GL.FALSE, 8*4, 0);
            vao.setAttribute(vbo, 1, 2, GL.FLOAT, GL.FALSE, 8*4, 4*4);
            vao.setAttribute(vbo, 2, 2, GL.FLOAT, GL.FALSE, 8*4, 6*4);

            texture = TextureObject(canvas, 2);
            texture.setImage(obj.renderedFrames{1}, 0, false);
            
            renderer = Renderer(canvas);
            renderer.projection.orthographic(0, 1, 0, 1);
            
            try %#ok<TRYNC>
                setMaxPriority();
            end
            
            nFrames = length(obj.renderedFrames);
            for frame = 1:nFrames
                canvas.clear();
                
                texture.setSubImage(obj.renderedFrames{frame}, 0, [0, 0], false);
                
                renderer.drawArray(vao, GL.TRIANGLE_STRIP, 0, 4, [1, 1, 1, 1], [], texture, []);

                canvas.window.flip();
                flipTimer.tick();
                
                canvas.window.pollEvents();
            end
            
            try %#ok<TRYNC>
                setNormalPriority();
            end

            info.flipDurations = flipTimer.flipDurations;
        end
        
    end
    
end