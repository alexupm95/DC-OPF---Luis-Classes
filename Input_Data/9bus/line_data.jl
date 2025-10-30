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
        1   4   0       0.0576  0       250     250     250     1       0       1       -60     60;
        2   7   0       0.0625  0       250     250     250     1       0       1       -60     60;
        3   9   0       0.0586  0       300     300     300     1       0       1       -60     60;
        4   5   0.01    0.085   0.176   250     250     250     1       0       1       -60     60;
        4   6   0.017   0.092   0.158   250     250     250     1       0       1       -60     60;
        5   7   0.032   0.161   0.306   250     250     250     1       0       1       -60     60;
        6   9   0.039   0.17    0.358   150     150     150     1       0       1       -60     60;
        7   8   0.0085  0.072   0.149   250     250     250     1       0       1       -60     60;
        8   9   0.0119  0.1008  0.209   150     150     150     1       0       1       -60     60
    ]
    return data
end