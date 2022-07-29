function [out_name, sc_name] = apply_tck_sample(tracks, scalar, out_dir, PS)

    [~, sc_name] = Supp_gz_fileparts(scalar);
    out_name = [out_dir filesep sc_name '_mean.txt'];
    
    command1 = [PS.mrtrix_prefix ' tcksample -stat_tck mean -precise -force ' tracks ' ' scalar ' ' out_name];
    no.dgn = false; % switch off diagnostics msg for this one, mention instead
    verb_msg(['Sampling ' scalar ' onto streamlines'], PS);
    sys_exec(command1, no);

end