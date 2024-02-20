clc; clear; close all;

% COMSOL 클래스 가져오기
import com.comsol.model.* % COMSOL 모델 처리를 위한 기본 클래스 가져오기
import com.comsol.model.util.* % COMSOL API에서 제공하는 유틸리티 클래스 가져오기

%% Inputs

% 파일 경로 생성
COM_filepath = 'G:\공유 드라이브\Battery Software Lab\Models\Pack_COMSOL'; % COMSOL 모델 파일 경로
COM_filename = 'Tubular pack_6.1.mph'; % COMSOL 모델 파일 이름
COM_fullfile = fullfile(COM_filepath, COM_filename); % 전체 파일 경로 생성

% COMSOL 모델 로드
model = mphload(COM_fullfile);
ModelUtil.showProgress(true); % 진행률 표시 모드 활성화

% COMSOL Navigator 열기
mphnavigator;


% 다양한 C_rate 및 D_in 값에 대한 루프 실행
data = table();
idx = 0;

for C_rate = 3.0:1:4.0
    for D_in = 0:1:2
        %try
            % COMSOL 모델의 매개변수 값 설정
            model.param.set('C_rate', C_rate);
            model.param.set('D_in', D_in);

            % COMSOL 스터디 실행
            model.study('std1').run;

            % 시뮬레이션 결과 추출
            [T_max, Time] = mphglobal(model, {'T_max', 't'}, 'unit', {'degC', 'hour'});

            % 결과를 테이블에 저장
            idx = idx + 1;
            data(idx, :) = {C_rate, 2 * D_in, T_max, Time};

            % Plot
            subplot(3, 3, (C_rate - 3) * 3 + D_in + 1);
            plot(Time, T_max, 'LineWidth', 2);
            title(['C-rate = ', num2str(C_rate), ', Diameter = ', num2str(2 * D_in)]);
            xlabel('Time (hr)');
            ylabel('Temperature (degC)');
            grid on;

        %catch
            % 오류가 발생하면 다음 반복으로 계속 진행
         %   continue;
        %end
    end
end

data.Properties.VariableNames = {'C_rate', 'Diameter', 'T_max', 'Time'};

% 누적된 데이터를 MAT 파일로 저장
save('Pack_Result', 'data');

