function Calculate_Matrix_B(DBUS::DataFrame, DCIR::DataFrame, nBUS::Int64, nCIR::Int64)
    # DBUS is the DataFrame related to the bus data
    # DCIR is the DataFrame related to the circuit data
    # nBUS is the number of buses
    # nCIR is the number of branches

    # From the terminal nodes of each branch (from_bus and to_bus), we create the incidence matrix,
    # where we assign 1 to from_bus nodes and -1 to to_bus nodes.
    # For the sparse function in SparseArrays, the arguments are:
    # sparse([Row Indices], [Column Indices], [Value], [Total Number of Rows], [Total Number of Columns])
    A = SparseArrays.sparse(DCIR.from_bus[:], 1:nCIR, 1, nBUS, nCIR) + SparseArrays.sparse(DCIR.to_bus[:], 1:nCIR, -1, nBUS, nCIR)

    # Create a vector with the susceptance values of each line B = -1/x
    B = @. - DCIR.l_status[:] / (DCIR.l_reac[:])

    # Once we have the Incidence Matrix "A" and the Susceptance vector "B",
    # we can construct the Susceptance Matrix "B_0":
    B_0 = A * SparseArrays.spdiagm(B) * A'
    # Here, spdiagm creates a sparse matrix and assigns the elements of vector B to the main diagonal

    # Return the susceptance matrix
    return B_0
end