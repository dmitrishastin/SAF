classdef saf_class

    properties
       
        saf_file                % full path to the resulting SAF tck file
        
        % in the order recorded:
        
        t_gghh                  % a two-row vector that stores the original index of the midcortical vertex at which the streamline starts (row 1) and ends (row 2)
        m                       % as above, for streamline terminations not within the LTHC but clearing gg_margin during GGHH
        h                       % as above, allocates 0 if termination occurs in right hemisphere and 1 if in left hemisphere        
        pg                      % as above, logical, records streamlines in t_gghh removed due to PG filtering
        ml                      % as above, logical, records streamlines removed due to exceeding maxlen
        t_gwg                   % as above, records the index of the WSM vertex where the streamline intersects the surface
        pre_c                   % maps cropped streamlines post GWG to streamlines pre GWG - remains empty if gwg_hard was not enabled
        pre_xp                  % maps ends of cropped streamlines post GWG to streamline points pre GWG - remains empty if gwg_hard was not enabled
        pre_h                   % stores previous hemispheric allocations (h) before overwriting them with new ones
        t                       % as above, for SAF (same as t_gwg, redundant / for backwards compatibility)
        l                       % vector recording streamline lengths for SAF
        w                       % vector recording streamline weights for SAF        
                
    end
    
    methods 
        
        
    end
end
