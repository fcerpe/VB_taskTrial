% (C) Copyright 2018 Mohamed Rezk
% (C) Copyright 2020 CPP visual motion localizer developpers

%% Visual motion localizer

getOnlyPress = 1;

more off;

% Clear all the previous stuff
clc;
if ~ismac
    close all;
    clear Screen;
end

% make sure we got access to all the required functions and inputs
initEnv();

% set and load all the parameters to run the experiment
cfg = setParameters;
cfg = userInputs(cfg);
cfg = createFilename(cfg);

load('input/mvpa_trial1101.mat');

%%  Experiment

% Safety loop: close the screen if code crashes
try

    %% Init the experiment
    [cfg] = initPTB(cfg);

    cfg = postInitializationSetup(cfg);

    cfg = expDesign(cfg);
    
    % Prepare for the output logfiles with all
    logFile.extraColumns = cfg.extraColumns;
    logFile = saveEventsFile('init', cfg, logFile);
    logFile = saveEventsFile('open', cfg, logFile);

    % prepare textures
    cfg = apertureTexture('init', cfg);
    cfg = dotTexture('init', cfg);

    disp(cfg);

    % Show experiment instruction
    standByScreen(cfg);

    % prepare the KbQueue to collect responses
    getResponse('init', cfg.keyboard.responseBox, cfg);


    %% Experiment Start

    cfg = getExperimentStart(cfg);

    getResponse('start', cfg.keyboard.responseBox);

    waitFor(cfg, cfg.timing.onsetDelay);

    %% For Each Block

    for iBlock = 1:cfg.design.nbBlocks

        fprintf('\n - Running Block %.0f \n', iBlock);
        
        % Here is the list of stimuli to check:   
        % cochon  faucon  balcon  vallon  poulet  roquet  chalet  sommet 
        % ⠉⠕⠉⠓⠕⠝  ⠋⠁⠥⠉⠕⠝  ⠃⠁⠇⠉⠕⠝  ⠧⠁⠇⠇⠕⠝  ⠏⠕⠥⠇⠑⠞  ⠗⠕⠟⠥⠑⠞  ⠉⠓⠁⠇⠑⠞  ⠎⠕⠍⠍⠑⠞
        % (as long as the machin knows what to do)              
        stimuliUnicode = [72 101 114 101 32 105 115 32 116 104 101 32 108 105 115 116 32 111 102 32 115 116 105 109 117 108 105 ...
                          32 116 111 32 99 104 101 99 107 58 10 10 ...
                          102 97 117 99 111 110 32 32 32 32 32 32 32 32 114 111 113 117 101 116 32 32 32 32 32 32 32 32 ...
                          99 111 99 104 111 110 32 32 32 32 32 32 32 32 112 111 117 108 101 116 10 10 ...
                          98 97 108 99 111 110 32 32 32 32 32 32 32 32 118 97 108 108 111 110 32 32 32 32 32 32 32 32 ...
                          99 104 97 108 101 116 32 32 32 32 32 32 32 32 115 111 109 109 101 116 10 10 ...
                          10255 10261 10277 10247 10257 10270 32 32 32 32 32 32 32 32 10263 10261 10271 10277 10257 10270 32 32 32 32 32 32 32 32 ...
                          10254 10261 10253 10253 10257 10270 32 32 32 32 32 32 32 32 10279 10241 10247 10247 10261 10269 10 10 ...
                          10249 10261 10249 10259 10261 10269 32 32 32 32 32 32 32 32 10251 10241 10277 10249 10261 10269 32 32 32 32 32 32 32 32 ...
                          10243 10241 10247 10249 10261 10269 32 32 32 32 32 32 32 32 10249 10259 10241 10247 10257 10270];
        
        if iBlock == 1 || iBlock == 4 || iBlock == 7 
            
            Screen('TextSize', cfg.screen.win, 35);
            DrawFormattedText(cfg.screen.win, double(stimuliUnicode), 'center','center', cfg.text.color);
            Screen('Flip', cfg.screen.win);
            WaitSecs(30);
        end
        
        previousEvent.target = 0;
        % For each event in the block
        for iEvent = 1:cfg.design.nbEventsPerBlock
            
            % Check for experiment abortion from operator
            checkAbort(cfg, cfg.keyboard.keyboard);

            [thisEvent, thisFixation, cfg] = preTrialSetup(cfg, iBlock, iEvent);

            % we wait for a trigger every 2 events
            if cfg.pacedByTriggers.do && mod(iEvent, 2) == 1
                waitForTrigger(cfg, cfg.keyboard.responseBox, cfg.pacedByTriggers.quietMode, ...
                               cfg.pacedByTriggers.nbTriggers);
            end

            % Get the image file 
            currentImgIndex = cfg.design.stimuliPresentation(iBlock,iEvent);
            
            if cfg.design.stimuliTargets(iBlock,iEvent) == 1
                folder = 'nonwords';
            else 
                folder = 'words';
            end
            
            eval(['thisImage = images.' folder '.' char("w" + currentImgIndex) ';']);

            % play the dots and collect onset and duraton of the event
            [onset, duration] = doDotMo(cfg, thisEvent, thisFixation, thisImage, iEvent);

            thisEvent = preSaveSetup( ...
                                     thisEvent, ...
                                     thisFixation, ...
                                     iBlock, iEvent, ...
                                     duration, onset, ...
                                     currentImgIndex, ...
                                     thisEvent.fixTarget(1), ...
                                     cfg.design.stimuliTargets(iBlock,iEvent), ...
                                     cfg, ...
                                     logFile);

            saveEventsFile('save', cfg, thisEvent);

            % collect the responses and appends to the event structure for
            % saving in the tsv file
            responseEvents = getResponse('check', cfg.keyboard.responseBox, cfg, ...
                                         getOnlyPress);

            triggerString = ['trigger_' cfg.design.blockNames{iBlock}];
            saveResponsesAndTriggers(responseEvents, cfg, logFile, triggerString);

            previousEvent = thisEvent;

            waitFor(cfg, cfg.timing.ISI);

        end

        % "prepare" cross for the baseline block
        % if MT / MST this allows us to set the cross at the position of the next block
        if iBlock < cfg.design.nbBlocks
            nextBlock = iBlock + 1;
        else
            nextBlock = cfg.design.nbBlocks;
        end
        [~, thisFixation] = preTrialSetup(cfg, nextBlock, 1);
        drawFixation(thisFixation);
        Screen('Flip', cfg.screen.win);

        waitFor(cfg, cfg.timing.IBI);

        % trigger monitoring
        triggerEvents = getResponse('check', cfg.keyboard.responseBox, cfg, ...
                                    getOnlyPress);

        triggerString = 'trigger_baseline';
        saveResponsesAndTriggers(triggerEvents, cfg, logFile, triggerString);

    end

    % End of the run for the BOLD to go down
    waitFor(cfg, cfg.timing.endDelay);

    cfg = getExperimentEnd(cfg);

    % Close the logfiles
    saveEventsFile('close', cfg, logFile);

    getResponse('stop', cfg.keyboard.responseBox);
    getResponse('release', cfg.keyboard.responseBox);

    createJson(cfg, cfg);

    farewellScreen(cfg);

    cleanUp();

catch

    cleanUp();
    psychrethrow(psychlasterror);

end
