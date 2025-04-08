% -------------------------
% PVDF計測制御付き 試行ループ (3回)
% -------------------------

% --- DAQ 設定 ----------------------------
% ひずみゲージDaq
if ~exist("daqStG", "var") || ~isvalid(daqStG)
    daqStG = daq("ni");
    addinput(daqStG, "cDAQ1Mod1", "ai0", "Voltage");
    daqStG.Rate = 5000;
    disp("daqStG SETTING")
end
% PVDFDaq
if ~exist("daqPVDF", "var") || ~isvalid(daqPVDF)
    daqPVDF = daq("ni");
    addinput(daqPVDF, "Dev2", "ai1", "Voltage");
    daqPVDF.Rate = 5000;
    duration = 1.0;  % 計測時間 [秒]
    numTrials = 3;
    disp("daqPVDF SETTING")
end

% --- シリアル通信ポート設定 ------------------
if ~exist("s_slider", "var") || ~isvalid(s_slider)
    s_slider = serialport("COM3", 9600);
    configureTerminator(s_slider, "CR/LF");
    disp("s_slider SETTING")
end
if ~exist("s_stage", "var") || ~isvalid(s_stage)
    s_stage = serialport("COM5", 9600);
    configureTerminator(s_stage, "CR/LF");
    disp("s_stage SETTING")
end


% --- システム制御 ---------------------------
% 初期設定
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

% 段階ごとの誤差しきい値（高い方から順）
thresholds = [0.55, 0.35, 0.15, 0.05];

cmd = sprintf("D:A%d,2000,400", v_max);
writeline(s_stage, cmd);
ResponseCommand(s_stage, "D:AR");





for trial = 1:numTrials
    fprintf("\n▶ 試行 %d 開始\n", trial);
    writeline(s_slider, "run 31");
    pause(2);
    
    % -----------------------
    % 1. 押しつけ力制御（z軸）
    % -----------------------
    disp("z軸ステージ上昇 → 所望の押しつけ力を制御中...");
    
    applied = false(size(thresholds));  % 各段階で速度変更したかどうか記録
    Command(s_stage, "MGO:A1750");
    pause(0.3)
    Command(s_stage, "JGO:A+");

    while true
        data = read(daqStG, seconds(0.01));
        current = mean(data.Variables);
        error = target + current;
    
        fprintf("Current Voltage: %.3f V\n", current);
        fprintf("Error: %.3f V\n", error);
    
        if error < 0.003
            Command(s_stage, "L:A");
            fprintf("✅ 目標に到達：停止--------------------\n");
            fprintf("Voltage: %.3f V\n", current);
            break;
        end
    
        for i = 1:length(thresholds)
            if error <= thresholds(i) && ~applied(i)
                Command(s_stage, "L:A");
                % ここで初めてこの段階に入ったときにだけ速度変更
                velocity = round(round(v_max * exp(-alpha * (0.6 - thresholds(i)))) / 10) * 10;
                velocity = min(max(velocity, v_min), v_max);
    
                cmd = sprintf("D:A%d,2000,400", velocity);
                Command(s_stage, cmd);
                ResponseCommand(s_stage, "D:AR");
                fprintf("error <= %.1f → 速度変更：%d\n", thresholds(i), velocity);
    
                applied(i) = true;  % この段階の速度変更済として記録
                % break;  % 一度に1段階だけ処理
            end
        end
    
        Command(s_stage, "JGO:A+"); % 速度変更し、JOG移動
    end


    % -----------------------
    % 2. PVDF計測の開始
    % -----------------------
    disp("PVDFセンサの計測開始");
    % 計測スタート
    start(daqPVDF, "Duration", seconds(duration));
    data = read(daqPVDF, seconds(duration));
    t = data.Time;
    v = data.Variables;

    % -----------------------
    % 3. スライダ動作（走査）
    % -----------------------
    disp("スライダ走査開始");
    writeline(s_slider, "run 29");

    % 1秒待つ（走査完了まで）
    pause(2.0);

    % -----------------------
    % 4. z軸ステージを下降
    % -----------------------
    disp("z軸ステージ下降");
    % ここで、下降動作
    Command(s_stage, "D:A500,9000,400");
    Command(s_stage, "AGO:A-2000");
    pause(1)
    

    % -----------------------
    % 5. スライダを初期位置へ
    % -----------------------
    disp("スライダ初期位置へ戻る");
    writeline(s_slider, "run 30");

    % ※データはまだ保存しません
    fprintf("✅ 試行 %d 終了\n", trial);
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
        pause(0.02);
        if s.NumBytesAvailable > 0
            status = readline(s);
            if contains(status, "K") || command == "JGO:A+"
                break;
            end
        end
    end
end


