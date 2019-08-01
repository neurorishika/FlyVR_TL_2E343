function runPairingTrial_memory(Exp_Name, CSpWait, CSpLength, ledDelay, CSmWait, CSmLength, endWait, ledPulseWidth, ledIntensity, nTrials, trialDelay, sampleRate)
%% initialize camera

if nargin < 1
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
    nTrials = 5;
    trialDelay = 180/spd;
    sampleRate=1000;
end
close all ;

%% Start Close Loop %%

system('start "cloop" call C:\FlyVR_TL_2E343\cl_nozzlecontrol.py')

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
stateOff=ones(1,length(valvedio.Channels));
stateOn=ones(1,length(valvedio.Channels));

lines = {'Vial1','Vial2','Vial3','Vial4','Vial5','Final'};
on = [0 0 0 0 1 0];
off = [1 0 0 0 0 0];

if iscell(lines)    
    channelNames={valvedio.Channels.Name};
    for i=1:length(lines)
        thisLine=find(strcmp(channelNames,lines(i)));
        if ~isempty(thisLine)
            stateOn(thisLine)=on(i);
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

%% Start Fictrac %%

%system('start "fictrac" C:\FlyVR_TL_2E343\FicTrac\FicTrac-PGR.bat')

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
    
    %{
    %Use bias to set the trigger mode of pointgrey to "external"
    handles.triggerMode = 'external';
    %hand over camera 1 to fictrac
    configCameraTrigger(handles,1);
    disconnectCamera(handles,1);
    %}
    
    system('start "fictrac" C:\FlyVR_TL_2E343\FicTrac\FicTrac-PGR.bat')
    
    queueOutputData(Session,[ledTrigger cameraTrigger]);
    
    setuptime=toc;
    
    startBackground(Session);
    
    %start camera 2 and 3
    startCamera(handles,1)
    startCamera(handles,2)
    %{
    startCamera(handles,2)
    startCamera(handles,3)
    %}
    
    %===
    
    tic;
    pause(initDelay/sampleRate+CSpWait);
    toc
    diff =(toc- initDelay/sampleRate-CSpWait);
    outputSingleScan(valvedio,stateOn);
    fprintf('CS+ on\n');
    pause(CSpLength-diff);
    toc
    diff =(toc- initDelay/sampleRate-CSpWait-CSpLength);
    outputSingleScan(valvedio,stateOff);
    fprintf('CS+ off\n');
    pause(CSmWait-diff);
    toc
    diff =(toc- initDelay/sampleRate-CSpWait-CSpLength-CSmWait);
    outputSingleScan(valvedio,stateOn);
    fprintf('CS- on\n');
    pause(CSmLength-diff);
    toc
    diff =(toc- initDelay/sampleRate-CSpWait-CSpLength-CSmWait-CSmLength);
    outputSingleScan(valvedio,stateOff);
    fprintf('CS- off\n');
    pause(endWait-diff);
    toc
    fprintf('Trial Ended... Saving Started\n');

    system('taskkill /fi "WINDOWTITLE eq fictrac*"')

    %== stop bias and save video
    tic
    stopCamera(handles,1)
    stopCamera(handles,2)
    %{
    stopCamera(handles,2)
    stopCamera(handles,3)
    %}
    closeCamera(handles)
    %== 
    
    pathname= strcat('C:\DATA_',Exp_Name,'\RUN_',datestr(now,'mmddyyyy_HHMM'),'_Trial_',num2str(trial));
    mkdir(pathname)

    copyfile('C:\FlyVR_TL_2E343\FicTrac\Test',pathname)
    toc
    pause(trialDelay-toc-setuptime)
    
    system('taskkill /fi "WINDOWTITLE eq bias*"')
    
end
%% End Trial %%

system('taskkill /fi "WINDOWTITLE eq fictrac*"')
system('taskkill /fi "WINDOWTITLE eq cloop*"')
release(valvedio)
release(Session)

