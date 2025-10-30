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
        1  2    0.0     0.1     0       40      40      40      1       0       1       -30     30;
        1  3    0.0     0.1     0       80      80      80      1       0       1       -30     30;
        2  3    0.0     0.1     0       30      30      30      1       0       1       -30     30
    ]
    return data
end