function modularDeviceBasicExample(port)
% modularDeviceBasicExample: demonstrates basic use of the
% ModularDevice class.
%
%  * Find serial port of modular device connected with a USB cable.
%    Windows:
%      Use command getAvailableComPorts()
%      Or use 'Device Manager' and look under 'Ports'.
%      Typically 'COM3' or higher.
%    Mac OS X:
%      Typically something like '/dev/tty.usbmodem'
%    Linux:
%      Typically something like '/dev/ttyACM0'
%
% Usage: (replace 'COM5' with the serial port of your device)
%
% getAvailableComPorts()
% modularDeviceBasicExample('COM5')
%

    % Create the Modular device object, open serial
    % connection and display device info.
    fprintf('Opening Modular device...\n');
    dev = ModularDevice(port);
    dev.open();
    fprintf('Modular Device Info:');
    dev.getDevInfo()

    % Pause for a little bit for added dramma
    pause(1.0)

    % Print dynamic methods
    dev.getMethods()
    fprintf('\n');

    % Clean up -
    dev.close();
    delete(dev);
    fprintf('Closed device. Goodbye!\n');
end
