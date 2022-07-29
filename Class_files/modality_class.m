classdef modality_class
   
    properties
        
        % data arrays
        
        rh                      % right hemisphere
        lh                      % left hemisphere
        
        cv                      % combined verts as an output of combine_verts() below
        cvi                     % original index of the combined verts
        cvh                     % original side (rh = 0; lh = 1)
        cvt                     % local cortical half-thickness at the combined vertices
        cvk                     % cluster allocation (for GG-HH)
        
        sl_tracks               % streamlines
        sl_info                 % pre-filtering tck file info        
        saf                     % contains output of SAF extraction
        slx                     % legacy container
        
        % paths to files storing coordinates
        
        cv_pial_coord_file
        cv_white_coord_file
        seed_coords_file_in
        seed_coords_file_out    % mrtrix output coordinates
        
        % paths to tractogram files
        
        sl_init                 % pre-filtering tractogram
        sl_weights              % streamline weights (e.g., SIFT2) for final pre-filtering tractogram
        
    end
    
    methods
        
        % populate
        function this = modality_class(PS) 
            
            [this.rh, this.lh] = deal(surfproper_class);
            this.saf = saf_class;
            
        end
        
                
        % record number of vertices & faces / hemisphere as a value
        function this = calc_vandf(this)
            
            for hemi = {'rh', 'lh'}
                          
                this.(hemi{1}).nverts = size(this.(hemi{1}).white, 1);
                this.(hemi{1}).nfaces = size(this.(hemi{1}).faces, 1);
                this.(hemi{1}).seeds = zeros(this.(hemi{1}).nverts, 1);
                
            end            
        end
        
        % produce coordinates for the mid-cortical surfaces and local cortical half-thickness
        function this = mid_surf(this) 
            
            for hemi = {'rh', 'lh'}
                
                pial = this.(hemi{1}).pial;
                white = this.(hemi{1}).white;
                
                if ~isempty(pial) && ~isempty(white)
                    [this.(hemi{1}).mid, mid] = deal((pial + white) / 2);
                    this.(hemi{1}).ht = sqrt(sum((pial - mid) .^ 2, 2));
                end
            end     
        end
        
        % give a combined list of "used" vertices from both hemispheres
        function this = combine_verts(surf, this)
            
           for hemi = {'rh', 'lh'}
                                
                if ~isempty(this.(hemi{1}).(surf))
                    
                    coords = this.(hemi{1}).(surf);
                    
                    % index the vertices
                    lab_h = this.(hemi{1}).usedv;
                    coords_i = find(lab_h);
                    
                    if strcmp(hemi{1}, 'rh')                       
                        
                        this.cv = coords(coords_i,:);
                        this.cvi = coords_i;
                        this.cvh = logical(coords_i * 0); %mark right hemisphere with 0
                        if ~isempty(this.rh.ht)
                            this.cvt = this.rh.ht(coords_i);
                        end
                        
                    else                        
                        
                        this.cv = [this.cv; coords(coords_i,:)];
                        this.cvi = [this.cvi; coords_i];
                        this.cvh = [this.cvh; logical(coords_i * 0 + 1)];
                        if ~isempty(this.lh.ht)
                            this.cvt = [this.cvt; this.lh.ht(coords_i)];
                        end                        
                    end                    
                end
            end
        end     
    end    
end
