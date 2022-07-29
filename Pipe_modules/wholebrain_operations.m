function [PS, SD] = wholebrain_operations(PS, SD)

    SD.DWI.saf.ml = false(1, size(SD.DWI.saf.t_gghh, 2));    

    if ~isempty(PS.sl_weights) || ~isempty(PS.maxlen)

        % find the streamlines to feed into these operations
        % (everything that doesn't end in white matter or CSF)
        valid_sl = all(SD.DWI.saf.t_gghh) & SD.DWI.saf.pg == 0;

        % % save them as a separate tractogram
        % PS.final_init = [PS.work_dir filesep 'pre_wb.tck'];
        % tck = SD.DWI.sl_info;
        % tck.data = SD.DWI.sl_tracks(valid_sl);
        % rite_mrtrix_tracks(tck, PS.final_init);

		% allocate weights
        if ~isempty(PS.sl_weights)
            full_weights = read_tsf(PS.sl_weights);     
            SD.DWI.sl_weights = [PS.work_dir filesep 'pre_GWG.wts'];
            write_tsf(full_weights(valid_sl), SD.DWI.sl_weights);
        end
        
        % limit by length if requested
        [PS, sl_lenfilt] = filters_length(PS);
        if ~isempty(sl_lenfilt)
            SD.DWI.saf.ml(valid_sl) = sl_lenfilt;
        end        
    end
end
