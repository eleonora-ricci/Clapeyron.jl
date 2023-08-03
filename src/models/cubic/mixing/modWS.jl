abstract type modWSRuleModel <: WSRuleModel end

struct modWSRule{γ} <: WSRuleModel
    components::Array{String,1}
    activity::γ
    references::Array{String,1}
end

"""
    WSRule{γ} <: WSRuleModel

    WSRule(components::Vector{String};
    activity = Wilson,
    userlocations=String[],
    activity_userlocations=String[],
    verbose::Bool=false)

## Input Parameters

None

## Input models

- `activity`: Activity Model

## Description

modified Wong-Sandler Mixing Rule.

```
aᵢⱼ = √(aᵢaⱼ)(1 - kᵢⱼ)
bᵢⱼ = (bᵢ + bⱼ)/2
c̄ = ∑cᵢxᵢ
B̄ = Σxᵢxⱼ(bᵢⱼ - aᵢⱼ√(αᵢαⱼ)/RT)
b̄  = B̄/(1 - gᴱ/λRT - Σxᵢaᵢαᵢ/bᵢRT)
ā = RT(b̄ - B̄)
for Redlich-Kwong:
    λ = log(2) (0.6931471805599453)
for Peng-Robinson:
    λ = 1/(2√(2))log((2+√(2))/(2-√(2))) (0.6232252401402305)
```

`λ` is a coefficient indicating the relation between `gᴱ` and `gᴱ(cubic)` at infinite pressure. see [1] for more information. it can be customized by defining `WS_λ(::WSRuleModel,::CubicModel,z)`
## References

1. Wong, D. S. H., & Sandler, S. I. (1992). A theoretically correct mixing rule for cubic equations of state. AIChE journal. American Institute of Chemical Engineers, 38(5), 671–680. [doi:10.1002/aic.690380505](https://doi.org/10.1002/aic.690380505)
2. Orbey, H., & Sandler, S. I. (1995). Reformulation of Wong-Sandler mixing rule for cubic equations of state. AIChE journal. American Institute of Chemical Engineers, 41(3), 683–690. [doi:10.1002/aic.690410325](https://doi.org/10.1002/aic.690410325)
"""
modWSRule

export modWSRule
function modWSRule(components::Vector{String}; activity = Wilson, userlocations=String[],activity_userlocations=String[], verbose::Bool=false)
    _activity = init_model(activity,components,activity_userlocations,verbose)
    references = ["10.1002/aic.690380505","10.1002/aic.690410325"]
    model = modWSRule(components, _activity,references)
    return model
end

function mixing_rule(model::ABCubicModel,V,T,z,mixing_model::modWSRuleModel,α,a,b,c)
    λ = WS_λ(mixing_model,model,z)
    n = sum(z)
    invn = (one(n)/n)
    RT⁻¹ = 1/(R̄*T)
    B̄ = zero(T+V+first(z))
    Σab = B̄
    for i in @comps
        zi = z[i]
        αi = α[i]
        ai = a[i,i]*αi
        bi = b[i,i]
        B̄ += zi*zi*(bi-ai*RT⁻¹)
        Σab += zi*ai/bi
        for j in 1:(i-1)
            αj = α[j]
            bij = b[i,j]
            aij = a[i,j]*sqrt(αi*αj)
            B̄ += 2*zi*z[j]*(bij-aij*RT⁻¹)
        end
    end
    Σab = Σab*invn
    B̄ = B̄*invn*invn
    Aᴱ = excess_gibbs_free_energy(mixing_model.activity,1e5,T,z)*invn
    b̄  = B̄/(1 + (Aᴱ/λ - Σab)*RT⁻¹)
    ā = b̄*(Σab-Aᴱ/λ)
    c̄ = dot(z,c)*invn
    return ā,b̄,c̄
end

