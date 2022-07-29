function [VR, VL, FR, FL, LR, LL] = process_FS_surfaces(RS, LS, PS)
    
    % used for different surfaces / modalities so can't fix shortcuts
    % RS = path to the right surface file
    % LS = path to the left surface file
  
    % read in the surface data    
    if PS.dgn
        [VR1, FR] = freesurfer_read_surf(RS);
        [VL1, FL] = freesurfer_read_surf(LS);
    else
        evalc('[VR1, FR] = freesurfer_read_surf(RS);');
        evalc('[VL1, FL] = freesurfer_read_surf(LS);');
    end
    
    % freesurfer displaces the centre of coordinates from magnet
    % isocentre to FOV/2 (I think) so needs correcting
    % only translation is used (no rotation should be happening)
    
    tfmatrix = get_surface_transform(RS);       
    VR = VR1 + repmat(tfmatrix(:,4)', length(VR1), 1);
    VL = VL1 + repmat(tfmatrix(:,4)', length(VL1), 1); 
    
    % identify vertices that are not included in the labels  
    if ~strcmp(PS.slab, '-1')        
        try
            [pp, nn] = Supp_gz_fileparts(RS);
            LR = [pp(1:end-4) 'label' filesep 'rh.' PS.slab '.label'];
            LL = [pp(1:end-4) 'label' filesep 'lh.' PS.slab '.label'];
            
            LR = filters_label(VR, LR);
            LL = filters_label(VL, LL);             
        catch
            error('rh, lh not in a standard -recon_all environment, or the label file is wrong')
        end        
    else        
        LR = ones(size(VR, 1), 1);
        LL = ones(size(VL, 1), 1);     
    end    
    
    LR = logical(LR);
    LL = logical(LL);
end
