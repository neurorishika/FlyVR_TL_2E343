function closeCamera(handles,camInd)
%camInd: 1, back camera; 2, side camera
if nargin < 2
    camInd = [1:length(handles.hComm.flea3)];
end
    
hComm=handles.hComm;
for camCounter = camInd
    if ~(hComm.flea3(camCounter)==0)
        hComm.flea3(camCounter).stopCapture();
        hComm.flea3(camCounter).disableLogging();
        hComm.flea3(camCounter).disconnect();
        hComm.flea3(camCounter).closeWindow();
    end
end