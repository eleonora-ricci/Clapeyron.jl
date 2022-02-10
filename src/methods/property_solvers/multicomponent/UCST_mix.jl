"""
    UCST_mix(model::EoSModel,T;v0=x0_UCST_mix(model,T))

Calculates the Upper critical solution point of a binary mixture at a given Temperature.

returns:
- UCEP Pressure [`Pa`]
- liquid volume at UCEP Point [`m^3`]
- gas volume at UCEP Point [`m^3`]
- liquid molar composition at UCEP Point
- gas molar composition at UCEP Point

"""
function UCST_mix(model::EoSModel,T;v0=nothing)
    if v0 === nothing
        v0 = x0_UCST_mix(model,T)
    end  
    f! = (F,x) -> Obj_UCST_mix(model, F, x[2], exp10(x[1]), T)
    r  = Solvers.nlsolve(f!,v0[1:end],LineSearch(Newton()))
    sol = Solvers.x_sol(r)
    z_c = FractionVector(sol[2])
    V_c = exp10(sol[1])
    p_c = pressure(model, V_c, T, z_c)
    return (p_c, V_c, z_c)
end
function x0_UCST_mix(model::EoSModel,T)
    V  = x0_volume_liquid(model,T,[0.5,0.5])
    return [log10(V),0.5]
end

function Obj_UCST_mix(model::EoSModel,F,z,V,T)
    z    = FractionVector(z)
    L,detM = mixture_critical_constraint(model,V,T,z)
    F[1] = L
    F[2] = detM
    return F
end