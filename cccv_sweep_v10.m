%% INTRODUCTION

%{
V10:
    (1) using v10 version of COMSOL model
         -> dset1
%}
%{
V8b:
    (1) using V8b version of Comsol model
    (2) fprintf begore and after each calculation.
%}
%{
V2: 
    (0) Using V8 versions of COMSOL model - done
    (1) Evaluate more parameters (thickness, ...) - done
    (2) Record more variables (t_cal, ...) - done
    (3) Save every 'n' - done
    (4) fprintf more variables (N_unitcell and Prate) - done
    
%}
%{
    If change the working folder
    update COM_filepath

    If to change the variables, 
    1. variable names,
    2. mphglobal: output
    3. stacked data: input

%}


clear;clc;close all
import com.comsol.model.*
import com.comsol.model.util.*
%% 1. DEFINE SWEEPING PARAMETERS

N_unitcell_vec = [60:2:120,125:5:195,200:10:300];
        % other methods: (1) define anode thickness and correct for making
        % integer, (2) log-spaced N_cell_vec, corrected for integer.
C_3D_vec = [0.5:0.05:1,1.1:0.1:2,2.2:0.2:4,4.5:0.5:12];

% N_unitcell_vec = [60,120];
% C_3D_vec = [1,2,4];

N=length(N_unitcell_vec);
M=length(C_3D_vec);

%% 2. PREDEFINE OUTPUT FORMAT

% define variables to be evaluated.
variable_names ={'N_unitcell','n_delta','C_3D','t'... %**v2
            'cccv_t_cc','cccv_t_cv','cccv_t_end',...
            'cccv_f_cv','cccv_f_soc','cccv_f_imin',...
            'cccv_soc1','cccv_soc2','cccv_soc3',...
            'cccv_Elp1','cccv_Elp2','cccv_Elp3',...
            'cccv_Tmax1','cccv_Tmax2','cccv_Tmax3'};
    K = length(variable_names);
    
% unstacked form
data = struct();
for k = 1:K
    data.(variable_names{k})= NaN(N,M);
end
    % additional variable structure %**v2
    data.t_cal = NaN(N,M);
    
    
% stacked form
data_stacked = NaN(N*M,K+1); %**v2
    % additional variable for 'K+1'

%% 3. RUN COMSOL MODEL

% define the COMSOL model to be solved.
COM_filepath = 'C:\Users\j.song\Box Sync\JSong_Personal\COMSOL\Cell_Models\H3D Model\v10s';
COM_filename = 'ANL_cell_H3D_V10_cccv_matlab.mph';
COM_fullfile = fullfile(COM_filepath,COM_filename);


% load the COMSOL model.
model = mphload(COM_fullfile);
% diagnose
ModelUtil.showProgress(true);

% v8b_1mm  <-- this was set in the mph model
% model.param.set('delta_hcon','1[mm]');

tic1 =tic;
for n = 1:N
    for m =1:M

                fprintf('Current case: %u / %u and %u / %u. \n',...
                n,N,m,M)
        
        tic2 = tic;
        
        % set parameter values
        model.param.set('N_unitcell',N_unitcell_vec(n));
        model.param.set('C_3D',C_3D_vec(m));
        % run the model (solution)

        model.sol('sol7').run;
            t_cal = toc(tic2); % calculation time %**v2
            
        % record the results unstacked form

        [data.N_unitcell(n,m),data.n_delta(n,m),data.C_3D(n,m),data.t(n,m),... %**v2
        data.cccv_t_cc(n,m),data.cccv_t_cv(n,m),data.cccv_t_end(n,m),...
        data.cccv_f_cv(n,m),data.cccv_f_soc(n,m),data.cccv_f_imin(n,m),...
        data.cccv_soc1(n,m),data.cccv_soc2(n,m),data.cccv_soc3(n,m),...
        data.cccv_Elp1(n,m),data.cccv_Elp2(n,m),data.cccv_Elp3(n,m),...
        data.cccv_Tmax1(n,m),data.cccv_Tmax2(n,m),data.cccv_Tmax3(n,m)]... 
                 = mphglobal(model,variable_names,'dataset','dset1','solnum','end');
        data.t_cal(n,m) = t_cal; % additional variable %**v2

        % record the results in stacked form
        data_stacked((n-1)*M + m,:)=...
            [data.N_unitcell(n,m),data.n_delta(n,m),data.C_3D(n,m),data.t(n,m),... %**v2
            data.cccv_t_cc(n,m),data.cccv_t_cv(n,m),data.cccv_t_end(n,m),...
            data.cccv_f_cv(n,m),data.cccv_f_soc(n,m),data.cccv_f_imin(n,m),...
            data.cccv_soc1(n,m),data.cccv_soc2(n,m),data.cccv_soc3(n,m),...
            data.cccv_Elp1(n,m),data.cccv_Elp2(n,m),data.cccv_Elp3(n,m),...
            data.cccv_Tmax1(n,m),data.cccv_Tmax2(n,m),data.cccv_Tmax3(n,m),...
            data.t_cal(n,m)]; % last row: additional variable  %**v2 
        
        % output update %**v2 
        fprintf('Done; took %3.1f seconds. Completed %u out of %u cases (%3.1f%%). \n',...
            t_cal,(n-1)*M + m,N*M,round(100*((n-1)*M + m)/(N*M)))
        
    end
        % save every n %**v2 
    save('matlabsweepresult_cccv_v10','data','data_stacked')
    fprintf('\n\n    Data are saved up to n = %u.\n',n)
    fprintf('    Total calculation time up to now is %5.1f sec (%4.3f hr). \n\n\n',toc(tic1),toc(tic1)/3600)
    
    
end

t_total=toc(tic1);
fprintf('\n\n\n\nTotal calculation time is %4.3f hours.\n\n',t_total/3600)



% close the COMSOL model
ModelUtil.clear
