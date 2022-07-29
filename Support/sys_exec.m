function sys_exec(str, PS)

    if PS.dgn
        system(str);
    else
        evalc('system(str);');
    end

end