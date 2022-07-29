classdef storage_class
   
    properties
        
        T1
        DWI        
        tx
        
    end
    
    methods
        
        % populate
        function this = storage_class(PS)
            
            [this.T1, this.DWI]     = deal(modality_class(PS));            

            this.T1.rh.pial_file    = [PS.fs_dir filesep 'surf' filesep 'rh.pial'];
            this.T1.rh.white_file   = [PS.fs_dir filesep 'surf' filesep 'rh.white'];                
            this.T1.rh.infl_file    = [PS.fs_dir filesep 'surf' filesep 'rh.inflated'];
            this.T1.rh.sph_file     = [PS.fs_dir filesep 'surf' filesep 'rh.sphere'];
            this.T1.rh.curv_file    = [PS.fs_dir filesep 'surf' filesep 'rh.curv'];
            
            this.T1.lh.pial_file    = [PS.fs_dir filesep 'surf' filesep 'lh.pial'];
            this.T1.lh.white_file   = [PS.fs_dir filesep 'surf' filesep 'lh.white'];                
            this.T1.lh.infl_file    = [PS.fs_dir filesep 'surf' filesep 'lh.inflated'];
            this.T1.lh.sph_file     = [PS.fs_dir filesep 'surf' filesep 'lh.sphere'];
            this.T1.lh.curv_file    = [PS.fs_dir filesep 'surf' filesep 'lh.curv'];
            
            this.tx = tx_class(PS);
            
        end        
        
        % transform vertex coordinates from T1 to DWI space
        function this = tx_coords(surf, this, PS)            
            
            if ~PS.noregister              
                for hemi = {'rh', 'lh'} 
                    
                    if ~isempty(this.T1.(hemi{1}).(surf))

                        in_name = [PS.work_dir filesep 'T1_' hemi{1} '_' surf '.csv'];
                        out_name = [PS.work_dir filesep 'DWI_' hemi{1} '_' surf '.csv'];

                        if ~exist(out_name, 'file') || PS.force

                            % writes T1 coordinates to disk if doesn't exist
                            if ~exist(in_name, 'file')
                                convert_coords(this.T1.(hemi{1}).(surf), in_name);
                            end

                            % performs actual transformation
                            verb_msg('Transforming coordinates to DWI space', PS)
                            
                            if ~isempty(this.tx.warp)
                                command1 = ['antsApplyTransformsToPoints -d 3 -p 1 -i ' in_name ' -o ' out_name ' -t ' this.tx.warp ' -t ' this.tx.affine];
                            elseif ~isempty(this.tx.affine)
                                command1 = ['antsApplyTransformsToPoints -d 3 -p 1 -i ' in_name ' -o ' out_name ' -t ' this.tx.affine];
                            else
                                error('no registration info available')
                            end
                            sys_exec(command1, PS);

                        end

                        % converts to .txt if needed
                        [dr,nm,ext] = Supp_gz_fileparts(out_name);
                        if strcmp(ext,'.csv')

                            out_name = [dr filesep nm '.txt'];
                            convert_coords([out_name(1:end-3) 'csv'], out_name);

                        end

                        % updates this class file
                        this.T1.(hemi{1}).([surf '_coord_file']) = in_name;
                        this.DWI.(hemi{1}).([surf '_coord_file']) = out_name;
                        this.DWI.(hemi{1}).(surf) = process_coords(out_name);
                        this.T1.(hemi{1}).(surf) = []; % clear T1 coords from memory

                        % saves coordinates in format which can be visualised in mrview
                        if PS.dgn
                            pts_to_tck(out_name,[dr filesep nm '.tck']);
                        end
                    end
                end            
            else  
                for hemi = {'rh', 'lh'}   
                    
                    this.DWI.(hemi{1}).(surf) = this.T1.(hemi{1}).(surf);
                    this.T1.(hemi{1}).(surf) = [];

                    if PS.dgn
                        coord_file = [PS.work_dir filesep 'DWI_' hemi{1} '_' surf '.txt'];
                        this.DWI.(hemi{1}).([surf '_coord_file']) = coord_file;
                        convert_coords(this.DWI.(hemi{1}).(surf), coord_file);
                    end
                end
            end 
        end
    end        
end
    
