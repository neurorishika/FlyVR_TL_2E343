function runOdorTrial(Fly_ID, Exp_Name, startWait, odorLength, endWait, trialDelay, sampleRate)
%% initialize camera
if nargin < 1
    spd=10;%speed up
    Fly_ID = 'debug';
    Exp_Name = 'SSM';
    startWait = 60/spd;
    odorLength = 30/spd;
    endWait = 60/spd;
    nTrialsA = 6;
    nTrialsB = 6;
    trialDelay = 180/spd;
    sampleRate=1000;
elseif nargin < 2
    spd=1;%speed up
    Exp_Name = 'SSM';
    startWait = 60/spd;
    odorLength = 30/spd;
    endWait = 60/spd;
    nTrialsA = 6;
    nTrialsB = 6;
    trialDelay = 180/spd;
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
stateA=ones(1,length(valvedio.Channels));
stateB=ones(1,length(valvedio.Channels));

lines = {'Vial1','Vial2','Vial3','Vial4','Vial5','Final'};
off = [1 0 0 0 0 0];

if app_ave == 0
    a = [0 0 0 0 1 0];
    b = [0 0 0 1 0 0];
else
    a = [0 0 0 1 0 0];
    b = [0 0 0 0 1 0];
end

if iscell(lines)    
    channelNames={valvedio.Channels.Name};
    for i=1:length(lines)
        thisLine=find(strcmp(channelNames,lines(i)));
        if ~isempty(thisLine)
            stateA(thisLine)=a(i);
            stateB(thisLine)=b(i);
            stateOff(thisLine)=off(i);
        else
            error('Some of the vial names cannot be found\n');
        end
    end
end


initDelay = 50; % in msec
trialLength = initDelay + (startWait + odorLength + endWait)*sampleRate;

% Initialize Trigger Outputs
cameraTrigger = zeros(trialLength,1);
ledTrigger = zeros(trialLength,1);

FrameRate = 50 ;
nFrames = (startWait + odorLength + endWait)*FrameRate;

pulse_width = 1000/FrameRate;

% Setup Camera Trigger
for i = 1:nFrames
    cameraTrigger(initDelay+pulse_width*(i-1):initDelay+pulse_width*(i-1)+pulse_width/2) = 5*ones;
end


%% Setup Camera and Start Trial%%
nTrials = nTrialsA + nTrialsB;

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
    
    system('start "fictrac" C:\FlyVR_TL_2E343\FicTrac\FicTrac-PGR.bat');
    
    queueOutputData(Session,[ledTrigger cameraTrigger]);
    
    setuptime=toc;
    
    startBackground(Session);
    
    %start camera 2 and 3
    startCamera(handles,1)
    startCamera(handles,2)
    
    fprintf('Trial on\n');
    tic;
    pause(initDelay/sampleRate+startWait);
    toc
    diff =(toc- initDelay/sampleRate-startWait);
    if trial <= nTrialsA
        outputSingleScan(valvedio,stateA);
        fprintf('Odor A (V5) on\n');
    else
        outputSingleScan(valvedio,stateB);
        fprintf('Odor B (V4) on\n');
    end
    pause(odorLength-diff);
    toc
    diff =(toc- initDelay/sampleRate-startWait-odorLength);
    outputSingleScan(valvedio,stateOff);
    fprintf('Odor off\n');
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
    if app_ave ==0
        pathname= strcat('C:\DATA_',Exp_Name,'\ODOR_VALENCE_MSA-ACV',datestr(now,'mmddyyyy_HHMM'),'_Trial_',num2str(trial),'_',Fly_ID);
    else
        pathname= strcat('C:\DATA_',Exp_Name,'\ODOR_VALENCE_ACV-MSA',datestr(now,'mmddyyyy_HHMM'),'_Trial_',num2str(trial),'_',Fly_ID);
    end
    
    mkdir(pathname)

    copyfile('C:\FlyVR_TL_2E343\FicTrac\Test',pathname)
    
    toc
    pause(trialDelay-toc-setuptime)
    
    system('taskkill /fi "WINDOWTITLE eq bias*"');
    movefile(strcat('C:\Data_FOB\',datestr(now,'yymmdd'),'\test'),pathname)
end
%% End Trial %%

system('taskkill /fi "WINDOWTITLE eq fictrac*"');
system('taskkill /fi "WINDOWTITLE eq cloop*"');
release(valvedio)
release(Session)

system('start "reset" call C:\FlyVR_TL_2E343\Protocols\Scripts\nozzle_reset.py')

