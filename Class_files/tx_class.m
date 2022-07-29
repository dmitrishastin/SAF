classdef tx_class
    
    properties
        
        t1                          % original T1 brain
        in_dwi                      % T1 brain in DWI space (for subsequent QC etc)
        affine                      % affine transform
        warp                        % non-affine transfrom
        iwarp                       % inverse non-affine
        
    end
    
    methods
        
        % populate
        function this = tx_class(PS)
            
            this.t1 = [PS.work_dir filesep 'brain_T1.nii.gz'];
            
            % convert brain.mgz to .nii.gz (ANTS appears to prefer it) if not done
            if ~exist(this.t1,'file')
                
                disp('Converting brain.mgz to brain.nii.gz')
                command1 = [PS.mrtrix_prefix ' mrconvert ' PS.fs_dir filesep 'mri' filesep 'brain.mgz ' this.t1];
                sys_exec(command1, PS);
                
            end
        end  
    end
end
    
