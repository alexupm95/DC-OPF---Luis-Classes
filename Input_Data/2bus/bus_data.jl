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
    #   1   2   3     4     5   6   7   8       9     10    11  12    13
    data = [
        1   3   0     0     0   0   1   1.0     0.0   138   1   1.1   0.9;
        2   2   100   0     0   0   1   1.0     0.0   138   1   1.1   0.9
    ]
    return data
end