function DFPermute(A::DF,v::Vector{Int})
    if length(A.var)!=length(v)
        error("Permute vector's dimension mismatch!")
    end

    valuespace = reshape(A.value, A.card...)
    newvaluespace = permutedims(valuespace, v)
    var = A.var[v]
    card = A.card[v]
    DF(var,card,newvaluespace[:])
end


function DFProduct(A::DF, B::DF)
    common_var = intersect(A.var, B.var)
    A_common_idx = indexin(common_var, A.var)
    B_common_idx = indexin(common_var, B.var)
    if A.card[A_common_idx] != B.card[B_common_idx]
        error("Inputs' common variables have mismatch cardinality!")
    end

    # Set the variables of C
    Cvar = union(A.var, B.var)

    Cvar_length = length(Cvar)

    mapA = indexin(A.var, Cvar)
    mapB = indexin(B.var, Cvar)

    # Set the cardinality of variables in C
    Ccard = zeros(Int, Cvar_length)
    Ccard[mapA] = A.card
    Ccard[mapB] = B.card

    Aarr0 = indexin(Cvar, A.var)
    Barr0 = indexin(Cvar, B.var)
    Aarr1 = Aarr0[Aarr0.>0]
    Barr1 = Barr0[Barr0.>0]

    A1 = DFPermute(A, Aarr1)
    B1 = DFPermute(B, Barr1)

    A1card = ones(Int, Cvar_length)
    B1card = ones(Int, Cvar_length)
    A1card[mapA] = A.card
    B1card[mapB] = B.card

    Avaluespace = reshape(A1.value, A1card...)
    Bvaluespace = reshape(B1.value, B1card...)

    Cvaluespace = Avaluespace .* Bvaluespace

    DF(Cvar, Ccard, Cvaluespace[:])
end


*(A::DF, B::DF) = DFProduct(A::DF, B::DF)


function DFMargin(A::DF, Remove_var::Vector{ASCIIString}, Remain_var::Vector{ASCIIString}, Remove_dims::Vector{Int}, Remain_dims::Vector{Int})
    Remain_card = A.card[Remain_dims]

    valuespace = reshape(A.value, A.card...)
    permute_dims = [Remain_dims,Remove_dims]
    permuted_valuespace = permutedims(valuespace, permute_dims)

    squeeze_dims = [length(Remain_dims)+1:length(permute_dims)]

    sumvaluespace = sum(permuted_valuespace, squeeze_dims)
    Remain_valuespace = squeeze(sumvaluespace, squeeze_dims)

    DF(Remain_var, Remain_card, Remain_valuespace[:])
end


function DFMarginDrop(A::DF, Remove_var::Vector{ASCIIString})
    Remove_dims = indexin(Remove_var, A.var)
    if any(Remove_dims==0)
        error("Wrong variable!")
    end
    
    Remain_var = symdiff(A.var, Remove_var)
    Remain_dims = indexin(Remain_var, A.var)

    DiscreteFactor.DFMargin(A, Remove_var, Remain_var, Remove_dims, Remain_dims)
end


function DFMarginKeep(A::DF, Remain_var::Vector{ASCIIString})
    Remain_dims = indexin(Remain_var, A.var)
    if any(Remain_dims==0)
        error("Wrong variable!")
    end

    Remove_var = symdiff(A.var, Remain_var)
    Remove_dims = indexin(Remove_var, A.var)

    DiscreteFactor.DFMargin(A, Remove_var, Remain_var, Remove_dims, Remain_dims)
end


function DFReduce(A::DF, Reduce_var::Vector{ASCIIString}, Reduce_idx::Vector{Int})
    Reduce_dims = indexin(Reduce_var, A.var)
    if any(Reduce_dims.==0)
        error("Wrong variable!")
    end
    if any(A.card[Reduce_dims].<Reduce_idx)
        error("Index larger than cardinality!")
    end

    Bvar = deepcopy(A.var)
    Bcard = deepcopy(A.card)
    Bvar[Reduce_dims] = Bvar[Reduce_dims].*["_{$i}" for i in Reduce_idx]
    Bcard[Reduce_dims] = 1

    valuespace = reshape(A.value, A.card...)
    
    for i = 1:length(Reduce_dims)
        valuespace = slicedim(valuespace, Reduce_dims[i], Reduce_idx[i])
    end
    DF(Bvar, Bcard, valuespace[:])
end

function DFNormalize(A::DF)
    Bvar = deepcopy(A.var)
    Bcard = deepcopy(A.card)
    tmpvalue = deepcopy(A.value)
    Z =  sum(tmpvalue)
    Bvalue = tmpvalue./Z
    DF(Bvar, Bcard, Bvalue)
end
