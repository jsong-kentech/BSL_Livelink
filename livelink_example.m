clc; clear; close all;

% COMSOL 클래스 가져오기
import com.comsol.model.* % COMSOL 모델 처리를 위한 기본 클래스 가져오기
import com.comsol.model.util.* % COMSOL API에서 제공하는 유틸리티 클래스 가져오기


%% Inputs

% 파일 경로 생성
COM_filepath = 'G:\공유 드라이브\Battery Software Lab\Models\COMSOL\pack_example'; % COMSOL 모델 파일 경로
COM_filename = 'pack_1205_1cell.mph'; % COMSOL 모델 파일 이름
COM_fullfile = fullfile(COM_filepath, COM_filename); % 전체 파일 경로 생성

% COMSOL 모델 로드
model = mphload(COM_fullfile);
ModelUtil.showProgress(true); % 진행률 표시 모드 활성화

% COMSOL Navigator 열기
mphnavigator;

% 다양한 C_rate 및 D_out 값에 대한 루프 실행
C_rate_vec = [0.6 1 2.2 4.6];%[0.2:0.4:2, 2.2:0.8:6.6];
N = length(C_rate_vec);
D_out_vec = [18 22 46];%[18:4:46, 50:8:80];
M = length(D_out_vec);

raw_data = table();
Tmax_mat = zeros(N,M);
idx = 0;

C_rate_plot = [0.6 1 2.2 4.6];
D_out_plot = [18 22 46];

for n = 1:N
    for m = 1:M

        try % 루프내 에러 발생시 전체 종료를 막기위함
            tic1 = tic;

            % COMSOL 모델 내 파라미터 값 설정 (네비게이터 창 사용)
            model.param.set('C_rate', C_rate_vec(n));
            model.param.set('d_batt', [num2str(D_out_vec(m)) '[mm]']); % 필요시 스트링으로 단위 입력 (수식도 입력 가능)

            % COMSOL 스터디 실행
            model.study('std1').run;

            % 시뮬레이션 결과 추출
            [T_max, Time, SOC] = mphglobal(model, {'T_max', 't', 'SOC'}, 'unit', {'degC', 'hour', '1'});

            % 결과를 테이블에 저장
            idx = idx + 1;
            raw_data(idx, :) = {C_rate_vec(n), D_out_vec(m), T_max, Time, SOC};

            % 컨투어 결과 플랏 용 매트릭스 생성
            Tmax_mat(n,m) = max(T_max);
         

            % 결과: 서브 플랏
            if ismember(C_rate_vec(n),C_rate_plot) && ismember(D_out_vec(m),D_out_plot)
                [~,M_plot] = ismember(D_out_vec(m),D_out_plot);
                figure(1)
                subplot(1,length(D_out_plot),M_plot)
                plot(SOC,T_max,'linewidth',2); hold on;
                title(['Diameter = ', num2str(D_out_vec(m))]);
                xlabel('SOC (1)');
                ylabel('Temperature (degC)');
                ylim([20 50])
                legend(cellstr(string(C_rate_plot)))

            end

            % 시뮬레이션 경과 표시
            t_cal = toc(tic1); 
            fprintf('Case done; the last case took %3.1f seconds. Completed %u out of %u cases (%3.1f%%). \n',...
            t_cal,(n-1)*M + m,N*M,round(100*((n-1)*M + m)/(N*M)))


        catch % 루프내 에러 발생시 아래 조건 실행
            continue % 스킵
        end
    end
end

% close the COMSOL model
ModelUtil.clear

raw_data.Properties.VariableNames = {'C_rate', 'Diameter', 'T_max', 'Time', 'SOC'};

% 누적된 데이터를 MAT 파일로 저장
save('Result', 'raw_data');


% 결과2: 컨투어
figure(2)
contourf(D_out_vec,C_rate_vec,Tmax_mat,10); hold on
title('T_{max}(Crate,Dout)')
xlabel('Dout (mm)')
ylabel('Crate (C)')
h = colorbar;
ylabel(h, 'T_{max} [degC]')
