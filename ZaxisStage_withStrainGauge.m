if ~exist("s", "var") || ~isvalid(s)
    s = serialport("COM5", 9600);
    configureTerminator(s, "CR/LF");
    disp("s SETTING")
end

if ~exist("d", "var") || ~isvalid(d)
    d = daq("ni");
    addinput(d, "cDAQ1Mod1", "ai0", "Voltage");
    d.Rate = 5000;
end


target = 0.6;  % [V]
% //////////////////////////////
% alpha の算出
v_max = 500; %最大速度
e_max = 0.6; %誤差0.6VのときD:A500
v_min = 10;
e_min = 0.1; %誤差0.1VのときD:A10
% velocity = maxSpeed * exp(-alpha * (0.6 - abs(error)));より
alpha = -log(v_min / v_max) / (e_max - abs(e_min));
% //////////////////////////////

Command(s, "MGO:A1750");
pause(0.3)

% 段階ごとの誤差しきい値（高い方から順）
thresholds = [0.55, 0.35, 0.15, 0.05];
applied = false(size(thresholds));  % 各段階で速度変更したかどうか記録

cmd = sprintf("D:A%d,2000,10", v_max);
Command(s, cmd);
ResponseCommand(s, "D:AR");

Command(s, "JGO:A+");


while true
    data = read(d, seconds(0.01));
    current = mean(data.Variables);
    error = target + current;

    fprintf("Current Voltage: %.3f V\n", current);
    fprintf("Error: %.3f V\n", error);

    if error < 0.003
        Command(s, "L:A");
        fprintf("✅ 目標に到達：停止--------------------\n");
        fprintf("Voltage: %.3f V\n", current);
        break;
    end

    for i = 1:length(thresholds)
        if error <= thresholds(i) && ~applied(i)
            Command(s, "L:A");
            % ここで初めてこの段階に入ったときにだけ速度変更
            velocity = round(round(v_max * exp(-alpha * (0.6 - thresholds(i)))) / 10) * 10;
            velocity = min(max(velocity, v_min), v_max);

            cmd = sprintf("D:A%d,2000,400", velocity);
            Command(s, cmd);
            ResponseCommand(s, "D:AR");
            fprintf("error <= %.1f → 速度変更：%d\n", thresholds(i), velocity);

            applied(i) = true;  % この段階の速度変更済として記録
            % break;  % 一度に1段階だけ処理
        end
    end

    Command(s, "JGO:A+"); % 速度変更し、JOG移動
end
pause(2)
% Command(s, "MGO:A-1500");


ResponseCommand(s, "D:AR");


function waitForStop(s)
    while true
        writeline(s, "Q:A2");
        pause(0.2);
        if s.NumBytesAvailable > 0
            status = readline(s);
            if contains(status, "K")
                break;
            end
        end
    end
end

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
        pause(0.2);
        if s.NumBytesAvailable > 0
            status = readline(s);
            if contains(status, "K") || command == "JGO:A+"
                break;
            end
        end
    end
end
