# ===================================================================================
#                   PRINT THE OPTIMIZATION MODEL IN TXT FILE
# ===================================================================================

# Function to write the DC-OPF model in a txt file
function Export_DCOPF_Model(model::Model, 
    θ::OrderedDict{Int64, VariableRef}, 
    P_g::OrderedDict{Int64, VariableRef},
    eq_const_angle_sw::ConstraintRef, 
    eq_const_p_balance::OrderedDict{Int64, ConstraintRef}, 
    ineq_const_p_ik::OrderedDict{Int64, ConstraintRef}, 
    ineq_const_diff_ang::OrderedDict{Int64, ConstraintRef},
    current_path_folder::String, 
    path_folder_results::String
    )

    cd(joinpath(path_folder_results,"DCOPF")) # Load the path folder for results

    # Open the file for writing
    open("model_summary.txt", "w") do io
        # Print the model to the file
        show(io, model)
    end

    # Desired key order to print the variables
    vector_dict_var = [θ, P_g]

    open("DCOPF_model_details.txt", "w") do io

        # ------------------
        # Objective fuction
        # ------------------
        println(io, "=========")
        println(io, "Objective ")
        println(io, "=========")
        println(io, model.ext[:objective])
        println(io, "\n")

        # ---------------------------
        # Variables used in the model
        # ---------------------------
        println(io, "=========")
        println(io, "Variables")
        println(io, "=========")
        for i in eachindex(vector_dict_var)
            for (j, info) in vector_dict_var[i]
                println(io, "$j: ", info)
            end
        end
        println(io, "\n")

        # --------------------
        # Equality constraint
        # --------------------
        println(io, "====================================")
        println(io, "Equality Constraint: Angle Swing Bus")
        println(io, "====================================")
        println(io, "1: ", eq_const_angle_sw)
        println(io, "\n")

        println(io, "====================================================")
        println(io, "Equality Constraints: Active Power Balance for Buses")
        println(io, "====================================================")
        for (i, info) in eq_const_p_balance 
            println(io, "$i: ", info) 
        end
        println(io, "\n")

        # ----------------------
        # Inequality constraint
        # ----------------------
        println(io, "=========================================================")
        println(io, "Inequality Constraints: Power Transfer Limits of Branches")
        println(io, "=========================================================")
        for (i, info) in ineq_const_p_ik
            println(io, "$i: ", info)
        end
        println(io, "\n")

        println(io, "===============================================================")
        println(io, "Inequality Constraints: Voltage Angle Differences between Buses")
        println(io, "===============================================================")
        for (i, info) in ineq_const_diff_ang
            println(io, "$i: ", info)
        end
        println(io, "\n")

        # Dicts with variables
        dicts_of_vars = [θ, P_g]  # OrderedDict{Int,VariableRef} or similar
        all_vars = Set(v for d in dicts_of_vars for v in values(d))

        println(io, "==========================================================")
        println(io, "Inequality Constraints: Inferior Limits Decision Variables")
        println(io, "==========================================================")
        const_lim_inf_decision_var = JuMP.all_constraints(model, VariableRef, MOI.LessThan{Float64})

        for (i, cref) in enumerate(const_lim_inf_decision_var)
            c_obj = JuMP.constraint_object(cref)  # returns ScalarConstraint
            var = c_obj.func                      # here .func is the VariableRef
            if var in all_vars
                println(io, "$i: ", cref)
            end
        end
        println(io, "\n")

        println(io, "==========================================================")
        println(io, "Inequality Constraints: Superior Limits Decision Variables")
        println(io, "==========================================================")
        const_lim_sup_decision_var = JuMP.all_constraints(model, VariableRef, MOI.GreaterThan{Float64})

        for (i, cref) in enumerate(const_lim_sup_decision_var)
            c_obj = JuMP.constraint_object(cref)  # returns ScalarConstraint
            var = c_obj.func                      # here .func is the VariableRef
            if var in all_vars
                println(io, "$i: ", cref)
            end
        end   
        println(io, "\n")

    end
    cd(current_path_folder)

    println("DC-OPF Model successfully saved as TXT file in: ", joinpath(path_folder_results,"DCOPF"))

