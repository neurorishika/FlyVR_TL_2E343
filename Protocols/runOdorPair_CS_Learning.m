function runOdorPair_CS_Learning(Fly_ID, Exp_Name)
%% initialize camera
if nargin < 1
    spd=1;%speed up
    Fly_ID = 'debug';
    Exp_Name = 'SSM';
    CSpWait = 20/spd;
    CSpLength = 30/spd;
    ledDelay = 15/spd;
    CSmWait = 20/spd;
    CSmLength = 30/spd;
    endWait = 20/spd;
    ledPulseWidth = 1/spd;
    ledIntensity = 3/spd;
    nTrials = 1;
    nBlocks = 1;
    blockDelay = 180/spd;
    sampleRate=1000;
elseif nargin < 2
    spd=1;%speed up
    Exp_Name = 'SSM';
    CSpWait = 20/spd;
    CSpLength = 30/spd;
    ledDelay = 15/spd;
    CSmWait = 20/spd;
    CSmLength = 30/spd;
    endWait = 20/spd;
    ledPulseWidth = 1/spd;
    ledIntensity = 3/spd;
    nTrials = 6;
    nBlocks = 3;
    blockDelay = 180/spd;
    sampleRate=1000;
end
close all ;

%% Start Close Loop %%

system('start "cloop" call C:\FlyVR_TL_2E343\Protocols\Scripts\cl_nozzlecontrol.py')

%% Setup NIDAQ-6001 Device for Trigger %%

HWlist=daq.getDevices;
for i=1:length(HWlist)
    if strcmpi(HWlist(i).Model,'USB-6001')
        NIdaq.dev=HWlist(i).ID;
    end
end
if ~isfield(NIdaq,'dev')
    error('Cannot connect to USB-6001')
end

% Create NIDAQ Session
Session = daq.createSession('ni');

fprintf('USB-6001 Session Created.\n')

% Setup Sampling
Session.Rate = 1000;

% Camera Channel
Session.addAnalogOutputChannel(NIdaq.dev,'ao1','Voltage');
% LED Channel
Session.addAnalogOutputChannel(NIdaq.dev,'ao0','Voltage');

%% Setup NIDAQ-6525 for Olfactometer %%

valvedio = connectToUSB6525()
pause(2)

fprintf('USB-6525 Session Created.\n')

% NIDAQ Signals
app_ave = 1;

stateOff=ones(1,length(valvedio.Channels));
stateOCT=ones(1,length(valvedio.Channels));
stateMCH=ones(1,length(valvedio.Channels));

lines = {'Vial1','Vial2','Vial3','Vial4','Vial5','Final'};
off = [1 0 0 0 0 0];
oct = [0 1 0 0 0 0];
mch = [0 0 1 0 0 0];

if iscell(lines)    
    channelNames={valvedio.Channels.Name};
    for i=1:length(lines)
        thisLine=find(strcmp(channelNames,lines(i)));
        if ~isempty(thisLine)
            stateOCT(thisLine)=oct(i);
            stateMCH(thisLine)=mch(i);
            stateOff(thisLine)=off(i);
        else
            error('Some of the vial names cannot be found\n');
        end
    end
end


initDelay = 50; % in msec
trialLength = initDelay + (CSpWait + CSpLength + CSmWait + CSmLength + endWait)*sampleRate;

% Initialize Trigger Outputs
cameraTrigger = zeros(trialLength,1);
ledTrigger = zeros(trialLength,1);
% odorTrigger = zeros(trialLength,1);

FrameRate = 50 ;
nFrames = (CSpWait + CSpLength + CSmWait + CSmLength + endWait)*FrameRate;

pulse_width = 1000/FrameRate;

% Setup Camera Trigger
for i = 1:nFrames
    cameraTrigger(initDelay+pulse_width*(i-1):initDelay+pulse_width*(i-1)+pulse_width/2) = 5*ones;
end

% Setup LED Trigger
totalLedPulses = floor((CSpLength-ledDelay)/(2*ledPulseWidth));
preLedDelay = initDelay + (CSpWait + ledDelay)*sampleRate;
for i = 0:totalLedPulses
   ledTrigger(preLedDelay+2*i*ledPulseWidth*sampleRate:preLedDelay+2*i*ledPulseWidth*sampleRate+ledPulseWidth*sampleRate) = ledIntensity*ones; 
end


%% Setup Camera and Start Trial%%
for block = 1:nBlocks
    
    for trial = 1:nTrials

        tic;
        try %in case bias is already running
            global handles
            closeCamera(handles)
            clear handles
        end

        handles = initializeCamera_fictrac;
        filename = 'test';
        handles.expDataSubdir=[handles.expDataDir,'\',strrep(filename,'.mat','')];
        handles.trialMovieName = [handles.expDataSubdir, '\movie_',num2str(trial), '.', handles.movieFormat];

        system('start "fictrac" C:\FlyVR_TL_2E343\FicTrac\FicTrac-PGR.bat');

        queueOutputData(Session,[ledTrigger cameraTrigger]);

        setuptime=toc;

        startBackground(Session);

        %start camera 2 and 3
        startCamera(handles,1)
        startCamera(handles,2)

        fprintf('Trial on\n');
        tic;
        pause(initDelay/sampleRate+CSpWait);
        toc
        diff =(toc- initDelay/sampleRate-CSpWait);
        outputSingleScan(valvedio,stateOCT);
        fprintf('CS+ on\n');
        pause(CSpLength-diff);
        toc
        diff =(toc- initDelay/sampleRate-CSpWait-CSpLength);
        outputSingleScan(valvedio,stateOff);
        fprintf('CS+ off\n');
        pause(CSmWait-diff);
        toc
        diff =(toc- initDelay/sampleRate-CSpWait-CSpLength-CSmWait);
        outputSingleScan(valvedio,stateMCH);
        fprintf('CS- on\n');
        pause(CSmLength-diff);
        toc
        diff =(toc- initDelay/sampleRate-CSpWait-CSpLength-CSmWait-CSmLength);
        outputSingleScan(valvedio,stateOff);
        fprintf('CS- off\n');
        pause(endWait-diff);
        toc
        fprintf('Trial Ended... Saving Started\n');

        system('taskkill /fi "WINDOWTITLE eq fictrac*"');

        %== stop bias and save video
        tic
        stopCamera(handles,1)
        stopCamera(handles,2)

        closeCamera(handles)
        %== 
        pathname= strcat('C:\DATA_',Exp_Name,'\Odor_Paired_Learning_',datestr(now,'mmddyyyy_HHMM'),'_Block_',num2str(block),'_Trial_',num2str(trial),'_',Fly_ID);

        mkdir(pathname)

        copyfile('C:\FlyVR_TL_2E343\FicTrac\Test',pathname)
        system('taskkill /fi "WINDOWTITLE eq bias*"');
        movefile(strcat('C:\Data_FOB\',datestr(now,'yymmdd'),'\test'),pathname)
        fprintf('Saving Done\n');
        toc
    end
    tic
    fprintf('Inter-Block Delay Started');
    pause(blockDelay)
    toc
end
%% End Trial %%

system('taskkill /fi "WINDOWTITLE eq fictrac*"');
system('taskkill /fi "WINDOWTITLE eq cloop*"');
release(valvedio)
release(Session)

system('start "reset" call C:\FlyVR_TL_2E343\Protocols\Scripts\nozzle_reset.py')
