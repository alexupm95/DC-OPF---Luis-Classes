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
    #   1   2       3       4        5      6       7       8   9       10  11      12  13
    data = [
        1   71.6    27      300     -300    1.04    100     1   250     10  0.11    5   150;
        2   163     6.7     300     -300    1.025   100     1   300     10  0.085   1.2 600;
        3   85      -10.9   300     -300    1.025   100     1   270     10  0.1225  1   335
    ]
    return data
end