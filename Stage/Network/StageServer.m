% A single-client server that allows remote access to a Stage session.

classdef StageServer < handle
    
    properties (Access = protected)
        canvas
        sessionData
    end
    
    properties (Access = private)
        tcpServer
    end
    
    methods
        
        function obj = StageServer(port)
            if nargin < 1
                port = 5678;
            end
            
            obj.tcpServer = TcpServer(port);
            
            addlistener(obj.tcpServer, 'clientConnected', @obj.onClientConnected);
            addlistener(obj.tcpServer, 'clientDisconnected', @obj.onClientDisconnected);
            addlistener(obj.tcpServer, 'eventReceived', @obj.onEventReceived);
            addlistener(obj.tcpServer, 'timedOut', @obj.onTimedOut);
        end
        
        % Creates a window/canvas and starts serving clients. All arguments are passed through to the Window 
        % constructor. This method will block the current Matlab session until all clients are disconnected and the 
        % escape key is held while the window has focus.
        function start(obj, varargin)            
            obj.prepareToStart(varargin{:});
            close = onCleanup(@()delete(obj.canvas));
            
            disp(['Serving on port: ' num2str(obj.tcpServer.port)]);
            obj.tcpServer.start();
        end
        
    end
    
    methods (Access = protected)
        
        function prepareToStart(obj, varargin)
            window = Window(varargin{:});
            obj.canvas = Canvas(window);
        end
        
        function onClientConnected(obj, src, data) %#ok<INUSL>
            rhost = data.client.socket.getInetAddress().getHostName();
            rport = data.client.socket.getPort();
            disp(['Serving connection from ' char(rhost) ':' num2str(rport)]);
            
            obj.sessionData.player = [];
            obj.sessionData.playInfo = [];
        end
        
        function onClientDisconnected(obj, src, data) %#ok<INUSD>
            disp('Client disconnected');
            
            obj.sessionData = [];
            
            % Clear class definitions.
            memory = inmem;
            for i = 1:length(memory)
                if exist(memory{i}, 'class')
                    clear(memory{i});
                end
            end
        end
        
        function onEventReceived(obj, src, data) %#ok<INUSL>           
            client = data.client;
            value = data.value;
            
            try
                switch value{1}
                    case NetEvents.GET_CANVAS_SIZE
                        obj.onEventGetCanvasSize(client, value);
                    case NetEvents.SET_CANVAS_COLOR
                        obj.onEventSetCanvasColor(client, value);
                    case NetEvents.PLAY
                        obj.onEventPlay(client, value);
                    case NetEvents.REPLAY
                        obj.onEventReplay(client, value);
                    case NetEvents.GET_PLAY_INFO                        
                        obj.onEventGetPlayInfo(client, value);
                    case NetEvents.SET_CANVAS_TRANSLATION
                        obj.onEventSetCanvasTranslation(client, value);
                    otherwise
                        error('Unknown event');
                end
            catch x
                disp('on event received error')
                client.send(NetEvents.ERROR, x);
            end
        end
        
        function onEventGetCanvasSize(obj, client, value) %#ok<INUSD>
            size = obj.canvas.size;
            client.send(NetEvents.OK, size);
        end
        
        function onEventSetCanvasColor(obj, client, value)
            color = value{2};
            
            obj.canvas.setClearColor(color);
            obj.canvas.clear();
            obj.canvas.window.flip();
            client.send(NetEvents.OK);
        end
        
        function onEventPlay(obj, client, value)
            presentation = value{2};
            prerender = value{3};
            
            if prerender
                obj.sessionData.player = PrerenderedPlayer(presentation);
            else
                obj.sessionData.player = RealtimePlayer(presentation);
            end
            
            % Unlock client to allow async operations during play.
            client.send(NetEvents.OK);
            
            try
                obj.sessionData.playInfo = obj.sessionData.player.play(obj.canvas);
            catch x
                obj.sessionData.playInfo = x;
            end
        end
        
        function onEventReplay(obj, client, value) %#ok<INUSD>
            if isempty(obj.sessionData.player)
                error('No player exists');
            end
            
            % Unlock client to allow async operations during play.
            client.send(NetEvents.OK);
            
            try
                player = obj.sessionData.player;
                if ismethod(player, 'replay')
                    obj.sessionData.playInfo = player.replay(obj.canvas);
                else
                    obj.sessionData.playInfo = player.play(obj.canvas);
                end
            catch x
                obj.sessionData.playInfo = x;
            end
        end
        
        function onEventGetPlayInfo(obj, client, value) %#ok<INUSD>
            info = obj.sessionData.playInfo;
            client.send(NetEvents.OK, info);
        end
        
        function onEventSetCanvasTranslation(obj, client, value)   
            obj.resetCanvasTranslation();
            try
                x = value{2};
                y = value{3};
                obj.canvas.projection.translate(x,y,0);
            catch
                disp('error on SetCanvasTranslation');
            end            
            client.send(NetEvents.OK);            
        end
        
        function onTimedOut(obj, src, data) %#ok<INUSD>
            window = obj.canvas.window;
            
            window.pollEvents();
            escState = window.getKeyState(GLFW.GLFW_KEY_ESCAPE);
            if escState == GLFW.GLFW_PRESS
                obj.tcpServer.requestStop();
            end
        end
        
    end
    
end