clear all
close all

filter_list = {'heat','high','normal'};
for filter_type_cell = filter_list
    filter_type = string(filter_type_cell);
    disp(filter_type);
    for k=3:2:7 
        % load sample data
        load(['samples_' num2str(k*10) '_heat.mat']);
        load(['Ls_' num2str(k*10) '.mat']);
        % init results matrix
        As_GSI_est = zeros(size(Ls));
        Ls_GSI_est = zeros(size(Ls));

        % iterate over 20 graphs in each category (i.e., 30, 50, 70)
        for i=1:size(Ls,1)
            samples_sq = squeeze(double(Ls(i,:,:)));  

            % sample covariance
            S = cov(samples_sq,1);

            % initializaions
            if strcmp(filter_type,'heat')
                beta = 0.1;
            elseif  strcmp(filter_type,'high')
                beta = 0.5;
                
            else 
                beta = 0.5;
 
            end 
            
            %beta = 0.5; % filter parameter
            graph_filter_ideal = @(x)(graph_filter_fwd(x,beta,filter_type) );
            [U,sigma_sq_C] = createBasis(S,'descend');
            max_sigma=(max(sigma_sq_C));
            sigma_orig = sigma_sq_C/max_sigma;

            % step I: prefilter
            sigma_sq_C = sigma_sq_C/max_sigma; sigma_sq_C(sigma_sq_C <= 10^-10) = 0;
            lambdas_current = graph_filter_inv(sigma_sq_C,beta,filter_type);
            orig_sigmas = 1./lambdas_current; orig_sigmas(orig_sigmas==Inf)=0;
            S_prefiltered = U * diag(orig_sigmas) * U';

            % step II: graph learning 
            Laplacian = estimate_cgl(S_prefiltered,ones(size(S_prefiltered)),0.000,10^-5,10^-7,40);

            % step III: filter parameter estimation (for a desired filter type a filter parameter selection step)
            %  Note: for exponential filter filter parameter selection step can be skipped, 
            %        becayse the output graphs are scaled versions of eachother for different beta parameter
            %        please refer to the paper for further details

            % show resulting graph on the US map
            % draw_us_temp_graph(Laplacian, center_vector);
            As_GSI_est(i,:,:) = laplacianToAdjacency(Laplacian,0.000);
            Ls_GSI_est(i,:,:) = Laplacian;
        end 
        
        % save resutls
        if strcmp(filter_type,'heat')
            save(['mat_files/As_' num2str(k*10) '_' 'heatkernel_GSI_res.mat'], 'As_GSI_est');
            save(['mat_files/Ls_' num2str(k*10) '_' 'heatkernel_GSI_res.mat'], 'Ls_GSI_est');

        elseif strcmp(filter_type,'high')
            save(['mat_files/As_' num2str(k*10) '_' 'highkernel_GSI_res.mat'], 'As_GSI_est');
            save(['mat_files/Ls_' num2str(k*10) '_' 'highkernel_GSI_res.mat'], 'Ls_GSI_est');
        
        elseif strcmp(filter_type,'normal')
            save(['mat_files/As_' num2str(k*10) '_' 'normalkernel_GSI_res.mat'], 'As_GSI_est');
            save(['mat_files/Ls_' num2str(k*10) '_' 'normalkernel_GSI_res.mat'], 'Ls_GSI_est');
        else
            error('Error: graph_filter_fwd wrong filter_type');
            
        end 
    end
end


