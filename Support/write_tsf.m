function write_tsf(scalar_data, fname)

    tsf_id = fopen(fname, 'w');
    fprintf(tsf_id, '%f ', scalar_data);
    fclose(tsf_id); 
                
end