classdef surfproper_class

    properties
       
        % the following will contain coordinates in RAS
        
        pial                    % pial surface (outer cortical surface)
        white                   % white surface (inner cortical surface / GMWMI)
        mid                     % midcordical surface (averaged euclidian coordinates of the above two)
        % infl                  % inflated white surface as produced by Freesurfer -recon_all
        % sph                   % spherical white surface as produced by Freesurfer -recon_all
        
        % paths to original FS files
        
        pial_file                 
        white_file                  
        mid_file
        infl_file
        sph_file  
        curv_file
        
        % paths to files storing coordinates
        
        pial_coord_file
        white_coord_file
        
        % other
        
        seeds                   % number of successful seeds at the vertex
        faces                   % mapping to vertices as produced by reading the surface file in
        usedv                   % indices of variables to use (e.g., exclude medial surface as a result of applying the cortex label)
        nverts                  % total number of vertices in this hemisphere
        nfaces                  % total number of faces in this hemisphere  
        ht                      % local cortical half-thickness @ each vertex

    end
    
    methods      
       
    end
    
end
