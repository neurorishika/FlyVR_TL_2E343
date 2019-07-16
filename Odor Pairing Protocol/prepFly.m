system('start "cloop" call C:\FlyVR_TL_2E343\cl_nozzlecontrol.py');
system('start "fictrac" C:\FlyVR_TL_2E343\FicTrac\FicTrac-PGR-View.bat');
pause(60*20);
system('taskkill /fi "WINDOWTITLE eq bias*"');
system('taskkill /fi "WINDOWTITLE eq fictrac*"');
system('taskkill /fi "WINDOWTITLE eq cloop*"');