%% real data generation
% you need to have a .mat file containing the data from the MS table
visibility_file_name = {'CYG-2G.mat'}; %{'CYG-2G.mat', 'CYG-3G.mat', 'CYG-5G.mat'}; 
param_real_data.image_size_Nx = 1024; % number of pixels in x axis
param_real_data.image_size_Ny = 512; % number of pixels in y axis

% param_real_data.use_shift = 0;
% param_real_data.shift_position = 1.5*[1/512 ; -1/512];
% param_real_data.use_undersamplig = 0;
% param_real_data.p = 0.7672*4;
% param_real_data.fu_undersampling_type = 'uniform'; % 'uniform', 'gaussian', 'general-gaussian'
% param_real_data.fu_g_sigma = pi/4; % variance of the gaussion over continous frequency
% param_real_data.fu_ggd_beta = pi/4; % scale parameter for ggd
% param_real_data.fu_ggd_rho = 0.07; % shape parameter for ggd

%% config parameters
Nx = param_real_data.image_size_Nx;
Ny = param_real_data.image_size_Ny;
N = Nx * Ny;

ox = 2; % oversampling factors for nufft
oy = 2; % oversampling factors for nufft
Kx = 8; % number of neighbours for nufft
Ky = 8; % number of neighbours for nufft

%% preconditioning parameters
param_precond.N = N; % number of pixels in the image
param_precond.Nox = ox*Nx; % number of pixels in the image
param_precond.Noy = oy*Ny; % number of pixels in the image
param_precond.gen_uniform_weight_matrix = 1; %set weighting type
param_precond.uniform_weight_sub_pixels = 1;

%% block structure

regenerate_block_structure = 1;

param_block_structure.use_density_partitioning = 0;
param_block_structure.density_partitioning_no = 1;

param_block_structure.use_uniform_partitioning = 0;
param_block_structure.uniform_partitioning_no = 4;

param_block_structure.use_equal_partitioning = 0;
param_block_structure.equal_partitioning_no = 1;

param_block_structure.use_manual_frequency_partitioning = 0;
% sparam.fpartition = [pi]; % partition (symetrically) of the data to nodes (frequency ranges)
% sparam.fpartition = [0, pi]; % partition (symetrically) of the data to nodes (frequency ranges)
% sparam.fpartition = [-0.25*pi, 0, 0.25*pi, pi]; % partition (symetrically) of the data to nodes (frequency ranges)
% sparam.fpartition = [-64/256*pi, 0, 64/256*pi, pi]; % partition (symetrically) of the data to nodes (frequency ranges)
param_block_structure.fpartition = [icdf('norm', 0.25, 0, pi/4), 0, icdf('norm', 0.75, 0, pi/4), pi]; % partition (symetrically) of the data to nodes (frequency ranges)
% sparam.fpartition = [-0.3*pi, -0.15*pi, 0, 0.15*pi, 0.3*pi, pi]; % partition (symetrically) of the data to nodes (frequency ranges)
% sparam.fpartition = [-0.35*pi, -0.25*pi, -0.15*pi, 0, 0.15*pi, 0.25*pi, 0.35*pi, pi]; % partition (symetrically) of the data to nodes (frequency ranges)

param_block_structure.use_manual_partitioning = 1;

%% load real_data;
[y, uw, vw, nWw, f, time_, pos, pixel_size] = util_load_real_vis_data(visibility_file_name, param_real_data);

figure(1),
for i = size(y,1)
    scatter(uw{i},vw{i},'.');hold on;
end


%%
ch = [1 : size(y,2)]; % number of channels loaded (note that this can be one).

for i = ch
    
    i
    
    %% compute weights
    [aWw] = util_gen_preconditioning_matrix(uw{i}, vw{i}, param_precond);
    
    % set the blocks structure
    if param_block_structure.use_manual_partitioning == 1
        param_block.size = 200000; 60000; % length(uw{i});  % number of visibilities in each data block on average
        param_block.snapshot = 0;
        param_block.pos = pos{i};
        out_block = util_time_based_block_sp_ar(uw{i},time_{i},param_block);
        partition = out_block.partition;
        param_block_structure.partition = partition;
    end
    
    % set the blocks structure
    [u, v, ~, uvidx, aW{i}, nW] = util_gen_block_structure(uw{i}, vw{i}, aWw, nWw{i}, param_block_structure);
    
    % measurement operator initialization
    fprintf('Initializing the NUFFT operator\n\n');
    tstart = tic;
   
    %     for k = 1 : length(nW)
    %         nW{k} = ones(size(nW{k}));
    %     end
    
    [A, At, G{i}, W{i}, Gw{i}] = op_p_nufft([v u], [Ny Nx], [Ky Kx], [oy*Ny ox*Nx], [Ny/2 Nx/2], nW);
    
    yb{i} = cell(length(u),1);
    for j = 1 : length(u) 
        yb{i}{j} = y{i}(uvidx{j});
    end
    
end

%% Save data
if save_data
    save('./real_data/data/CYG_data.mat','-v7.3', 'G', 'W', 'aW', 'yb');
    save('./real_data/data/CYG_y.mat','-v7.3', 'y');
end

%%
if save_full_operator && exist('Gw','var')
    save('./real_data/data/CYG_Gw.mat','-v7.3', 'Gw');
end


%% Free memory
if free_memory
    clear y u v uv_mat uv_mat1 uvidx uw vw ant1 ant2 aWw nW nWw out_block;
end
