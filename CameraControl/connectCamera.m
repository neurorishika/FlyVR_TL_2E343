function connectCamera(handles,camInd)
%camInd: 1, back camera; 2, side camera
if nargin < 2
    camInd = [1:length(handles.hComm.flea3)];
end
    
for camCounter = camInd
    if ~(handles.hComm.flea3(camCounter) == 0)
%         flea3(camCounter) = BiasControlV49(camera(camCounter).ip,camera(camCounter).port);
        handles.hComm.flea3(camCounter).connect();
    end
end