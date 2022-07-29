function [PS, SD] = seed_curv(PS, SD)

    % this produces a heatmap of successful seeding distribution on the surface
    % by finding the vertex closest to each seed then calculating seed count per verte    
    % similar principle as GG filter but not imposing proximity restraints
    
    if PS.dgn && isempty(PS.noseed) 
        
        out_dir = [PS.work_dir filesep 'surf_data'];
        if ~exist(out_dir,'dir')
            mkdir(out_dir);
        end
        
        surffile.rh = [out_dir filesep 'rh.seeds'];
        surffile.lh = [out_dir filesep 'lh.seeds'];
        
        if ~exist(surffile.rh,'file') || ~exist(surffile.lh,'file') || PS.force
            
            verb_msg('Projecting seeds on the white matter surface', PS)
            
            % get the seeds
            seeds_all = process_coords(SD.DWI.seed_coords_file_out);
            
            % cluster the white mesh coordinates
            wsm_clustering = coordinate_clustering(SD.DWI.cv, size(seeds_all, 1));
            
            % find closest vertex
            gg_idx = find_closest_vertex(SD.DWI.cv, seeds_all, wsm_clustering);
       
            % restore within-hemisphere indexation
            hh_idx = SD.DWI.cvh(gg_idx);          
            gg_idx = SD.DWI.cvi(gg_idx);
            
            % record hemisphere-wise results
            seeds.rh = gg_idx(~hh_idx);
            seeds.lh = gg_idx(hh_idx);
            total_count = 0;
            
            for hemi = {'rh' 'lh'}
                
                % find how many times each has been used
                [uv_idx, ~, uv_p] = unique(seeds.(hemi{1}));
                uv_c = accumarray(uv_p, 1);
                cvc = zeros(SD.DWI.(hemi{1}).nverts, 1, 'uint32');
                cvc(uv_idx) = uv_c;
                total_count = numel(uv_idx) + total_count;
                write_curv(surffile.(hemi{1}), cvc, SD.DWI.(hemi{1}).nfaces);
                SD.DWI.(hemi{1}).seeds = logical(cvc);
                
            end
            
            PS.logt(end+1,:) = {'Cortical seed density (%):' round(total_count / ...
                sum([SD.DWI.rh.usedv(:); SD.DWI.lh.usedv(:)]) * 100, 2)};           

         end
    end 
end