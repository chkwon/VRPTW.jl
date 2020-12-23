
# mutable struct PulseGraph
#     origin      :: Int64
#     destination :: Int64
#     capacity    :: Float64
#     cost        :: Matrix{Float64}
#     time        :: Matrix{Float64}
#     load        :: Matrix{Float64}
#     early_time  :: Vector{Float64}
#     late_time   :: Vector{Float64}
# end



function graph_reduction!(pg::ESPPRC_Instance)
    n_nodes = length(early_time)
    OD = [pg.origin, pg.destination]

    for i in 1:n_nodes, j in 1:n_nodes
        if i != j && !in(i, OD) && !in(j, OD)
            if pg.early_time[i] + pg.service_time[i] + pg.time[i, j] > pg.late_time[j]
                pg.cost[i, j] = Inf
            end
        end
    end
end

function successors(v_i, pg::ESPPRC_Instance)
    if v_i == pg.destination
        return []
    else
        succ = setdiff(findall(x -> x < Inf, pg.cost[v_i, :]), [v_i])
        return succ
    end
end

function reach(λ_i::Label, v_i::Int, v_j::Int, pg::ESPPRC_Instance)
    is_reachable = true

    # Check time 
    arrival_time = max( λ_i.time + pg.service_time[v_i] + pg.time[v_i, v_j] , pg.early_time[v_j] )
    if arrival_time > pg.late_time[v_j]
        is_reachable = false
    end

    # Check capacity
    new_load = λ_i.load + pg.load[v_i, v_j]
    if new_load > pg.capacity
        is_reachable = false
    end

    return is_reachable, arrival_time, new_load
end

function update_flag!(label::Label, pg::ESPPRC_Instance)
    label.flag[label.path] .= 1
    v_j = label.path[end]
    for v_k in successors(v_j, pg)
        if label.flag[v_k] == 0
            is_reachable, _, _ = reach(label, v_j, v_k, pg)
            if !is_reachable
                label.flag[v_k] = 1
            end
        end
    end
end

function extend(λ_i::Label, v_i::Int, v_j::Int, pg::ESPPRC_Instance)
    is_reachable, arrival_time, new_load = reach(λ_i, v_i, v_j, pg)

    if !is_reachable
        λ_i.flag[v_j] = 1
        return nothing
    end
    new_cost = λ_i.cost + pg.cost[v_i, v_j]
    new_path = [λ_i.path; v_j]

    label = Label(arrival_time, new_load, copy(λ_i.flag), new_cost, new_path)
    update_flag!(label, pg)

    return label
end


function is_identical(label::Label, other_label::Label)
    is_same = label.path == other_label.path
    has_same_values = label.cost == other_label.cost &&
                        label.time == other_label.time && 
                        label.load == other_label.load

    if is_same
        # Exactly the same path
        @assert has_same_values
        return true
    else 
        return false
    end
end
                    
function dominate(label::Label, other_label::Label)
    # Check if label dominates other_label 

    if label.cost > other_label.cost
        return false
    elseif label.time > other_label.time
        return false
    elseif label.load > other_label.load 
        return false
    elseif all(label.flag .>= other_label.flag)
        return false
    else
        return true
    end
end


function EFF!(Λ::Vector, F_ij::Vector, v_j::Int)
    is_updated = false
    while !isempty(F_ij)
        label = pop!(F_ij)
        
        idx = []
        for n in eachindex(Λ[v_j])
            other_label = Λ[v_j][n]
            if dominate(label, other_label) && !is_identical(label, other_label)
                push!(idx, n)
            end
        end
    
        if !isempty(idx)
            deleteat!(Λ[v_j], idx)
            is_updated = true
        end
    
        is_non_dominated = true 
        for n in eachindex(Λ[v_j])
            other_label = Λ[v_j][n]
            if dominate(other_label, label) || is_identical(label, other_label)
                is_non_dominated = false
                break
            end
        end
    
        if is_non_dominated
            push!(Λ[v_j], label)
            is_updated = true
        end
    end

    return is_updated
end

function find_min_cost_label!(labels)
    if isempty(labels)
        return nothing
    else
        sort!(labels, by=x->x.cost)
        return labels[1]
    end
end

function solveESPPRCfeillet(org_pg::ESPPRC_Instance; max_neg_cost_routes=Inf)
    pg = deepcopy(org_pg)
    graph_reduction!(pg)

    n_nodes = length(early_time)
    set_N = 1:n_nodes

    # Initial Label Sets
    Λ = Vector{Vector{Label}}(undef, n_nodes)
    for v_i in set_N
        Λ[v_i] = Label[]
    end

    # Label at the origin
    flag = zeros(Int, n_nodes)
    init_label = Label(0.0, 0.0, flag, 0.0, [pg.origin])
    update_flag!(init_label, pg)
    push!(Λ[pg.origin], init_label)

    # Inititial node
    set_E = [pg.origin]

    while !isempty(set_E)
        v_i = set_E[1]

        for v_j in successors(v_i, pg)
            # F_ij: set of labels extended from node v_i to node v_j
            F_ij = Label[]

            for λ_i in Λ[v_i]
                if λ_i.flag[v_j] == 0
                    label = extend(λ_i, v_i, v_j, pg)
                    if !isnothing(label)
                        push!(F_ij, label)
                    end
                end
            end

            is_updated = EFF!(Λ, F_ij, v_j)
            if is_updated
                push!(set_E, v_j)
            end
        end

        setdiff!(set_E, v_i)
    end


    best_label = find_min_cost_label!(Λ[pg.destination])
    return best_label, Λ

end