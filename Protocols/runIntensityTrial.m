function runIntensityTrial(Fly_ID, Exp_Name, startWait, ledLength, endWait, ledIntensity)

system('taskkill /fi "WINDOWTITLE eq fictrac*"')
system('taskkill /fi "WINDOWTITLE eq cloop*"')

if nargin < 1
    speed = 10;
    Fly_ID = 'debug';
    Exp_Name = 'SSM';
    startWait = 60/speed;
    ledLength = 60/speed;
    endWait = 60/speed;
    ledIntensity = 5;
    sampleRate=1000;
    nTrials = 2;
    trialDelay = 180/speed;
elseif nargin < 2
    speed=1;
    Exp_Name = 'SSM';
    startWait = 60/speed;
    ledLength = 60/speed;
    endWait = 60/speed;
    ledIntensity = 5;
    sampleRate=1000;
    nTrials = 6;
    trialDelay = 180/speed;
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

initDelay = 50; % in msec
trialLength = initDelay + (startWait + ledLength + endWait)*sampleRate;

% Initialize Trigger Outputs
cameraTrigger = zeros(trialLength,1);
ledTrigger = zeros(trialLength,1);
% odorTrigger = zeros(trialLength,1);

FrameRate = 50 ;
nFrames = (startWait + ledLength + endWait)*FrameRate;

pulse_width = 1000/FrameRate;

% Setup Camera Trigger
for i = 1:nFrames
    cameraTrigger(initDelay+pulse_width*(i-1):initDelay+pulse_width*(i-1)+pulse_width/2) = 5*ones;
end

% Setup LED Trigger
preLedDelay = initDelay + (startWait)*sampleRate;
ledEnd = initDelay + (startWait+ledLength)*sampleRate;
ledTrigger(preLedDelay:ledEnd) = ledIntensity*ones; 


%% Setup Camera and Start Trial%%

for trial = 1:nTrials
    
    tic;
    
    %== Set up file saving for bias ==
    try %in case bias is already running
        global handles
        closeCamera(handles)
        clear handles
    end
    
    handles = initializeCamera_fictrac;
    filename = 'test';
    handles.expDataSubdir=[handles.expDataDir,'\',strrep(filename,'.mat','')];
    handles.trialMovieName = [handles.expDataSubdir, '\movie_',num2str(trial), '.', handles.movieFormat];
    
    system('start "fictrac" C:\FlyVR_TL_2E343\FicTrac\FicTrac-PGR.bat')
    

    queueOutputData(Session,[ledTrigger cameraTrigger]);
    
    setuptime=toc;
    
    startBackground(Session);

    startCamera(handles,1)
    startCamera(handles,2)

    pause(trialLength/sampleRate)

    system('taskkill /fi "WINDOWTITLE eq fictrac*"')

    tic
    stopCamera(handles,1)
    stopCamera(handles,2)
    closeCamera(handles)
    %== 

    pathname= strcat('C:\DATA_',Exp_Name,'\MBON_Intensity_',datestr(now,'mmddyyyy_HHMM'),'_Trial_',num2str(trial),'_',Fly_ID);
    mkdir(pathname) 
    
    copyfile('C:\FlyVR_TL_2E343\FicTrac\Test',pathname)
    
    pause(trialDelay-toc-setuptime)
    toc
    
    system('taskkill /fi "WINDOWTITLE eq bias*"')
    movefile(strcat('C:\Data_FOB\',datestr(now,'yymmdd'),'\test'),pathname)
    
end
%% End Trial %%

system('taskkill /fi "WINDOWTITLE eq fictrac*"')
system('taskkill /fi "WINDOWTITLE eq cloop*"')
release(Session)
system('start "reset" call C:\FlyVR_TL_2E343\Protocols\Scripts\nozzle_reset.py')
