cd(dirname(@__FILE__));

#=
CODE TO SOLVE THE DC OPTIMAL POWER FLOW

Authors:    Alex Junior and Peng Wang
Supervisor: Luis Badesa Bernardo
Affiliation: Technical University of Madrid
November 2025

===========================================================================
                          IMPORTANT NOTES 
===========================================================================
Only series reactance of transmission lines and transformers are considered
=#

#---------------------------
# INCLUDE THE PACKAGES USED
#---------------------------
# Packages related to linear algebra
using LinearAlgebra, SparseArrays
# Packages related data manipulation
using DataFrames, Printf, CSV, DataStructures
# Packages related to the optimization
using JuMP, HiGHS#, Gurobi

#---------------------------------
# INCLUDE AUXILIAR FUNCTION FILES
#--------------------------------
include("AF_CLEAN_TERMINAL.jl")         # Auxiliar function to clean the terminal
include("AF_READ_DATA.jl")              # Auxiliar functions used to read input data
include("AF_B_MATRIX.jl")               # Auxiliar function to create the Suscpetance Matrix
include("BUILD_DCOPF_MODEL_REDUCED.jl") # Auxiliar function to create the DC OPF model for optimization (this creates a reduced version neglecting OFF components)
include("AF_SAVE_OUTPUT.jl")            # Auxiliar function to save the output results
include("AF_MANAGEMENT.jl")             # Auxiliar function that calculates DC power flow and manage some data


#=
----------------------------------------------
 Relevant input variables to solve the DC-OPF
----------------------------------------------
** Select a system from the options below: **
3bus
9bus
24bus
=#

case        = "3bus"        # Case under study (folder name)
load_factor = 1.0           # Coefficient factor that can be used to scale the power demanded by loads
base_MVA    = 100.0         # Base Power [MVA]
optimizer = HiGHS.Optimizer # ¿Gurobi.Optimizer o HiGHS.Optimizer?


#-----------------------------------------
Clean_Terminal() # Clean the terminal
#-----------------------------------------

#-----------------------------------------
# Generate a folder to export the results
#-----------------------------------------
current_path_folder = pwd()                                            # Directory of the current folder
name_path_results   = "Results"                                        # Name of the folder to save the results (it must be created in advance)
path_folder_results = joinpath(current_path_folder, name_path_results) # Results directory
cd(current_path_folder)                                                # Load the current folder

#------------------------------------------
# Call the function to read the input data
#------------------------------------------
input_data_path_folder = joinpath(current_path_folder, "Input_Data", case) # Folder name where the input data is located

# Get the structs with data related to buses, generators and circuits
DBUS, DGEN, DCIR, bus_mapping, reverse_bus_mapping = Read_Input_Data(input_data_path_folder) 

DBUS.p_d = load_factor .* (DBUS.p_d) # Scale the real power demanded by loads using the coefficient factor

# ---------------------------------------------------
nBUS = length(DBUS.bus)      # Number of buses in the system
nGEN = length(DGEN.id)       # Number of generators in the system
nCIR = length(DCIR.from_bus) # Number of circuits in the system
cd(current_path_folder)      # Load the current folder

#-------------------------------------------------------------------------------------------------
# Associates the buses with the generators and circuits connected to it, as well as adjacent buses
#-------------------------------------------------------------------------------------------------
bus_gen_circ_dict, bus_gen_circ_dict_ON = Manage_Bus_Gen_Circ(DBUS, DGEN, DCIR) 

#-----------------------------------
# Calculate the Susceptance Matrix
#-----------------------------------

# Calculate the Susceptance Matrix
B_matrix = Calculate_Matrix_B(DBUS, DCIR, nBUS, nCIR) # Susceptance matrix

# ########################################################################################
#                                 STARTS OPTIMIZATION PROCESS 

