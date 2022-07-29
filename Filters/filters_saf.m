function [PS, DWI] = filters_saf(PS, DWI)

    DWI.saf.saf_file    = [PS.work_dir filesep 'SAF.tck'];
    DWI.saf.t           = DWI.saf.t_gwg; % redundancy // for legacy reasons & potential to apply GWG differently
    
    % those that passed GWG
    exist_saf = all(DWI.saf.t_gwg);
    acc_tck = DWI.sl_tracks(exist_saf); 
    PS.logt(end+1,:) = {'Total number of SAF streamlines:' sum(exist_saf)};         

    % save SAF tractogram
    slinf = DWI.sl_info;
    slinf.data = acc_tck;
    slinf.count = num2str(length(slinf.data));
    write_mrtrix_tracks(slinf, DWI.saf.saf_file); 
    
    % save SAF weights if available
    if ~isempty(DWI.sl_weights)
        
       % read the weights
       part_weights = read_tsf(DWI.sl_weights); 
       
       if ~isempty(DWI.saf.pre_c)
            warning('mapping previous weights to new streamlines, may not apply')
            saf_weights = DWI.sl_weights(DWI.saf.pre_c);           
       else
            valid_sl = all(DWI.saf.t_gghh) & ~DWI.saf.pg;
            full_weights = DWI.saf.t(1, :) * 0;
            full_weights(valid_sl) = part_weights;
            saf_weights = full_weights(exist_saf);
       end       
             
       saf_wtfile = [PS.work_dir filesep 'SAF.wts'];
       write_tsf(saf_weights, saf_wtfile);
       DWI.saf.w = saf_weights;
       
       PS.logt(end+1,:) = {'SAF streamline weights saved in:' saf_wtfile};
       
    end
     
    % produce indexation of cortical intersection for SAF (redundant)
    DWI.saf.t(:, ~exist_saf) = 0; 
    
    % streamline lengths
    DWI.saf.l = DWI.saf.t(1, :) * 0;    
    sl_length = @(x) sum(sqrt(sum(diff(x) .^ 2, 2)));
    DWI.saf.l(exist_saf) = cellfun(sl_length, acc_tck);

end
