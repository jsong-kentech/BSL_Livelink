clear;clc;close all
% Initiate comsol
import com.comsol.model.*
import com.comsol.model.util.*



%% Inputs

COM_filepath = 'D:\Leejh\1. KENTECH\1. Modeling\MATLAB\Cell';
COM_filename = 'LJH_Fast_Charging_Tubular_Cell_Final_231024.mph';
% COM_filename = 'LJH_Fast_Charging_Cylinder_Cell_230718.mph'; % Cylinder
COM_fullfile = fullfile(COM_filepath,COM_filename);

result_filename = 'Tubular_Sweep_Crate_Rout_Result.mat';
%result_filename = 'Cylinder_Sweep_Crate_Rout_Result.mat';


model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

mphnavigator;



%% Sweep

C_rate_vec = 1:12; % [1:0.2:12]; 
D_out_vec = 10:5:80; % 
N= length(C_rate_vec);
M= length(D_out_vec);

% Secure memory
T_max = zeros(N,M);
E_lp_min = zeros(N,M);
SOC =cell(N,M);
t = cell(N,M);
t95 = zeros(N,M);

tic1 =tic; % begin time  for entire sweep

for i = 1:N

    C_rate = C_rate_vec(i);

    for j = 1:M

        D_out = D_out_vec(j);

        % Display calculation status
        fprintf('Current case: %u / %u and %u / %u. \n',...
                i,N,j,M)
        
        tic2 = tic; % begin time  for each case


        % Parameter setting in .mph

        model.param.set('C_rate',C_rate);    % ** check name in comsol
        model.param.set('D_out', D_out);   % ** check name in comsol

        % Run mph model
        model.study('std1').run   % ** check name in comsol
        t_cal = toc(tic2); % end time  for each case
 

        % Extract results
            % ** check if we are getting entire vector or the last value
            % we need: E_lp (comp1 variable), T_max (comp2 variable) 
            % SOC (comp1 variable), t (comp1 variable)
            [T_max(i,j), E_lp_min(i,j)] = mphglobal('model',{'comp2.T_max','comp1.E_lp_min'});
            SOC{i,j} = mphglobal('model','comp1.soc');
            t{i,j} = mphglobal('model','t');
            % ** check name in comsol

        % Calculate charging times
            t95(i,j) = interp1(SOC{i,j},t{i,j},0.95);


        % output update  
        fprintf('Done; the last case took %3.1f seconds. Completed %u out of %u cases (%3.1f%%). \n',...
            t_cal,(i-1)*M + j,N*M,round(100*((i-1)*M + j)/(N*M)))


    end

end

% Save file
save(result_filename,'data','T_max','E_lp_min','SOC','t','t95')

t_total=toc(tic1);
fprintf('\n\n\n\nTotal calculation time is %4.3f hours.\n\n',t_total/3600)


