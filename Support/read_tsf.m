function scalar_data = read_tsf(tsf)

    % access the external file (values separated by spaces)
    dat_id = fopen(tsf);
    
    % start reading
    pos = ftell(dat_id);
    comline = fgetl(dat_id);
    
    % skip comment lines
    while strcmp(comline(1), '#') 
        pos = ftell(dat_id);
        comline = fgetl(dat_id);
    end

    % return to the beginning of the previous string
    fseek(dat_id, pos, -1); 
    
    % start scanning
    scalar_data = fscanf(dat_id, '%f ', [1 Inf])';
    fclose(dat_id); 
                
end