end

# ===================================================================================
#                  PRINT THE REPORTS FOR THE DC OPF IN TXT AND CSV
# ===================================================================================

# Function to print and save variables according to the solution of the model
function Save_Solution_Model(model::Model, 
    V::OrderedDict{Int, Float64}, 
    θ::OrderedDict{Int, VariableRef}, 
    P_g::OrderedDict{Int, VariableRef}, 
    bus_gen_circ_dict::OrderedDict,
    DBUS::DataFrame, 
    DGEN::DataFrame, 
    DCIR::DataFrame, 
    base_MVA::Float64, 
    nBUS::Int64, 
    nGEN::Int64, 
    nCIR::Int64,
    bus_mapping::OrderedDict,
    reverse_bus_mapping::OrderedDict,
    current_path_folder::String,
    path_folder_results::String
    )

    println("===================================================")
    println("Objective Function: € "*string(round(JuMP.value.(model.ext[:objective]), digits=2))*"")
    println("===================================================")

    V_optim = [data for (_, data) in V] # Only to convert from Dict to vector (all elements are equal to 1 p.u.)

    P_g_optim = [JuMP.value(v) for (_, v) in P_g]  # Get the results of the optimization process -> Variable P_g
    θ_optim   = [JuMP.value(v) for (_, v) in θ]    # Get the results of the optimization process -> Variable θ

    # =============================================================================
    #                                   Generators
    # =============================================================================
    # Initialize a Vector for all generators
    P_g_all = zeros(Float64, nGEN)
    Q_g_all = zeros(Float64, nGEN)
    S_g_all = zeros(Float64, nGEN)

    P_g_dict = Dict{Int, Float64}()
    Q_g_dict = Dict{Int, Float64}()
    S_g_dict = Dict{Int, Float64}()
    aux_count = 0
    for (i, id) in enumerate(DGEN.id)
        if DGEN.g_status[i] == 1
            aux_count += 1
            P_g_dict[id] = Float64(P_g_optim[aux_count])
            Q_g_dict[id] = 0.0
            S_g_dict[id] = Float64(P_g_optim[aux_count])
        end
    end
    
    for (i, id) in enumerate(DGEN.id)
        if haskey(P_g_dict, id)
            P_g_all[i] = P_g_dict[id]  # Use optimized value
            Q_g_all[i] = Q_g_dict[id]
            S_g_all[i] = S_g_dict[id]
        end
    end

    # Calculate loading
    gen_loading_p = [DGEN.g_status[i] * ((P_g_all[i] - (DGEN.pg_min[i] / base_MVA)) / ((DGEN.pg_max[i] - DGEN.pg_min[i]) / base_MVA)) for i in 1:nGEN] # Generator loading -> Active power
    
    gen_loading_q = zeros(Float64, nGEN) # Generator loading -> Reactive power

    # =============================================================================
    #                                   Buses
    # =============================================================================
    # Defining a vector of Power Generated in each bus
    P_g_bus = zeros(Float64, nBUS) # Vector of active power generated at each bus
    Q_g_bus = zeros(Float64, nBUS) # Vector of reactive power generated at each bus
    for bus_id in eachindex(DBUS.bus)
        indices_bus_gen = bus_gen_circ_dict[bus_id][:gen_ids]
        if !isempty(indices_bus_gen)
            P_g_bus[bus_id] = sum(P_g_all[indices_bus_gen])
        end
    end

    # =============================================================================
    #                                 Circuits
    # =============================================================================
    # Initialize Vector for all Circuits
    P_ik_all = zeros(Float64, nCIR)
    Q_ik_all = zeros(Float64, nCIR)
    S_ik_all = zeros(Float64, nCIR)
    P_ki_all = zeros(Float64, nCIR)
    Q_ki_all = zeros(Float64, nCIR)
    S_ki_all = zeros(Float64, nCIR)

    P_ik_dict = Dict{Int, Float64}()
    Q_ik_dict = Dict{Int, Float64}()
    S_ik_dict = Dict{Int, Float64}()
    P_ki_dict = Dict{Int, Float64}()
    Q_ki_dict = Dict{Int, Float64}()
    S_ki_dict = Dict{Int, Float64}()

    for (i, id) in enumerate(DCIR.circ)
        if DCIR.l_status[i] == 1
            f_bus = DCIR.from_bus[id]  # Bus from
            t_bus = DCIR.to_bus[id]    # Bus to
            b = 1 / (DCIR.l_reac[id]) # Branch series susceptance         

            P_ik_dict[id] = b * (θ_optim[f_bus] - θ_optim[t_bus])
            Q_ik_dict[id] = 0.0
            S_ik_dict[id] = b * (θ_optim[f_bus] - θ_optim[t_bus])
            P_ki_dict[id] = b * (θ_optim[t_bus] - θ_optim[f_bus])
            Q_ki_dict[id] = 0.0
            S_ki_dict[id] = b * (θ_optim[t_bus] - θ_optim[f_bus])
            # aux_count += 1
            # P_ik_dict[id] = Float64(Pik_optim[aux_count])
            # Q_ik_dict[id] = 0.0
            # S_ik_dict[id] = Float64(Pik_optim[aux_count])
            # P_ki_dict[id] = Float64(Pki_optim[aux_count])
            # Q_ki_dict[id] = 0.0
            # S_ki_dict[id] = Float64(Pki_optim[aux_count])
        end
    end

    for (i, id) in enumerate(DCIR.circ)
        if haskey(P_ik_dict, id)
            P_ik_all[i] = P_ik_dict[id]  # Use optimized value
            Q_ik_all[i] = Q_ik_dict[id]
            S_ik_all[i] = S_ik_dict[id]
            P_ki_all[i] = P_ki_dict[id]  # Use optimized value
            Q_ki_all[i] = Q_ki_dict[id]
            S_ki_all[i] = S_ki_dict[id]
        end
    end

    Plosses = P_ik_all + P_ki_all  # Active power losses in the branches
    Qlosses = Q_ik_all + Q_ki_all  # Reactive power losses in the branches
    

    # Calculate the loading of each branch according to the data provided in the input files
    # If there is no capacity limit defined in the input data file, the code assumes null loading
    all_cap = [DCIR.l_cap_1 DCIR.l_cap_2 DCIR.l_cap_3]
    circ_cap = zeros(Float64, nCIR)

    for i in 1:nCIR
        if any(!iszero, all_cap[i,:])
            index_cap = findfirst(!iszero, all_cap[i,:])
            circ_cap[i] = all_cap[i, index_cap]
        else
            circ_cap[i] = Inf
        end
    end
    circ_loading = [DCIR.l_status[lin] * abs(max(S_ik_all[lin], S_ki_all[lin])) / (circ_cap[lin] / base_MVA) for lin in eachindex(DCIR.circ)]

    # Correcting the buses labels
    bus_bus      = [reverse_bus_mapping[b] for b in DBUS.bus]
    gen_bus      = [reverse_bus_mapping[b] for b in DGEN.bus]
    from_bus     = [reverse_bus_mapping[b] for b in DCIR.from_bus]
    to_bus       = [reverse_bus_mapping[b] for b in DCIR.to_bus]

    # DataFrame to save the results related to the buses
    RBUS = DataFrame(
        bus  = bus_bus,                                             # Bus identifier
        v    = V_optim,                                             # Voltage magnitude                            [p.u.]
        θ    = round.(rad2deg.(θ_optim),                 digits=3), # Voltage angle                                [deg]
        p    = round.((P_g_bus .* base_MVA) .- DBUS.p_d, digits=3), # Net Active power                             [MW]
        q    = round.(zeros(Float64, length(V_optim)),   digits=3), # Net Reactive power                           [MVAr]
        p_g  = round.((P_g_bus .* base_MVA),             digits=3), # Active power generated                       [MW]
        q_g  = round.((Q_g_bus .* base_MVA),             digits=3), # Reactive power generated                     [MVAr]
        p_d  = round.(DBUS.p_d,                          digits=3), # Active power generated                       [MW]
        q_d  = round.(zeros(Float64, length(V_optim)),   digits=3), # Reactive power demanded by load              [MVAr]
        p_sh = round.(DBUS.g_sh .* (V_optim.^2),         digits=3), # Active power demanded by shunt conductance   [MW]
        q_sh = round.(zeros(Float64, length(V_optim)),   digits=3)  # Reactive power demanded by shunt suscpetance [MVAr]
    )
    
    # DataFrame to save the results related to the circuits
    RCIR = DataFrame(
        circ      = DCIR.circ,                                   # Circuit identifier
        from_bus  = from_bus,                                    # From bus identifier
        to_bus    = to_bus,                                      # To bus identifier
        p_ik      = round.(P_ik_all .* base_MVA, digits=3),      # Circuit active power flow from i to k   [MW]
        q_ik      = round.(Q_ik_all .* base_MVA, digits=3),      # Circuit reactive power flow from i to k [MVAr]
        s_ik      = round.(S_ik_all .* base_MVA,      digits=3), # Circuit apparent power flow from i to k [MVA]
        p_ki      = round.(P_ki_all .* base_MVA, digits=3),      # Circuit active power flow from k to i   [MW]
        q_ki      = round.(Q_ki_all .* base_MVA, digits=3),      # Circuit reactive power flow from k to i [MVAr]
        s_ki      = round.(S_ki_all .* base_MVA,      digits=3), # Circuit apparent power flow from k to i [MVA]
        p_losses  = round.(Plosses .* base_MVA,   digits=3),     # Losses of active power                  [MW]
        q_losses  = round.(Qlosses .* base_MVA,   digits=3),     # Losses of reactive power                [MVAr]
        s_cap     = circ_cap,                                    # Circuit maximum power capacity          [MVA]
        loading   = circ_loading                                 # Circuit loading
    )    

    # DataFrame to save the results related to the generators
    RGEN = DataFrame(
        id_gen    = DGEN.id,                                 # Generator ID
        id_bus    = gen_bus,                                 # Bus in which the generator is connected
        p_g       = round.((P_g_all .* base_MVA), digits=3), # Active power generated           [MW]
        q_g       = round.((Q_g_all .* base_MVA), digits=3), # Reactive power generated         [MVAr]
        s_g       = round.((S_g_all .* base_MVA), digits=3), # Apparent power generated         [MVA]
        loading_p = round.(gen_loading_p,         digits=3), # Generator active power loading
        loading_q = round.(gen_loading_q,         digits=3)  # Generator reactive power loading
    )

    Save_ResultsTXT_DCOPF(path_folder_results, RBUS, nBUS, RGEN, nGEN, RCIR, nCIR, Float64(JuMP.value.(model.ext[:objective]))) # Save the results in a TXT file

    cd(current_path_folder)

    return RBUS, RGEN, RCIR

