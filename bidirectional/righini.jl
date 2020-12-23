
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

function predecessors(v_i, pg::ESPPRC_Instance)
    if v_i == pg.origin
        return []
    else
        pred = setdiff(findall(x -> x < Inf, pg.cost[:, v_i]), [v_i])
        sort!(pred, by=x->pg.time[x, v_i])
        return pred
    end
end

function successors(v_i, pg::ESPPRC_Instance)
    if v_i == pg.destination
        return []
    else
        succ = setdiff(findall(x -> x < Inf, pg.cost[v_i, :]), [v_i])
        sort!(succ, by=x->pg.time[v_i, x])
        return succ
    end
end

function forward_reach(λ_i::Label, v_i::Int, v_j::Int, pg::ESPPRC_Instance)
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

function calculate_max_T(pg::ESPPRC_Instance)
    n_nodes = length(pg.early_time)
    set_N = 1:n_nodes
    set_C = setdiff(set_N, [pg.origin, pg.destination])
    tmp = [pg.late_time[i] + pg.service_time[i] + pg.time[i, pg.destination] for i in set_C]
    max_T = maximum(tmp)
    return max_T
end

function backward_reach(λ_i::Label, v_i::Int, v_k::Int, pg::ESPPRC_Instance, max_T)
    # Currently at v_i 
    # extending arc: (v_k, v_i)

    is_reachable = true

    a_bw_k = pg.early_time[v_k] + pg.service_time[v_k]
    b_bw_k = pg.late_time[v_k] .+ pg.service_time[v_k]

    # Check time 
    min_time_required = max(pg.time[v_k, v_i] + pg.service_time[v_i] + λ_i.time, max_T - b_bw_k)
    if min_time_required > max_T - a_bw_k
        is_reachable = false
    end

    # Check capacity
    new_load = λ_i.load + pg.load[v_k, v_i]
    if new_load > pg.capacity
        is_reachable = false
    end

    # @show is_reachable, v_k, λ_i.path, min_time_required
    return is_reachable, min_time_required, new_load
end

function update_flag!(label::Label, pg::ESPPRC_Instance)
    label.flag .= 0
    label.flag[label.path] .= 1
    # v_j = label.path[end]
    # for v_k in successors(v_j, pg)
    #     if label.flag[v_k] == 0
    #         is_reachable, _, _ = reach(label, v_j, v_k, pg)
    #         if !is_reachable
    #             label.flag[v_k] = 1
    #         end
    #     end
    # end
end

function forward_extend(λ_i::Label, v_i::Int, v_j::Int, pg::ESPPRC_Instance)
    is_reachable, new_time, new_load = forward_reach(λ_i, v_i, v_j, pg)

    if !is_reachable
        # λ_i.flag[v_j] = 1
        return nothing
    end
    new_cost = λ_i.cost + pg.cost[v_i, v_j]
    new_path = [λ_i.path; v_j]

    label = Label(new_time, new_load, copy(λ_i.flag), new_cost, new_path)
    update_flag!(label, pg)

    return label
end

function backward_extend(λ_i::Label, v_i::Int, v_k::Int, pg::ESPPRC_Instance, max_T)
    # Currently at v_i 
    # extending arc: (v_k, v_i)

    is_reachable, new_time, new_load = backward_reach(λ_i, v_i, v_k, pg, max_T)

    if !is_reachable
        # λ_i.flag[v_j] = 1
        return nothing
    end
    new_cost = pg.cost[v_k, v_i] + λ_i.cost 
    new_path = [v_k; λ_i.path]

    label = Label(new_time, new_load, copy(λ_i.flag), new_cost, new_path)
    update_flag!(label, pg)

    return label
end

function is_dominated_by(label::Label, other_label::Label)
    # Check if label is dominated by other_label 

    is_same = label.path == other_label.path
    has_same_values = label.cost == other_label.cost &&
                        label.time == other_label.time && 
                        label.load == other_label.load

    # return true: label is dominated by other_label; label is removed
    # return false: label is not dominated by other_label; label is alive
    if is_same
        # Exactly the same path
        @assert has_same_values
        return true
    elseif has_same_values
        # Different path, but they are equally good. So far.
        return true
    elseif label.cost < other_label.cost
        return false
    elseif label.time < other_label.time
        return false
    elseif label.load < other_label.load 
        return false
    elseif any(label.flag .< other_label.flag)
        return false
    else
        return true
    end
end

function EFF!(Λ::Vector, label::Label, v_j::Int)
    is_updated = false
    is_non_dominated = true 
    idx = []
    for n in eachindex(Λ[v_j])
        other_label = Λ[v_j][n]
        if is_dominated_by(label, other_label)
            is_non_dominated = false
            # break
        elseif is_dominated_by(other_label, label)
            push!(idx, n)
        end
    end
    if !isempty(idx)
        deleteat!(Λ[v_j], idx)
        is_updated = true
    end

    if is_non_dominated
        push!(Λ[v_j], label)
        is_updated = true
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

