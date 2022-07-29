function [PS, SD] = read_prefilter_tracks(PS, SD)

    % read the streamlines in
    verb_msg('Loading streamlines', PS);
    SD.DWI.sl_info = read_mrtrix_tracks(PS.final_init);
    SD.DWI.sl_tracks = SD.DWI.sl_info.data;    
    SD.DWI.sl_info = rmfield (SD.DWI.sl_info, 'data');

end