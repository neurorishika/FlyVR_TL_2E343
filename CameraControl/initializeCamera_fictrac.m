function handles=initializeCamera_fictrac(handles)

if nargin < 1
    thisDate = datestr(now,'yymmdd');
    handles.expDataDir = ['C:\Data_FOB\',thisDate];
end
try
    mkdir(handles.expDataDir)
end

%% == Camera_user_setting ==
camera(1).ip = '127.0.0.1';
camera(1).port = 5010;

camera(2).ip = '127.0.0.1';
camera(2).port = 5020;

camera(3).ip = '127.0.0.1';
camera(3).port = 5030;

%
movieFormat = 'avi';
frameRate = 60;
ROI = [128 128 1024 768];
triggerMode = 'internal';

biasFile = 'C:\Data_fictrac\CameraControl\bias_gui.bat';
% defaultJsonFile{1} = 'C:\Users\Glenn\Documents\MATLAB\thacq.ver4\CameraControl\bias_config_external.json';
defaultJsonFile{1} = 'C:\Data_fictrac\CameraControl\bias_config_balltracking_cam0.json';%ufmf, 512x512, lowered compression
defaultJsonFile{2} = 'C:\Data_fictrac\CameraControl\bias_config_balltracking_cam1.json';%ufmf, 512x512, lowered compression
defaultJsonFile{3} = 'C:\Data_fictrac\CameraControl\bias_config_balltracking_cam2.json';%ufmf, 512x512, lowered compression


%% == initialize_camera; ==
try
    %Run the camera server program bias
    dos([biasFile, ' &']);
    pause(1);
    %initialize the camera
    for camCounter = 1:length(camera)
        flea3(camCounter) = BiasControlV49(camera(camCounter).ip,camera(camCounter).port);
        %flea3.initializeCamera(frameRate, movieFormat, ROI, triggerMode);
        flea3(camCounter).connect();
        flea3(camCounter).loadConfiguration(defaultJsonFile{camCounter});
        flea3(camCounter).disableLogging();
        hComm.flea3(camCounter) = flea3(camCounter);
    end
    
catch ME
    disp('error\n');
    disp(ME.message);
    if camCounter == 1
        for i = 1:length(camera)
            flea3(i) = 0;
            hComm.flea3(i) = flea3(i);
        end
    elseif camCounter == 2
        flea3(2) = 0;
        hComm.flea3(2) = flea3(2);
    end
end
%%
%Save values in handles
handles.biasFile = biasFile;
handles.hComm = hComm;
handles.jsonFile = defaultJsonFile;
handles.movieFormat = movieFormat;
handles.frameRate = frameRate;
handles.ROI = ROI;
handles.triggerMode = triggerMode;
handles.intensityMode = 'LINEAR';
handles.cameraRunning = 1;

% Camera preview
for i = 1:length(hComm.flea3)
    if ~(hComm.flea3(i) == 0)
        flyBowl_camera_control(handles.hComm.flea3(i),'preview');
    end
end
