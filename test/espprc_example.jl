# Solving ESPPRC 
# Modified from the example given by Google OR-Tools https://developers.google.com/optimization/routing/vrp

using VRPTW
using Test 
using Random

# This example is modifed from the VRPTW example from OR-Tools
# But ESPPRC can be used outside the VRP context
# This example describes non-VRP context

# Number of nodes
n_nodes = 17

# cost matrix:
# The objective of ESPPRC is to minimize the total cost 
# Randomly generated in this example 
# cost allows negative values
cost = - rand(17, 17) 

# travel_time matrix:
# Some elements are Inf, meaning disconnected
# travel_time is used to check the time windows constraints
# If you have service time in each node, then it should be added to travel_time
# e.g., travel_time[i,j] = travel_time[i,j] + service_time[i]
travel_time = Float64[
    0 8 3 2 6 8 4 8 8 13 7 5 8 12 10 Inf 6; 
    8 0 11 10 6 3 9 5 8 4 15 14 13 9 18 9 9; 
    3 11 0 1 7 10 6 10 10 14 6 7 9 14 6 16 8; 
    2 10 1 0 6 9 4 8 9 13 4 6 8 12 8 14 7; 
    6 6 7 6 0 2 3 2 2 7 9 7 7 6 12 8 3; 
    8 3 10 9 2 0 6 2 5 4 Inf 10 10 6 Inf 5 6; 
    4 9 6 4 3 6 0 4 4 8 5 4 3 7 8 10 2; 
    8 5 10 8 2 2 4 0 3 4 9 8 7 3 13 6 3; 
    8 8 10 9 2 5 4 3 0 4 6 5 4 3 9 5 2; 
    13 4 14 13 7 4 8 4 4 0 10 9 8 4 13 4 6; 
    7 Inf 6 4 9 Inf 5 9 6 10 0 1 3 7 3 10 6; 
    5 14 7 6 7 10 4 8 5 9 1 0 2 6 4 8 4; 
    8 13 9 8 7 10 3 7 4 8 3 2 0 4 5 6 4; 
    12 9 14 12 6 6 7 3 3 4 7 6 4 0 9 2 5; 
    10 18 6 8 12 15 8 13 9 13 3 4 5 9 0 9 9; 
    Inf 9 16 14 8 5 10 6 5 4 10 8 6 2 9 0 7; 
    6 9 8 7 3 6 2 3 2 6 6 4 4 5 9 7 0
]

# load matrix 
# The load information is for each arc, hence given as a matrix
# If you have load on each node, then it should be converted to a matrix
# For example, load[i, j] = load_on_node[j] 
load_on_node = [1, 1, 2, 4, 2, 4, 8, 8, 1, 2, 1, 2, 4, 4, 8, 8, 0]
load = zeros(n_nodes, n_nodes)
for i in 1:n_nodes, j in 1:n_nodes
    load[i, j] = load_on_node[j]
end

# Time windows, for all nodes
time_windows = [
    (0, 12),  # 1
    (0, 15),  # 2
    (16, 28),  # 3
    (10, 13),  # 4
    (0, 5),  # 5
    (5, 10),  # 6
    (0, 4),  # 7
    (5, 10),  # 8
    (0, 3),  # 9
    (10, 16),  # 10
    (10, 15),  # 11
    (0, 5),  # 12
    (5, 10),  # 13
    (7, 8),  # 14
    (10, 15),  # 15
    (11, 15),  # 16
    (0, 35), # 17
]
# If early_time is set for the origin, it means the earliest possible departure time.
early_time = [time_windows[i][1] for i in 1:n_nodes]
late_time = [time_windows[i][2] for i in 1:n_nodes]

# vehicle capacity
capacity = 15 

# origin and destination
origin, destination = 6, 3

# service_time is just set to all zeros in this example
service_time = zeros(n_nodes)

pg = ESPPRC_Instance(
    origin,
    destination,
    capacity,
    cost,
    travel_time,
    load,
    early_time,
    late_time,
    service_time
)


@info("Testing for OD=($(pg.origin), $(pg.destination))")

print("Pulse     : "); @time pulse = solveESPPRC(pg, method="pulse")
print("Mono      : "); @time mono0= solveESPPRC(pg, method="monodirectional")
print("Mono DSSR : "); @time mono1 = solveESPPRC(pg, method="monodirectional", DSSR=true)
# print("Bi        : "); @time bidi0= solveESPPRC(pg, method="bidirectional")
# print("Bi   DSSR : "); @time bidi1 = solveESPPRC(pg, method="bidirectional", DSSR=true)

@show pulse.cost, pulse.load, pulse.time
@show mono0.cost, mono0.load, mono0.time
@show mono1.cost, mono1.load, mono1.time
# @show bidi0.cost, bidi0.load, bidi0.time
# @show bidi1.cost, bidi1.load, bidi1.time
@show pulse.path
@show mono0.path
@show mono1.path
# @show bidi0.path
# @show bidi1.path

@testset "ESPPRC Example Test" begin
    @test isapprox(pulse.cost, mono0.cost, atol=1e-7)
    @test isapprox(mono0.cost, mono1.cost, atol=1e-7)
    # @test isapprox(pulse.cost, bidi0.cost, atol=1e-7)
    # @test isapprox(bidi0.cost, bidi1.cost, atol=1e-7)
end



# negative cost route return test 
max_neg = 10
@info("ESPPRC Example testing with max_neg_routes=$(max_neg)...")

@time pulse, neg_pulse = solveESPPRC_vrp(pg, method="pulse", max_neg_routes=max_neg)
@time mono0, neg_mono0 = solveESPPRC_vrp(pg, method="monodirectional", max_neg_routes=max_neg)
@time mono1, neg_mono1 = solveESPPRC_vrp(pg, method="monodirectional", max_neg_routes=max_neg, DSSR=true)

@show typeof(pulse), typeof(neg_pulse), length(neg_pulse)
@show pulse 
@show mono0
@show mono1

@testset "ESPPRC Example Test with max_neg_routes" begin
    @test length(neg_pulse) <= max_neg
    @test length(neg_mono0) <= max_neg
    @test length(neg_mono1) <= max_neg
    for l in neg_pulse
        @test l.cost < 0.0
        @test l.path[1] == pg.origin        
        @test l.path[end] == pg.destination
    end
    for l in neg_mono0
        @test l.cost < 0.0
        @test l.path[1] == pg.origin        
        @test l.path[end] == pg.destination        
    end
    for l in neg_mono1
        @test l.cost < 0.0
        @test l.path[1] == pg.origin        
        @test l.path[end] == pg.destination        
    end
end