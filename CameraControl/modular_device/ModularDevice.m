%
% ModularDevice - matlab serial interface for controlling and
% communicating with modular devices running the appropriate
% firmware.
%
% Public properties
% ------------------
%
%   * debug = debug flag, turns on debug messages if true.
%
%   (Dependent)
%   * isOpen    = true is serial connection to device is open, false otherwire
%   * methodIds = structure of method identification numbers retrieved from device.
%   * responseCodes  = structure of response codes retrieved from device.
%
%
% Note, in what follows 'dev' is assumed to be an instance of the ModularDevice class.
% dev = ModularDevice(portName)
%
% Regular (public) class methods
% -----------------------------
%
%   * open - opens serial connection to device
%     Usage: dev.open()
%
%   * close - closes serial connection to device
%     Usage: dev.close()
%
%   * delete - deletes instance of device object.
%     Usage: dev.delete() or delete(dev)
%
%   * getDeviceInfo - returns the device information.
%     e.g. name, model number, serial number, firmware number
%     Note, the device must be opened for this method to work.
%     Usage: device_info = dev.getDeviceInfo()
%
%   * getMethods - prints the names of all dynamically generated class
%     methods. Note, the device must be opened for this method to work.
%     Usage: dev.getMethods()
%
% Notes:
%
%  * Find serial port of modular device connected with a USB cable.
%    When the modular device is Arduino-based, you can use the
%    Arduino environment to help find port. Read more details
%    here: http://arduino.cc/en/Guide/HomePage
%    Windows:
%      Use command getAvailableComPorts()
%      Or use 'Device Manager' and look under 'Ports'.
%      Typically 'COM3' or higher.
%    Mac OS X:
%      Typically something like '/dev/tty.usbmodem'
%    Linux:
%      Typically something like '/dev/ttyACM0'
%
%
% Typical Usage:
%
%   % Linux and Mac OS X
%   ls /dev/tty*
%   serial_port = '/dev/ttyACM0'     % example Linux serial port
%   serial_port = '/dev/tty.usbmodem262471' % example Mac OS X serial port
%
%   % Windows
%   getAvailableComPorts()
%   serial_port = 'COM4'             % example Windows serial port
%
%   dev = ModularDevice(serial_port) % creates a device object
%   dev.open()                       % opens a serial connection to the device
%   device_info = dev.getDeviceInfo()% get device information
%   dev.getMethods()                 % get device methods
%   dev.close()                      % close serial connection
%   delete(dev)                      % deletes the device
%

