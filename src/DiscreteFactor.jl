module DiscreteFactor
    importall Base

    type DF
        var::Vector{ASCIIString}
        card::Vector{Int}
        value::Vector{Float64}

        function DF(var::Vector{ASCIIString}, card::Vector{Int}, value::Vector{Float64})
            if prod(card) != length(value)
                error("Cardinalities and values do not match!")
            elseif length(var) != length(card)
                error("Variables and cardinalities do not match!")
            else
                new(var, card, value)
            end
        end
    end

    include("dfactor.jl")

    export
        locateat,
        *, # infix for DFProduct
        DF,
        DFMarginDrop,
        DFMarginKeep,
        DFNormalize,
        DFPermute,
        DFProduct,
        DFReduce
end