end

# Save the reports of the power flow in TXT files
function Save_ResultsTXT_DCOPF(path_folder_results::String, RBUS::DataFrame, nBUS::Int64, RGEN::DataFrame, nGEN::Int64, RCIR::DataFrame, nCIR::Int64, objective::Float64)
    cd(joinpath(path_folder_results, "DCOPF"))

    # Summation of power generated and demmanded
    sum_Pg = 0.0
    sum_Qg = 0.0
    sum_Pd = 0.0
    sum_Qd = 0.0
    sum_Psh = 0.0
    sum_Qsh = 0.0
    sum_losses_P = 0.0
    sum_losses_Q = 0.0
    sum_gen_Pg = 0.0
    sum_gen_Qg = 0.0
    sum_gen_Sg = 0.0

    io = open("buses_report.txt", "w")
    @printf(io, "BUSES REPORT\n")
    @printf(io, "============================================================================================================================= \n")
    @printf(io, "   BUS    V (pu)     θ (º)     P (MW)     Q (MVAr)      PG (MW)    QG (MVAr)    PD (MW)   QD (MVAr)     Psh (MW)   Qsh (MVAr) \n")
    @printf(io, "----------------------------------------------------------------------------------------------------------------------------- \n")
    for i = 1:nBUS
        @printf(io, " %4d    %6.4f    %6.2f    %8.2f    %8.2f    %8.2f    %8.2f    %8.2f    %8.2f    %8.2f    %8.2f\n", RBUS.bus[i], RBUS.v[i], RBUS.θ[i], RBUS.p[i], RBUS.q[i], RBUS.p_g[i], RBUS.q_g[i], RBUS.p_d[i], RBUS.q_d[i], RBUS.p_sh[i], RBUS.q_sh[i])
        sum_Pg += RBUS.p_g[i]
        sum_Qg += RBUS.q_g[i]
        sum_Pd += RBUS.p_d[i]
        sum_Qd += RBUS.q_d[i]
        sum_Psh += RBUS.p_sh[i]
        sum_Qsh += RBUS.q_sh[i]
    end
    @printf(io, "----------------------------------------------------------------------------------------------------------------------------- \n")
    @printf(io, " TOTAL:                                               %8.2f    %8.2f    %8.2f    %8.2f   %8.2f     %8.2f\n", sum_Pg, sum_Qg, sum_Pd , sum_Qd, sum_Psh , sum_Qsh)
    @printf(io, "============================================================================================================================= \n")
    @printf(io, "\n")
    close(io)  

    io = open("generators_report.txt", "w")
    @printf(io, "GENERATORS REPORT\n")
    @printf(io, "========================================================================== \n")
    @printf(io, "   ID     BUS     P_g (MW)  Q_g (MVAr)   S_g (MVA)   Loading_P   Loading_Q \n")
    @printf(io, "-------------------------------------------------------------------------- \n")
    for i = 1:nGEN
        @printf(io, " %4d   %4d    %8.2f    %8.2f    %8.2f    %8.4f    %8.4f   \n", RGEN.id_gen[i], RGEN.id_bus[i], RGEN.p_g[i], RGEN.q_g[i], RGEN.s_g[i], RGEN.loading_p[i], RGEN.loading_q[i])
        sum_gen_Pg += RGEN.p_g[i]
        sum_gen_Qg += RGEN.q_g[i]
        sum_gen_Sg += RGEN.s_g[i]
    end
    @printf(io, "-------------------------------------------------------------------------- \n")
    @printf(io, " TOTAL:         %8.4f   %8.4f   %8.4f\n", round(sum_gen_Pg, digits=3), round(sum_gen_Qg, digits=3), round(sum_gen_Sg, digits=3))
    @printf(io, "========================================================================== \n")
    close(io)
    
    io = open("circuits_report.txt", "w")
    @printf(io, "CIRCUITS REPORT\n")
    @printf(io, "=============================================================================================================================================== \n")
    @printf(io, "  CIRC    FROM    TO      Pik (MW)  Qik (MVAr)   Sik (MVA)   Pki (MW)  Qki (MVAr)    Ski (MVA)  Cap (MVA)    Loading    Ploss (MW)  Qloss (MVAr)\n")
    @printf(io, "----------------------------------------------------------------------------------------------------------------------------------------------- \n")
    for i = 1:nCIR
        @printf(io, " %4d   %4d   %4d    %8.2f    %8.2f    %8.2f    %8.2f   %8.2f     %8.2f   %8.4f     %8.4f     %8.3f     %8.3f\n", RCIR.circ[i], RCIR.from_bus[i], RCIR.to_bus[i], RCIR.p_ik[i], RCIR.q_ik[i], RCIR.s_ik[i], RCIR.p_ki[i], RCIR.q_ki[i], RCIR.s_ki[i], RCIR.s_cap[i], RCIR.loading[i], RCIR.p_losses[i], RCIR.q_losses[i])
        sum_losses_P += RCIR.p_losses[i]
        sum_losses_Q += RCIR.q_losses[i]
    end
    @printf(io, "----------------------------------------------------------------------------------------------------------------------------------------------- \n")
    @printf(io, " TOTAL:                                                                                                                  %8.3f     %8.3f\n", sum_losses_P , sum_losses_Q)
    @printf(io, "=============================================================================================================================================== \n")
    close(io)
    
    io = open("optimization_report.txt", "w")
    @printf(io, "OBJECTIVE\n")
    @printf(io, "================================ \n")
    @printf(io, "Total cost: (Euros) %8.2f \n", round(objective, digits = 2))
    @printf(io, "================================ \n")
    close(io)

    println("DC-OPF results successfully saved as TXT files in: ", joinpath(path_folder_results, "DCOPF"))