classdef ModularDevice < handle

    properties
        dev = [];
        debug = false;
    end

    properties (Access=private)
        methodIdStruct = [];
        responseCodeStruct = [];
    end

    properties (Constant, Access=private)

        % Serial communication parameters.
        baudrate = 9600;
        databits = 8;
        stopbits = 1;
        timeout = 1.0;
        terminator = 'LF';
        resetDelay = 2.0;
        inputBufferSize = 2048;
        waitPauseDt = 0.25;
        powerOnDelay = 1.5;

        % Method ids for basic methods.
        methodIdGetDeviceInfo = 0;
        methodIdGetMethods = 1;
        methodIdGetResponseCodes = 2;

    end


    properties (Dependent)
        isOpen;
        methodIds;
        responseCodes;
    end

    methods

        function obj = ModularDevice(port)
        % ModularDevice - class constructor.
            obj.dev = serial( ...
                port, ...
                'baudrate', obj.baudrate, ...
                'databits', obj.databits, ...
                'stopbits', obj.stopbits, ...
                'timeout', obj.timeout, ...
                'terminator', obj.terminator,  ...
                'inputbuffersize', obj.inputBufferSize ...
                );

        end

        function open(obj)
        % Open - opens a serial connection to the device.
            if obj.isOpen == false
                fopen(obj.dev);
                pause(obj.resetDelay);
                obj.createResponseCodeStruct();
                obj.createMethodIdStruct();
            end
        end

        function close(obj)
        % Close - closes the connection to the device.
            if obj.isOpen == true
                fclose(obj.dev);
            end
        end

        function delete(obj)
        % Delete - deletes the object.
            if obj.isOpen
                obj.close();
            end
            delete(obj.dev);
        end

        function isOpen = get.isOpen(obj)
        % get.isOpen - returns true/false depending on whether the connection
        % to the device is open.
            status = get(obj.dev,'status');
            if strcmpi(status,'open')
                isOpen = true;
            else
                isOpen = false;
            end
        end

        function deviceInfoStruct = getDeviceInfo(obj)
        % getDeviceInfo - returns device information
            deviceInfoStruct = obj.sendRequest(obj.methodIdGetDeviceInfo);
        end

        function getMethods(obj)
        % getMethods - prints all dynamically generated class methods.
            methodIdNames = fieldnames(obj.methodIdStruct);
            fprintf('\n');
            fprintf('Modular Device Methods\n');
            fprintf('---------------------\n');
            for i = 1:length(methodIdNames)
                fprintf('%s\n',methodIdNames{i});
            end
        end

        function methodIds = get.methodIds(obj)
        % get.methodIds - returns the structure of method Ids.
            methodIds = obj.methodIdStruct;
        end

        function responseCodes = get.responseCodes(obj)
        % get.responseCodes - returns the structure of device response codes.
            responseCodes = obj.responseCodeStruct;
        end

        function varargout = subsref(obj,S)
        % subsref - overloaded subsref function to enable dynamic generation of
        % class methods from the methodIdStruct structure.
            val = [];
            if obj.isDynamicMethod(S)
                val = obj.dynamicMethodFcn(S);
            else
                if nargout == 0
                    builtin('subsref',obj,S);
                else
                    val = builtin('subsref',obj,S);
                end
            end
            if ~isempty(val)
                varargout = {val};
            end
        end


        function responseStruct = sendRequest(obj,methodId,varargin)
        % sendRequest - sends a request to the device and reads the device's response.
        % The device responds to all requests with a serialized json string.
        % This string is parsed into a Matlab structure.
        %
        % Arguments:
        %  methodId = the Id number of the method
        %  varagin  = any additional arguments required by the request
            if obj.isOpen

                % Send request to device
                request = obj.createRequest(methodId, varargin);
                if obj.debug
                    fprintf('request: ');
                    fprintf('%c',request);
                    fprintf('\n');
                end
                fprintf(obj.dev,request);

                % Get response as json string and parse
                response = fscanf(obj.dev,'%c');
                if obj.debug
                    fprintf('response: ');
                    fprintf('%c',response);
                    fprintf('\n');
                end

                try
                    responseStruct = loadjson(response);
                catch ME
                    causeME = MException( ...
                        'ModularDevice:unableToParseJSON', ...
                        'Unable to parse device response' ...
                        );
                    ME = addCause(ME, causeME);
                    rethrow(ME);
                end

                % Check the returned method Id
                try
                    responseMethodId = responseStruct.method_id;
                    responseStruct = rmfield(responseStruct, 'method_id');
                catch ME
                    causeME = MException( ...
                        'ModularDevice:MissingMethodId', ...
                        'device response does not contain method_id' ...
                        );
                    ME = addCause(ME, causeME);
                    rethrow(ME);
                end

                if responseMethodId ~= methodId
                    msg = sprintf( ...
                        'method_id returned, %d, does not match that sent, %d', ...
                        responseMethodId, ...
                        methodId ...
                        );
                    ME = MException('ModularDevice:methodIdDoesNotMatch', msg);
                    throw(ME);
                end


                % Get response status
                try
                    responseStatus = responseStruct.status;
                    responseStruct = rmfield(responseStruct,'status');
                catch ME
                    causeME = MException( ...
                        'ModularDevice:MissingStatus', ...
                        'Device response does not contain status' ...
                        );
                    ME = addCause(ME, causeME);
                    rethrow(ME);
                end

                % Check response status
                if ~isempty(obj.responseCodeStruct)
                    if responseStatus ~= obj.responseCodeStruct.response_success
                        errMsg = 'device responded with error';
                        try
                            errMsg = sprintf('%s, %s',errMsg, responseStruct.error_message);
                        catch ME
                            errMsg = sprintf('%s, but error message is missing', errMsg);
                        end
                        ME = MException('ModularDevice:DeviceResponseError', errMsg);
                        throw(ME);
                    end
                end

            else
                ME = MException( ...
                    'ModularDevice:DeviceNotOpen', ...
                    'connection must be open to send method to device' ...
                    );
                throw(ME);
            end
        end

    end

    methods (Access=private)

        function request = createRequest(obj, methodId, requestArgs)
        % createRequest - create a request for sending to the device given
        % the methodId and a cell array of the request arguments.
            request = sprintf('[%d',uint16(methodId));
            for i=1:length(requestArgs)
                arg = requestArgs{i};
                switch class(arg)
                  case 'double'
                    request = sprintf('%s, %f', request, arg);
                  case 'char'
                    request = sprintf('%s, %s', request, arg);
                  otherwise
                    errMsg = sprintf('unknown type, %s, in method', class(arg));
                    ME = MException('ModularDevice:UnknownType', errMsg);
                    throw(ME);
                end
            end
            request = sprintf('%s]',request);
        end

        function flag = isDynamicMethod(obj,S)
        % isDynamicMethod - used in the subsred function to determine whether
        % or not the method is dynamically generated. This is determined by
        % whether or not the name of the method given method is also the name
        % of a field in the methodIdStruct.
        %
        % Arguments:
        %  S = 'type' + 'subs' stucture passed to subsref function
            flag = false;
            if ~isempty(obj.methodIdStruct)
                if S(1).type == '.' & isfield(obj.methodIdStruct,S(1).subs)
                    flag= true;
                end
            end
        end

        function rtnVal = dynamicMethodFcn(obj,S)
        % dynamicMethodFcn - implements a the dynamically generated class methods.

        % Get method name, method args and method id number
            methodName = S(1).subs;
            try
                requestArgs = S(2).subs;
            catch
                requestArgs = {};
            end
            methodId = obj.methodIdStruct.(methodName);

            % Convert method arguments from structure if required
            %if length(requestArgs) == 1 && strcmp(class(requestArgs{1}), 'struct')
            %    requestArgs = obj.convertArgStructToCell(requestArgs{1});
            %end

            % Send method and get response
            responseStruct = obj.sendRequest(methodId,requestArgs{:});

            % Convert response into return value.
            responseFieldNames = fieldnames(responseStruct);
            if length(responseFieldNames) == 0
                rtnVal = [];
            elseif length(responseFieldNames) == 1;
                rtnVal = responseStruct.(responseFieldNames{1});
            else
                emptyFlag = true;
                for i = 1:length(responseFieldNames)
                    name = responseFieldNames{i};
                    value = responseStruct.(name);
                    if ~isempty(value)
                        emptyFlag = false;
                    end
                end
                % Return structure or if only fieldnames return cell array of fieldnames
                if ~emptyFlag
                    rtnVal = responseStruct;
                else
                    rtnVal = responseFieldNames;
                    for i = 1:length(rtnVal)
                        name = rtnVal{i};
                        % Convert '-' character back to human readable
                        if strcmp(name, 'x0x2D_')
                            rtnVal{i} = '-';
                        end
                        % Convert '+' character back to human readable
                        if strcmp(name, 'x0x2B_');
                            rtnVal{i} = '+';
                        end
                    end
                end
            end
        end

        function createMethodIdStruct(obj)
        % createMethodIdStruct - gets structure of method Ids from device.
            obj.methodIdStruct = obj.sendRequest(obj.methodIdGetMethods);
        end

        function createResponseCodeStruct(obj)
        % createResponseCodeStruct - gets structure of response codes from the device.
            obj.responseCodeStruct = obj.sendRequest(obj.methodIdGetResponseCodes);
        end

    end
end

% Utility functions
% -----------------------------------------------------------------------------
function flag = isCellEqual(cellArray1, cellArray2)
% Tests whether or not two cell arrays of strings are eqaul.
% Returns false if both cell array don't consist entirely of strings
    flag = true;
    for i = 1:length(cellArray1)
        string = cellArray1{i};
        if ~isInCell(string,cellArray2)
            flag = false;
        end
    end
end


function flag = isInCell(string, cellArray)
% Test whether or not the given string is in the given cellArray.
    flag = false;
    if strcmp(class(string), 'char')
        for i = 1:length(cellArray)
            if strcmp(class(cellArray{i}),'char') && strcmp(cellArray{i}, string)
                flag = true;
                break;
            end
        end
    end
end
