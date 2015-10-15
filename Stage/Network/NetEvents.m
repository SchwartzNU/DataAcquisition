classdef NetEvents
    
    properties (Constant)
        %% Client to server:
        % Requests the current canvas size.
        GET_CANVAS_SIZE = 'GET_CANVAS_SIZE'
        
        % Request a new canvas color.
        SET_CANVAS_COLOR = 'SET_CANVAS_COLOR'
        
        % Sets translation
        SET_CANVAS_TRANSLATION = 'SET_CANVAS_TRANSLATION'
        
        % Requests that a presentation be played.
        PLAY = 'PLAY'
        
        % Requests that the last played presentation be played again.
        REPLAY = 'REPLAY'
        
        % Requests information about the last played presentation.
        GET_PLAY_INFO = 'GET_PLAY_INFO'
        
        %% Server to client:
        % The request was completed successfully.
        OK = 'OK'
        
        % An error occurred while executing the request.
        ERROR = 'ERROR'
    end
    
end