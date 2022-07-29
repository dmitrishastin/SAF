function SD = prepare_seeds(PS, SD)
    
    native_seeds = [PS.work_dir filesep 'WSM_coords.txt'];
    remeshed_seeds = [PS.work_dir filesep 'remeshed_seeds.txt'];    
    SD.DWI.sl_init = [PS.work_dir filesep 'surf_tracks.tck']; % tractography output file

    if PS.remesh_seeds && isempty(PS.noseed) && (~exist(SD.DWI.sl_init, 'file') || PS.force)
        
        if ~exist(remeshed_seeds, 'file') || PS.force

            output_seeds = [];

            % find edges
            E = @(F) [F(:, 1:2); F(:, 2:3); F(:, [3 1])];

            % calculate edge lengths
            L = @(E, V) sum((V(E(:, 1), :) - V(E(:, 2), :)) .^ 2, 2);

            if isa(PS.remesh_seeds, 'numeric')

                maxlen = PS.remesh_seeds;

            else            

                len = [];             
                for hemi = {'rh' 'lh'}

                    V = SD.DWI.(hemi{1}).white;
                    F = SD.DWI.(hemi{1}).faces;

                    len = [len; sqrt(L(E(F), V))];

                end            
                maxlen = mean(len) + std(len) * 3;
                verb_msg(['Edge length cut off for white surface remeshing (seed input): ' num2str(round(maxlen, 2))], PS);

            end

            % to save from repeating sqrt for L all the time
            maxlen = maxlen ^ 2;

            for hemi = {'rh' 'lh'}

                V = SD.DWI.(hemi{1}).white;
                F = SD.DWI.(hemi{1}).faces;   
                F(sum(ismember(F, find(~SD.DWI.(hemi{1}).usedv)), 2) > 1, :) = [];
                nv = size(V, 1); nf = size(F, 1);    

                edges = E(F);
                long_E = L(edges, V) > maxlen;

                while any(long_E)

                    % take the first long edge
                    le = edges(find(long_E, 1), :);

                    % find adjacent faces
                    f = sum(ismember(F, le), 2) > 1;

                    % find their other vertices
                    fx = F(f, :);
                    v3 = fx ~= le(1) & fx ~= le(2);
                    nn = sum(v3(:));

                    % new vertex in the middle
                    new_v = mean(V(le, :));            

                    % split the faces
                    v1_idx = mod(find(v3') - 1, 3) + 1;
                    vf_idx = mod(v1_idx, 3) + 1;
                    vr_idx = mod(v1_idx - 2, 3) + 1;

                    new_f = zeros(nn * 2, 3);
                    for i = 1:nn
                        new_f((i - 1) * 2 + 1:i * 2, :) = ...
                            [fx(i, [v1_idx(i) vf_idx(i)]), nv + 1; ...
                            nv + 1, fx(i, [vr_idx(i) v1_idx(i)])]; 
                    end

                    % update
                    edges = permute(reshape(edges, [nf 2 3]), [1 3 2]);
                    long_E = reshape(long_E, [nf 3]);

                    F(f, :) = [];

                    F = [F; new_f];
                    V = [V; new_v];
                    nf = size(F, 1); nv = nv + 1;

                    new_l = reshape(L(E(new_f), V) > maxlen, [nn * 2 3]);
                    new_e = permute(reshape(E(new_f), [nn * 2, 2, 3]), [1 3 2]);            
                    edges(f, :, :) = [];
                    edges = reshape(permute(cat(1, edges, new_e), [1 3 2]), [nf * 3 2]);
                    long_E(f, :) = [];
                    long_E = reshape([long_E; new_l], [nf * 3 1]);

                end

                output_seeds = [output_seeds; V];

            end
            
            SD.DWI.cv_white_coord_file = remeshed_seeds;
            convert_coords(output_seeds, SD.DWI.cv_white_coord_file);   
            
        else
            
            SD.DWI.cv_white_coord_file = remeshed_seeds;
            
            if ~PS.quiet
                output_seeds = process_coords(remeshed_seeds); 
            end
            
        end
        
        verb_msg(['Number of coordinates added for seeding: ' num2str(size(output_seeds, 1) - size(SD.DWI.cv, 1))], PS);
               
    else
        
        SD.DWI.cv_white_coord_file = native_seeds;
        
        if ~exist(native_seeds, 'file') || PS.force            
            convert_coords(SD.DWI.cv, SD.DWI.cv_white_coord_file);            
        end
            
    end
    
    SD.DWI.seed_coords_file_in = SD.DWI.cv_white_coord_file;
    
end
