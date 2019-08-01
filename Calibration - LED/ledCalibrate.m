function ledCalibrate(Exp_Name,startWait, ledLength, endWait, ledIntensity)

if nargin < 1
    Exp_Name = 'SSM';
    startWait = 3;
    ledLength = 20;
    endWait = 3;
    ledIntensity = 10;
    sampleRate=1000;
    nTrials = 3;
end

close all ;


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


% Setup LED Trigger
preLedDelay = initDelay + (startWait)*sampleRate;
ledEnd = initDelay + (startWait+ledLength)*sampleRate;
ledTrigger(preLedDelay:ledEnd) = ledIntensity*ones; 

% plot(ledTrigger)

for trial = 1:nTrials
    
    tic;
    
    queueOutputData(Session,[ledTrigger cameraTrigger]);
    
    startBackground(Session);

    pause(trialLength/sampleRate)
end
%% End Trial %%

