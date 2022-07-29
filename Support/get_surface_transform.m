function tfmatrix = get_surface_transform(surf_file)

    fid = fopen(surf_file, 'rb', 'b');
    nline = '';
    
    while numel(nline)<4 || ~strcmp(nline(1:4), 'xras')
        
        nline = fgetl(fid);
       
        if feof(fid)
            error('unable to extract the surface transform')
        end
        
    end  
    
    tfmatrix = zeros(3,4);
    
    for i = 1:4
        tfmatrix(:,i) = sscanf(nline(5:end), '   = %e %e %e');
        nline = fgetl(fid);
    end    

end