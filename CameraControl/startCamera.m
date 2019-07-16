function startCamera(handles,camInd)
%camInd: 1, back camera; 2, side camera
if nargin < 2
    camInd = [1:length(handles.hComm.flea3)];
end
    
for i = camInd
    if ~(handles.hComm.flea3(i) == 0)
        flyBowl_camera_control(handles.hComm.flea3(i),'stop');
        flyBowl_camera_control(handles.hComm.flea3(i),'start', handles.trialMovieName);
    end
end

