function [sched_params, var, xmin, xmax, startingMean, p_jumpUp, p_jumpLo, p_stick, jumpHi, jumpLo, cut_off] = loadParams(paramPath)

    sched_params = load(paramPath);
    sched_params = sched_params.sched_params; 

    var = sched_params.var;
    xmin = sched_params.xmin;
    xmax = sched_params.xmax;
    startingMean = sched_params.startingMean; 
    p_jumpUp = sched_params.p_jumpUp; 
    p_jumpLo = sched_params.p_jumpLo;
    p_stick = sched_params.p_stick;
    jumpHi = sched_params.jumpHi;
    jumpLo = sched_params.jumpLo;
    cut_off = sched_params.cut_off; 