#-----------------------------------
# Optimization model -> Setup
#-----------------------------------
model = JuMP.Model(optimizer)
if optimizer == HiGHS.Optimizer
    JuMP.set_optimizer_attribute(model, "mip_rel_gap", 1e-8) # Set optimality tolerance
    # JuMP.set_optimizer_attribute(model, "output_flag", false) # Suppress solver output
    # JuMP.set_optimizer_attribute(model, "simplex_iteration_limit", 20_000)
    # JuMP.set_optimizer_attribute(model, "ipm_iteration_limit", 5000)

elseif optimizer == Gurobi.Optimizer
    JuMP.set_optimizer_attribute(model, "OptimalityTol", 1e-8)
    # JuMP.set_optimizer_attribute(model, "OutputFlag", 0)
    # JuMP.set_optimizer_attribute(model, "IterationLimit", 5000)
end

#------------------------------
# Build the Optimization Model
#------------------------------
time_to_build_model = time() # Start the timer to build the Optimization Model

model, V, θ, P_g, eq_const_angle_sw, eq_const_p_balance, ineq_const_p_ik_lb, ineq_const_p_ik_ub, ineq_const_diff_ang_lb, 
ineq_const_diff_ang_ub = Make_DCOPF_Model!(model, B_matrix, DBUS, DGEN, DCIR, bus_gen_circ_dict_ON, base_MVA, nBUS, nGEN, nCIR)

time_to_build_model = time() - time_to_build_model # End the timer to build the Optimization Model
println("\nTime to build the model: $time_to_build_model sec\n")

# =====================================================================================

#-------------------------------------------------------------------------------------
#                         SAVE MODEL SUMMARY AND DETAILS
#-------------------------------------------------------------------------------------
println("--------------------------------------------------------------------------------------------------------------------------------------")
Export_DCOPF_Model(model, θ, P_g, eq_const_angle_sw, eq_const_p_balance, ineq_const_p_ik_lb, ineq_const_p_ik_ub, 
ineq_const_diff_ang_lb, ineq_const_diff_ang_ub, current_path_folder, path_folder_results)

println("--------------------------------------------------------------------------------------------------------------------------------------")

# ---------------------------------
#  Solve the optmization problem
# ---------------------------------
time_to_solve_model = time()                       # Start the timer to solve the Optimization Model
JuMP.optimize!(model)                              # Optimize model
time_to_solve_model = time() - time_to_solve_model # End the timer to build the Optimization Model
println("\nTime to solve the model: $time_to_solve_model sec")
status_model = JuMP.termination_status(model)
println("Termination Status: $status_model \n")
println("--------------------------------------------------------------------------------------------------------------------------------------")


#                               ENDS OPTIMIZATION PROCESS 
# ########################################################################################

RBUS::Union{Nothing, DataFrame} = nothing # DataFrame with results for the buses
RGEN::Union{Nothing, DataFrame} = nothing # DataFrame with results for the generators
RCIR::Union{Nothing, DataFrame} = nothing # DataFrame with results for the branches

if status_model == OPTIMAL || status_model == LOCALLY_SOLVED || status_model == ITERATION_LIMIT # Check the final status of the model after optmization
    #-------------------------------------------------------------------------------------
    #                                SAVE RESULTS 
    #-------------------------------------------------------------------------------------
    RBUS, RGEN, RCIR = Save_Solution_Model(model, V, θ, P_g, bus_gen_circ_dict_ON, 
    DBUS, DGEN, DCIR, base_MVA, nBUS, nGEN, nCIR, bus_mapping, reverse_bus_mapping, 
    current_path_folder, path_folder_results)

    #-------------------------------------------------------------------------------------
    #                               SAVE DUAL VARIABLES
    #-------------------------------------------------------------------------------------
    Save_Duals_DCOPF_Model(model, θ, P_g, eq_const_angle_sw, eq_const_p_balance, ineq_const_p_ik_lb, ineq_const_p_ik_ub, 
    ineq_const_diff_ang_lb, ineq_const_diff_ang_ub, base_MVA, current_path_folder, path_folder_results)

else
    JuMP.@warn "Optmization process failed. No feasible solution found."
end
println("--------------------------------------------------------------------------------------------------------------------------------------")


