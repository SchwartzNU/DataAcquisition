function gabor()    
    % Open a window in windowed-mode and create a canvas.
    window = Window([640, 480], false);
    canvas = Canvas(window);
    
    % Set the canvas background color to gray.
    canvas.setClearColor(0.5);
    canvas.clear();
    
    % Create the grating stimulus.
    grating = Grating();
    grating.position = canvas.size / 2;
    grating.size = [300, 300];
    grating.spatialFreq = 1/100; % 1 cycle per 100 pixels
    
    % Assign a gaussian envelope mask to the grating.
    mask = Mask.createGaussianEnvelope();
    grating.setMask(mask);
    
    % Create a controller to change the grating's phase property as a function of time. The phase will shift 360 degrees 
    % per second.
    gaborPhaseController = PropertyController(grating, 'phase', @(state)state.time * 360);
    
    % Create a 5 second presentation and add the stimulus and controller.
    presentation = Presentation(5);
    presentation.addStimulus(grating);
    presentation.addController(gaborPhaseController);
    
    % Play the presentation on the canvas!
    presentation.play(canvas);
    
    % Window automatically closes when the window object is deleted.
end