# COLUMNS
# 1  -> Bus number
# 2  -> Bus type: (3 = SW), (2 = PV) or (1 = PQ) 
# 3  -> Active power demanded (MW)
# 4  -> Reactive power demanded (MVAr) 
# 5  -> Shunt conductance (MW) 
# 6  -> Shunt susceptance (MVAr) 
# 7  -> Area where the bus is located
# 8  -> Voltage specified (p.u)
# 9  -> Voltage angles (rad)
# 10 -> Base voltage of the system (kV)
# 11 -> Zone where the bus is located
# 12 -> Maximum bus voltage (p.u)
# 13 -> Minimum bus voltage (p.u)
function bus_data()
    #   1   2   3    4   5   6   7   8   9   10      11  12      13
    data = [ 
        1   3   0    0   0   0   1   1   0   16.5    1   1.1     0.9;
        2   2   0    0   0   0   1   1   0   18      1   1.1     0.9;
        3   2   0    0   0   0   1   1   0   13.8    1   1.1     0.9;
        4   1   0    0   0   0   1   1   0   230     1   1.1     0.9;
        5   1   125  50  0   0   1   1   0   230     1   1.1     0.9;
        6   1   90   30  0   0   1   1   0   230     1   1.1     0.9;
        7   1   0    0   0   0   1   1   0   230     1   1.1     0.9;
        8   1   100  35  0   0   1   1   0   230     1   1.1     0.9;
        9   1   0    0   0   0   1   1   0   230     1   1.1     0.9
    ]
    return data
end