function join_labels!(final_labels, λ_i::Label, λ_j::Label, pg::ESPPRC_Instance, max_T)
    v_i = λ_i.path[end] # forward label
    v_j = λ_j.path[1]   # backward label

    # Check no cycle
    new_flag = λ_i.flag .+ λ_j.flag
    if !prod(λ_i.flag .+ λ_j.flag .<= 1)
        return Inf
    end
    # Check capacity
    new_load = λ_i.load + pg.load[v_i, v_j] + λ_j.load 
    if new_load > pg.capacity
        return Inf
    end
    # Check time
    time_check = λ_i.time + pg.service_time[v_i] + pg.time[v_i, v_j] + pg.service_time[v_j] + λ_j.time
    if time_check > max_T
        return Inf
    end

    # println("Joining: ", λ_i.path, " + ", λ_j.path)

    new_path = [λ_i.path; λ_j.path]
    new_cost = λ_i.cost + pg.cost[v_i, v_j] + λ_j.cost 
    new_time = calculate_path_time(new_path, pg)
    
    new_label = Label(new_time, new_load, new_flag, new_cost, new_path)
    update_flag!(new_label, pg)
    push!(final_labels, new_label)

    return new_cost
end

function select_node!(set_E, pg::ESPPRC_Instance)
    return set_E[1]
end


function solveESPPRCrighini(org_pg::ESPPRC_Instance; max_neg_cost_routes=Inf)
    pg = deepcopy(org_pg)
    graph_reduction!(pg)

    n_nodes = length(pg.early_time)
    set_N = 1:n_nodes
    max_T = calculate_max_T(pg)
    @show pg.late_time[pg.destination], max_T

    # Initial Label Sets
    Λ_fw = Vector{Vector{Label}}(undef, n_nodes)
    Λ_bw = Vector{Vector{Label}}(undef, n_nodes)
    for v_i in set_N
        Λ_fw[v_i] = Label[]
        Λ_bw[v_i] = Label[]
    end

    # Label at the origin
    unreachable = zeros(Int, n_nodes)
    init_label = Label(0.0, 0.0, unreachable, 0.0, [pg.origin])
    update_flag!(init_label, pg)
    push!(Λ_fw[pg.origin], init_label)

    # Label at the destination
    unreachable = zeros(Int, n_nodes)
    term_label = Label(0.0, 0.0, unreachable, 0.0, [pg.destination])
    update_flag!(term_label, pg)
    push!(Λ_bw[pg.destination], term_label)

    # Inititial search nodes
    set_E = [pg.origin, pg.destination]

    forward_cpu_time = 0
    backward_cpu_time = 0
    join_cpu_time = 0

    # Search
    while !isempty(set_E)
        # v_i = set_E[1]
        v_i = select_node!(set_E, pg)

        t0 = time()
        # Forward Extension            
        for λ_i in Λ_fw[v_i]
            if λ_i.time < max_T / 2
                for v_j in successors(v_i, pg)
                    if λ_i.flag[v_j] == 0
                        label = forward_extend(λ_i, v_i, v_j, pg)
                        if !isnothing(label)
                            is_updated = EFF!(Λ_fw, label, v_j)
                            if is_updated
                                push!(set_E, v_j)
                            end    
                        end
                    end
                end
            end
        end
        forward_cpu_time += time() - t0

        t0 = time()
        # Backward Extension
        for λ_i in Λ_bw[v_i]
            if λ_i.time < max_T / 2
                for v_k in predecessors(v_i, pg)
                    if λ_i.flag[v_k] == 0
                        label = backward_extend(λ_i, v_i, v_k, pg, max_T)
                        if !isnothing(label)
                            is_updated = EFF!(Λ_bw, label, v_k)
                            if is_updated
                                push!(set_E, v_k)
                            end    
                        end
                    end
                end
            end
        end
        backward_cpu_time += time() - t0

        setdiff!(set_E, v_i)
    end

    println("...search is done...")


    t0 = time()

    # Finding the minimum cost among labels
    min_all_bw = Inf 
    min_bw = fill(Inf, n_nodes)
    min_fw = fill(Inf, n_nodes)
    for v_i in set_N
        for λ_i in Λ_fw[v_i]
            min_fw[v_i] = min(min_fw[v_i], λ_i.cost)
        end
        for λ_i in Λ_bw[v_i]
            min_bw[v_i] = min(min_bw[v_i], λ_i.cost)
            min_all_bw = min(min_all_bw, λ_i.cost)
        end
    end
    UB = Inf

    final_labels = Label[]
    # Join between forward and backward paths
    for v_i in set_N
        min_c = minimum([pg.cost[v_i,j] for j in set_N if j!=v_i])
        if min_fw[v_i] + min_c + min_all_bw < UB
            for λ_i in Λ_fw[v_i]
                if λ_i.cost + min_c + min_all_bw < UB 
                    for v_j in set_N
                        if λ_i.cost + pg.cost[v_i,v_j] + min_bw[v_j] < UB 
                            for λ_j in Λ_bw[v_j]
                                if λ_i.cost + pg.cost[v_i,v_j] + λ_j.cost < UB 
                                    new_cost = join_labels!(final_labels,λ_i, λ_j, pg, max_T)
                                    UB = min(UB, new_cost)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    join_cpu_time = time() - t0

    @show forward_cpu_time, backward_cpu_time, join_cpu_time
    @show size(Λ_fw), size(Λ_bw), size(final_labels)

    best_label = find_min_cost_label!(final_labels)
    return best_label, Λ_fw

end