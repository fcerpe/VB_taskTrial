% (C) Copyright 2018 Mohamed Rezk
% (C) Copyright 2020 CPP visual motion localizer developpers

function [onset, duration, dots] = doDualTask(cfg, thisEvent, thisFixation, thisImage, iEvent)
    % Draws the stimulation of static/moving in 4 directions dots or static
    %
    % DIRECTIONS
    %  0=Right; 90=Up; 180=Left; 270=down
    %
    % Input:
    %   - cfg: PTB/machine configurations returned by setParameters and initPTB
    %
    % Output:
    %     -
    %
    % The dots are drawn on a square with a width equals to the width of the
    % screen
    % We then draw an aperture on top to hide the certain dots.

    %% Get parameters
%     if ~(strcmp(thisEvent.trial_type, 'static') && thisEvent.target == 1) ||  ...
%         isempty(dots)
%         dots = initDots(cfg, thisEvent);
%     end

    % Set for how many frames this event will last
    framesLeft = floor(cfg.timing.eventDuration / cfg.screen.ifi);

    %% Start the dots presentation
    vbl = Screen('Flip', cfg.screen.win);
    onset = vbl;
    
    Screen('BlendFunction', cfg.screen.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');


    while framesLeft
        % Make the image into a texture
        
        % WORDS PART
        imageTexture = Screen('MakeTexture', cfg.screen.win, thisImage);
        
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen
        Screen('DrawTexture', cfg.screen.win, imageTexture, [], [], 0);
                
        % FIXATION PART
        thisFixation.fixation.color = cfg.fixation.color;
        if thisEvent.fixTarget(1) && vbl < (onset + cfg.target.duration)
            thisFixation.fixation.color = cfg.fixation.colorTarget;
        end
        drawFixation(thisFixation);

        Screen('DrawingFinished', cfg.screen.win);

        vbl = Screen('Flip', cfg.screen.win, vbl + cfg.screen.ifi);

        %% Update counters

        % Check for end of loop
        framesLeft = framesLeft - 1;

    end

    %% Erase last dots

    drawFixation(thisFixation);

    Screen('DrawingFinished', cfg.screen.win);
    
    Screen('Close');

    vbl = Screen('Flip', cfg.screen.win, vbl + cfg.screen.ifi);

    duration = vbl - onset;

end
