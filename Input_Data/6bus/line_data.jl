# COLUMNS
# 1  -> "From" bus  
# 2  -> "To" bus
# 3  -> Branch resistance (p.u)  
# 4  -> Branch reactance (p.u) 
# 5  -> Branch shunt susceptance (Π model) (p.u)
# 6  -> Branch maximum capacity 1 (MW or MVA) 
# 7  -> Branch maximum capacity 2 (MW or MVA) 
# 8  -> Branch maximum capacity 3 (MW or MVA)
# 9  -> Transformer tap (p.u) 
# 10 -> Shift angle of the transformer (degrees)   
# 11 -> Branch ON or Branch OFF
# 12 -> Minimum angle (degrees)
# 13 -> Maximum angle (degrees)
function branch_data()
    #   1   2   3       4       5       6       7       8       9       10      11      12      13
    data = [
        1   2   0.04    0.2     0       50      50       50     1       0       1       -30     30;
        1   4   0.04    0.2     0       50      50       50     1       0       1       -30     30;
        1   5   0.06    0.3     0       50      50       50     1       0       1       -30     30;
        2   3   0.05    0.25    0       20      20       20     1       0       1       -30     30;
        2   4   0.02    0.1     0       50      50       50     1       0       1       -30     30;
        2   5   0.06    0.3     0       50      50       50     1       0       1       -30     30;
        2   6   0.04    0.2     0       50      50       50     1       0       1       -30     30;
        3   5   0.05    0.26    0       50      50       50     1       0       1       -30     30;
        3   6   0.02    0.1     0       60      60       60     1       0       1       -30     30;
        4   5   0.08    0.4     0       20      20       20     1       0       1       -30     30;
        5   6   0.06    0.3     0       20      20       20     1       0       1       -30     30
    ]
    return data
end