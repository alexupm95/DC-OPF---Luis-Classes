# COLUMNS
# 1  -> Bus number
# 2  -> Active power for generation specified (MW)
# 3  -> Reactive power for generation specified (MVAr)
# 4  -> Maximum reactive power capacity (MVAr)
# 5  -> Minimum reactive power capacity (MVAr)
# 6  -> Voltage specified for the generator (p.u)
# 7  -> Base power of the system (MVA)
# 8  -> Generator status -> ON or OFF
# 9  -> Maximum active power capacity (MW)
# 10 -> Minimum active power capacity (MW)  
# 11 -> Generation cost (quadratic) (€/MW)
# 12 -> Generation cost (linear) (€/MW)
# 13 -> Generation cost (fixed) (€/MW)
function gen_data()
    #   1   2   3   4        5      6       7       8      9     10     11      12  13
    data = [
        1   0   0   100      -100   1.0     100     1       50   0      0       20   0;
        2   0   0   100      -100   1.0     100     1       100  59     0       30   0
    ]
    return data
end