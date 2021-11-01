% (C) Copyright 2020 CPP visual motion localizer developpers

function [cfg] = expDesign(cfg, displayFigs)
    % Creates the sequence of blocks and the events in them
    %
    % The conditions are consecutive static and motion blocks
    % (Gives better results than randomised).
    %
    % Style guide: constants are in SNAKE_UPPER_CASE
    %
    % EVENTS
    % The numEventsPerBlock should be a multiple of the number of "base"
    % listed in the MOTION_DIRECTIONS and STATIC_DIRECTIONS (4 at the moment).
    %  MOTION_DIRECTIONS = [0 90 180 270];
    %  STATIC_DIRECTIONS = [-1 -1 -1 -1];
    %
    % Pseudorandomization rules:
    % (1) Directions are all present in random orders in `numEventsPerBlock/nDirections`
    % consecutive chunks. This evenly distribute the directions across the
    % block.
    % (2) No same consecutive direction
    %
    %
    % TARGETS
    %
    % Pseudorandomization rules:
    % (1) If there are more than 1 target per block we make sure that they are at least 2
    % events apart.
    % (2) Targets cannot be on the first or last event of a block.
    % (3) Targets can not be present more than NB_REPETITIONS - 1 times in the same event
    % position across blocks.
    %
    % Input:
    % - cfg: parameters returned by setParameters
    % - displayFigs: a boolean to decide whether to show the basic design
    % matrix of the design
    %
    % Output:
    % - ExpParameters.designBlockNames = cell array (nr_blocks, 1) with the
    % name for each block
    %
    % - cfg.designDirections = array (nr_blocks, numEventsPerBlock)
    % with the direction to present in a given block
    % - 0 90 180 270 indicate the angle
    % - -1 indicates static
    %
    % - cfg.designSpeeds = array (nr_blocks, numEventsPerBlock) * speedEvent;
    %
    % - cfg.designFixationTargets = array (nr_blocks, numEventsPerBlock)
    % showing for each event if it should be accompanied by a target
    %

    %% Check inputs

    % Set to 1 for a visualtion of the trials design order
    if nargin < 2 || isempty(displayFigs)
        displayFigs = 0;
    end

    % Set variables here for a dummy test of this function
    if nargin < 1 || isempty(cfg)
        error('give me something to work with');
    end

    [NB_BLOCKS, NB_REPETITIONS, NB_EVENTS_PER_BLOCK, MAX_TARGET_PER_BLOCK] = getDesignInput(cfg);
    [~, CONDITON1_INDEX] = assignConditions(cfg);

    if mod(NB_REPETITIONS, MAX_TARGET_PER_BLOCK) ~= 0
        error('number of repetitions must be a multiple of max number of targets');
    end

    RANGE_TARGETS = MAX_TARGET_PER_BLOCK;
    targetPerCondition = repmat(RANGE_TARGETS, 1, NB_REPETITIONS / MAX_TARGET_PER_BLOCK);

    numTargetsForEachBlock = [9,9,9,9,9,9,9,9,9];
    % numTargetsForEachBlock(CONDITON1_INDEX) = shuffle(targetPerCondition);
    
    %% Give the blocks the names with condition and design the task in each event
    while 1

        fixationTargets = zeros(NB_BLOCKS, NB_EVENTS_PER_BLOCK);

        for iBlock = 1:NB_BLOCKS

            % Set target
            % - if there are 2 targets per block we make sure that they are at least
            % 2 events apart
            % - targets cannot be on the first or last event of a block
            % - no more than 2 target in the same event order

            nbTarget = numTargetsForEachBlock(iBlock);

            chosenPosition = setTargetPositionInSequence( ...
                                                         NB_EVENTS_PER_BLOCK, ...
                                                         nbTarget, ...
                                                         [1 NB_EVENTS_PER_BLOCK]);

            fixationTargets(iBlock, chosenPosition) = 1;

        end

        % Check rule 3
        if max(sum(fixationTargets)) < NB_REPETITIONS - 1
            break
        end

    end
    
    %% Put the stimuli in order and assign other targets
    stimMatrix = zeros(9,80);
    
    for i = 1:9
        for j =1:16:80
            stimMatrix(i,j:j+15) = randperm(16);
        end
    end

    % assign new targets
    while 1
        stimTargets = zeros(NB_BLOCKS, NB_EVENTS_PER_BLOCK);
        for k = 1:NB_BLOCKS
            nbTarget = numTargetsForEachBlock(k);
            chosenPosition = setTargetPositionInSequence(NB_EVENTS_PER_BLOCK, nbTarget, [1 NB_EVENTS_PER_BLOCK]);
            stimTargets(k, chosenPosition) = 1;
        end
        % Check rule 3
        if max(sum(stimTargets)) < NB_REPETITIONS - 1
            break
        end
    end
    
    %% Now we do the easy stuff
    cfg.design.blockNames = assignConditions(cfg);

    cfg.design.nbBlocks = NB_BLOCKS;

% %     cfg = setDirections(cfg);
% 
%     speeds = ones(NB_BLOCKS, NB_EVENTS_PER_BLOCK) * cfg.dot.speedPixPerFrame;
%     cfg.design.speeds = speeds;

    cfg.design.fixationTargets = fixationTargets;
    cfg.design.stimuliTargets = stimTargets;
    cfg.design.stimuliPresentation = stimMatrix;
    %% Plot
    diplayDesign(cfg, displayFigs);

end
