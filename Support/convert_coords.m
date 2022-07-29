function in_mat = convert_coords(in_file, out_file)

    in_file = process_coords(in_file);
    in_mat = in_file;
    
    try
        switch out_file(end-2:end)
            case 'csv' %ANTS format
                
                in_file(:,1:2)=-in_file(:,1:2);
                in_file(:,4)=0;
                fileID=fopen(out_file,'w'); fprintf(fileID, '%c,%c,%c,%c\n', ['x','y','z','t']); 
                fprintf(fileID, '%f,%f,%f,%f\n', in_file'); fclose(fileID);
            
            case 'tck' %MRTRIX format
            
                pts_to_tck(in_file,out_file);
            
            otherwise %TXT format
            
                fileID=fopen(out_file,'w'); fprintf(fileID, '%f %f %f\n', in_file'); fclose(fileID);
        end
    catch
        error('Wrong input for coordinate conversion provided')
    end
    
end