end

# ===================================================================================
#                  PRINT THE DUALS OF THE OPTIMIZATION PROBLEM
# ===================================================================================
# Function to obtain the duals of the DC-OPF
function Save_Duals_DCOPF_Model(model::Model,
    θ::OrderedDict{Int, VariableRef}, 
    P_g::OrderedDict{Int, VariableRef}, 
    eq_const_angle_sw::ConstraintRef, 
    eq_const_p_balance::OrderedDict{Int64, ConstraintRef}, 
    ineq_const_p_ik::OrderedDict{Int64, ConstraintRef}, 
    ineq_const_diff_ang::OrderedDict{Int64, ConstraintRef},
    base_MVA::Float64,
    current_path_folder::String,
    path_folder_results::String
    )

    cd(joinpath(path_folder_results, "DCOPF")) # Load the results path folder

    # -------------------------------------------------------------------------------------------------
    # Dual related to the equality constraint of angle at the swing bus
    dual_θ_SW = JuMP.dual.(eq_const_angle_sw) 

    # -------------------------------------------------------------------------------------------------
    # Dual related to the equality constraint active power balance
    dual_P_balance = -1.0 .* [JuMP.dual(info) for (i, info) in eq_const_p_balance] ./ base_MVA

    # -------------------------------------------------------------------------------------------------
    # Dual related to the inequality constraint power transfer limit for branches
    dual_p_ik = -1.0 .* [JuMP.dual(info) for (i, info) in ineq_const_p_ik] ./ base_MVA

    # -------------------------------------------------------------------------------------------------
    # Dual related to the inequality constraint voltage angle differences between buses
    dual_diff_ang = [JuMP.dual(info) for (i, info) in ineq_const_diff_ang]

    # -------------------------------------------------------------------------------------------------
    # Dual of the LOWER bound of the angle of each bus
    dual_LB_θ = [JuMP.dual(LowerBoundRef(info)) for (i, info) in θ]

    # Dual of the UPPER bound of the angle of each bus
    dual_UB_θ = [JuMP.dual(UpperBoundRef(info)) for (i, info) in θ]

    # -------------------------------------------------------------------------------------------------
    # Dual of the LOWER bound of the active power of each generator
    dual_LB_Pg = [JuMP.dual(LowerBoundRef(info)) for (i, info) in P_g] ./ base_MVA

    # Dual of the UPPER bound of the active power of each generator
    dual_UB_Pg = [JuMP.dual(UpperBoundRef(info)) for (i, info) in P_g] ./ base_MVA

    # ========== WRITE TO TXT FILE ==========
    open("DCOPF_duals.txt", "w") do io
        function write_dual_power(io, name, vec)
            println(io, "======================================")
            println(io, " $name:")
            println(io, "======================================")
            for (i, val) in enumerate(vec)
                println(io, "[$i] =\t €/MW $val")
            end
            println(io)  # empty line between sections
        end

        function write_dual_others(io, name, vec)
            println(io, "============================================")
            println(io, " $name:")
            println(io, "============================================")
            for (i, val) in enumerate(vec)
                println(io, "[$i] =\t $val")
            end
            println(io)  # empty line between sections
        end

        write_dual_others(io, "Dual Angle Swing Bus",     dual_θ_SW)
        write_dual_power(io, "Dual Power Balance", dual_P_balance)
        write_dual_power(io, "Dual Power Congestion", dual_p_ik)
        write_dual_others(io, "Dual Angular Difference", dual_diff_ang)

        write_dual_others(io,  "Dual Lower Bound θ", dual_LB_θ)
        write_dual_others(io,  "Dual Upper Bound θ", dual_UB_θ)
        write_dual_power(io,  "Dual Lower Bound Pg", dual_LB_Pg)
        write_dual_power(io,  "Dual Upper Bound Pg", dual_UB_Pg)

    end

    println("Duals of the DC-OPF model successfully saved as TXT file in: ", joinpath(path_folder_results, "DCOPF"))

    cd(current_path_folder)

end

