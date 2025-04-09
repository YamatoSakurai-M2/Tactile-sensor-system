% if ~exist("s", "var") || ~isvalid(s)
%     s = serialport("COM3", 9600);
%     configureTerminator(s, "CR/LF");
%     disp("s SETTING")
% end
% 
% % //////////////////////////////
% 
% found = false;
% Command(s, "D:A1000,2000,40");
% ResponseCommand(s, "D:AR");
% writeline(s, "JGO:A+")
% 
% while ~found
%     data = read(d, seconds(0.1));
%     maxVoltage = min(data.Variables);
%     fprintf("Voltage: %.3f V\n", maxVoltage);
% 
%     if maxVoltage <= -0.05
%         found = true;
% 
%         Command(s, "L:A");
%         ResponseCommand(s, "Q:A1")
%     end
% end
% 
% % //////////////////////////////
% 
% 
% 
% 
% % writeline(s, "AGO:A5000");
% % waitForStop(s);
% % 
% % writeline(s, "AGO:A200");
% % waitForStop(s);
% % 
% % writeline(s, "AGO:A5000");
% % waitForStop(s);
% % writeline(s, "AGO :A0");
% 
% Command(s, "AGO:A5000");
% % ResponseCommand(s, "Q:A1");
% Command(s, "MGO:A-3000");
% % ResponseCommand(s, "Q:A1");
% Command(s, "MGO:A500");
% % ResponseCommand(s, "Q:A1");
% Command(s, "AGO:A-2000");
% % ResponseCommand(s, "Q:A1");
% Command(s, "H:A");
% 
% % 
% % writeline(s, "JGO:A+")
% % pause(2)
% % writeline(s, "L:A")
% % 
% % 
% % % writeline(s, "H:A")
% % waitForStop(s);
% 
% % writeline(s, "A:A5000");
% % writeline(s, "G:A");
% 
% 
% % CommandResponse(s, "D:AR")
% 
% 
% function waitForStop(s)
%     while true
%         writeline(s, "Q:A2");
%         pause(0.2);
%         if s.NumBytesAvailable > 0
%             status = readline(s);
%             if contains(status, "K")
%                 break;
%             end
%         end
%     end
% end
% 
% function ResponseCommand(s, command)
%     writeline(s, command)
%     pause(0.2)
% 
%     if s.NumBytesAvailable > 0
%         response = readline(s);
%         disp(response);
%     else
%         disp("No Response");
%     end
% end
% 
% function Command(s, command)
%     writeline(s, command)
%     while true
%         writeline(s, "Q:A2");
%         pause(0.2);
%         if s.NumBytesAvailable > 0
%             status = readline(s);
%             if contains(status, "K")
%                 break;
%             end
%         end
%     end
% end

% if ~exist("slider", "var") || ~isvalid(s)
%     slider = serialport("COM3", 9600);
%     configureTerminator(slider, "CR/LF");
%     disp("s SETTING")
% end
% 
% writeline(slider, "run 31");
% pause(2);
% writeline(slider, "run 29");
% pause(2);
% writeline(slider, "run 31");
% pause(2);
% writeline(slider, "run 29");
% pause(2);
% writeline(slider, "run 31");
% pause(2);
% writeline(slider, "run 29");
% pause(2);
% writeline(slider, "run 31");

% -------------------------------------------------
% --- シリアル通信ポート設定 ------------------
if ~exist("s_slider", "var") || ~isvalid(s_slider)
    s_slider = serialport("COM400", 9600);
    configureTerminator(s_slider, "CR/LF");
    disp("s_slider SETTING")
end
if ~exist("s", "var") || ~isvalid(s)
    s = serialport("COM3", 9600);
    configureTerminator(s, "CR/LF");
    disp("s SETTING")
end


% Command(s, "MGO:A1750");
writeline(s, "MGO:A1750")




function ResponseCommand(s, command)
    writeline(s, command)
    pause(0.2)

    if s.NumBytesAvailable > 0
        response = readline(s);
        disp(response);
    else
        disp("No Response");
    end
end

function Command(s, command)
    writeline(s, command)
    while true
        writeline(s, "Q:A2");
        pause(0.02);
        if s.NumBytesAvailable > 0
            status = readline(s);
            if contains(status, "K") || command == "JGO:A+"
                break;
            end
        end
    end
end


