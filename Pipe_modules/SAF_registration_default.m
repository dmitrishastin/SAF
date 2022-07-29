function SD = SAF_registration_default(PS, SD)
 
    if ~PS.noregister
        
        if exist([PS.work_dir filesep 'ants_anatomical.nii.gz'],'file') && PS.force

            system(['rm ' PS.work_dir filesep 'ants_*']);

        end

        if ~exist([PS.work_dir filesep 'ants_anatomical.nii.gz'],'file')  

            if isempty(PS.fa)
                error('FA file is required for registration')
            end

            verb_msg('Performing FA to T1 registration using ANTS', PS)        
            command1 = ['antsIntermodalityIntrasubject.sh -d 3 -i ' PS.fa ' -r ' SD.tx.t1 ' -t 3 -x ' SD.tx.t1 ' -w ' PS.work_dir filesep 'a -o ' PS.work_dir filesep 'ants_'];
            sys_exec(command1, PS)        

        end

        SD.tx.affine = [PS.work_dir filesep 'ants_0GenericAffine.mat'];
        SD.tx.warp = [PS.work_dir filesep 'ants_1Warp.nii.gz'];
        SD.tx.iwarp = [PS.work_dir filesep 'ants_1InverseWarp.nii.gz'];    
        SD.tx.in_dwi = [PS.work_dir filesep 'brain_DWI.nii.gz'];

        if ~exist(SD.tx.in_dwi,'file') || PS.force

            command1 = ['antsApplyTransforms -d 3 -i ' SD.tx.t1 ' -r ' PS.fa ' -t [' SD.tx.affine ', 1] -t ' SD.tx.iwarp ' -o ' SD.tx.in_dwi];
            sys_exec(command1, PS)      

        end
        
    else
        verb_msg('Assuming T1 and DWI are co-registered', PS); 
        SD.tx.in_dwi = SD.tx.t1;
        [~,nn,ee] = Supp_gz_fileparts(SD.tx.t1);
        command1 = ['ln -s ' SD.tx.t1 ' ' PS.work_dir filesep nn ee];
        sys_exec(command1, PS);
    end
    
end
