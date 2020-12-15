
include("../src/read_solomon_data.jl")
include("../src/vrp_bnb.jl")


function generate_solomon_vrptw_instance(dataset_name)
    data_file_path = dataset_name * ".xml"
    data_file_path = joinpath(@__DIR__, "..", "solomon-1987", data_file_path)
    dataset, data_name, nodes, fleet, requests = read_solomon_data(data_file_path)

    n_nodes = length(nodes)
    n_vehicles = fleet.number
    n_customers = length(requests)

    # Add a dummy node for depot at the end
    push!(nodes, nodes[n_nodes])
    depot0 = n_customers + 1
    depot_dummy = n_customers + 2
    cost = calculate_cost(nodes)
    cost[depot0, depot_dummy] = Inf
    cost[depot_dummy, depot0] = Inf

    n_nodes = length(nodes)
    @assert n_nodes - 2 == n_customers
    V = 1:n_vehicles
    N = 1:n_nodes
    C = 1:n_customers

    d = [requests[i].quantity for i in C]
    q = fleet.capacity
    a = [requests[i].start_time for i in C]
    b = [requests[i].end_time for i in C]
    t = copy(cost)
    θ = [requests[i].service_time for i in C]

    vrptw_inst = VRPTW_Instance(
        t,
        θ,
        a,
        b,
        d,
        q,
        fleet.max_travel_time
    )

    return vrptw_inst
end








solomon_vrptw = generate_solomon_vrptw_instance("R101_025")
@time sol_y, sol_routes, sol_obj = solve_vrp_bnb(solomon_vrptw)

for n in 1:length(sol_y)
    if sol_y[n] > 0.01
        @show n, sol_y[n], sol_routes[n]
    end
end