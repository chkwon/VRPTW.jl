# using VRPTW
include("../src/VRPTWinclude.jl")
using Test

# For testing purpose
using Random


for i in 1:100
rnd_seed = rand(0:1000000)
Random.seed!(rnd_seed)
# Random.seed!(3232) # old bug instance
solomon_dataset_name = "R104_050"
solomon = load_solomon(solomon_dataset_name)
n_customers = length(solomon.nodes) - 1
dual_var = rand(0:20, n_customers)

# Random.seed!(0)

# For Debugging
include("debugging.jl")

# solomon_dataset_name = "C102_050"
# solomon = load_solomon(solomon_dataset_name)
# n_customers = length(solomon.nodes) - 1
# dual_var = rand(0:20, n_customers)
# dual_var = ones(n_customers) .* 10

# dual_var = [3.8237089201877836,5.935211267605691,3.5788732394366782,7.671830985915506,6.599999999999994,4.678873239436655,11.300000000000072,16.204225352112584,5.099999999999973,12.976291079812267,6.776291079812243,12.121126760563307,6.208450704225527,12.900000000000034,18.743661971831017,0.6999999999999886,18.164788732394427,12.098356807511898,10.623708920187784,14.301291079812213,15.335211267605604,8.099999999999994,8.43521126760563,8.878873239436668,23.042253521126618,14.214084507042223,0.5999999999999943,0.7999999999999545,26.52887323943669,18.499999999999915,4.376291079812155,14.477582159624472,7.247417840375427,17.850000000000094,29.799999999999997,22.476291079812142,4.199999999999996,20.352112676056265,17.021126760563277,6.28591549295777,8.099999999999994,12.75633802816887,31.16478873239444,5.300000000000068,13.80000000000009,14.600000000000009,1.5237089201877154,16.66478873239444,39.23521126760568,14.007042253521107,15.048122065727835,10.67629107981211,8.70000000000001,15.235915492957815,6.135915492957793,11.999999999999936,6.1563380281688715,4.756338028168925,4.3352112676056045,5.400000000000006,12.200000000000017,6.9525821596244235,26.847417840375446,19.40000000000003,37.94553990610343,15.521126760563313,30.90000000000004,7.721126760563319,10.123708920187838,7.798708920187778,20.40704225352111,6.578873239436646,9.799999999999972,16.33591549295781,5.300000000000011,11.928873239436705,5.300000000000026,5.599999999999959,6.77887323943666,3.70000000000001,2.7230046948355415,9.499999999999911,11.20000000000001,12.956338028168986,2.752112676056356,20.487323943661863,16.48732394366207,6.399999999999917,2.3999999999999773,21.001291079812308,6.299999999999997,1.700000000000017,11.700000000000017,9.142253521126836,1.0000000000000036,8.435211267605553,4.900000000000006,11.26478873239446,6.587323943661858,3.299999999999983] # R201_100
# dual_var = [2.200000000000003,5.599999999999952,1.1000000000000085,8.423809523809622,1.8000000000000114,9.380555555555656,3.5,10.158333333332985,6.0999999999999375,13.735317460317347,6.599999999999966,0.29999999999996163,6.400000000000006,10.251984126984016,16.325000000000088,1.2527777777780447,11.099999999999994,20.30000000000009,11.000000000000043,15.299999999999983,1.200000000000017,2.0726190476186197,35.595634920635035,9.463888888889038,21.800793650793302,0.16865079365103952,0.09999999999996587,3.731349206349016,25.20000000000003,17.400000000000034,3.5,15.299999999999997,7.595238095237917,8.295238095237977,29.904761904761997,13.052777777777813,1.600000000000028,23.500000000000085,11.709126984126762,10.447619047618819,15.636904761905036,11.584126984126765,28.427777777777656,3.7027777777785484,22.113888888888617,20.600000000000023,14.816666666666872,3.3305555555553386,37.372222222222206,3.304761904762046,7.8333333333336554,3.799999999999997,8.8,15.828571428571502,7.363888888889036,11.51428571428557,5.372222222222355,4.9523809523811835,2.60000000000007,8.730555555555316,17.116666666666205,5.336111111111094,25.50000000000002,20.361111111111263,47.14087301587317,12.59523809523806,13.200000000000003,7.499999999999993,11.636111111111113,13.09523809523806,8.100000000000001,0.5999999999999943,11.461904761904886,16.928571428571495,0.5857142857144382,15.000000000000014,4.300000000000033,16.64007936507921,4.399999999999977,2.500000000000121,3.490476190476002,3.8999999999999773,0.7000000000000028,16.01666666666718,1.8999999999999773,19.80555555555539,13.227777777777698,10.125000000000128,1.300000000000078,16.833333333333478,3.0527777777777754,2.8000000000000003,4.846825396825898,0.30000000000000426,1.2999999999999727,0.7999999999999687,7.178174603174295,1.6999999999999957,7.727777777777462,11.753174603174118] #R202_100

# dual_var = [4.599999999999994,6.6107556618580645,6.507937812990541,5.033395620001583,12.031500859556067,5.393557067045491,11.484098213618402,7.100000000000023,7.067975932431393,5.599999999999994,4.599999999999968,6.799999999999983,4.099999999999947,10.735395022049524,14.400000000000006,1.3999999999999897,17.599999999999994,9.777191867852551,7.381822258763812,5.540791538978972,2.8646049779504636,5.763771582330683,1.5000000000000178,11.235395022049524,9.564604977950488,11.299999999999983,2.0558225577396882,5.700000000000017,20.81116301666787,13.400000000000013,5.370509754092353,13.71841692204201,11.052612302862656,11.419519396068452,14.5,14.040896180581768,3.4000000000000363,18.956734434561607,15.30615516854769,14.776186561028444,8.099999999999994,10.648471485163338,24.419624037670967,8.700000000000019,13.494622169070894,18.38678899768276,13.882678077583972,26.37821959787736,18.49460348307046,12.600000000000023,9.491232528589592,9.983866507212749,3.1099222662382644,6.335395022049545,10.499999999999996,12.883922565213926,7.263177367516152,3.9000000000000465,2.599999999999966,6.325229837805605,3.2000000000000015,6.162183272292367,13.874512295388278,19.667478884819456,33.23208386277004,17.700000000000017,32.668790642051135,1.0826818147844754,8.279254802302148,11.168248748038039,11.176683608640403,7.711163016667868,4.399405785185504,8.733395620001625,5.39999999999997,8.11116301666788,9.900000000000006,4.856667164959989,3.656667164959971,7.317318185215502,6.597604454742546,6.564604977950532,5.584632633231141,11.890126317363125,5.052784214066731,15.199999999999994,8.900000000000006,6.780701098736721,2.6000000000000085,9.24079153897899,6.300000000000023,2.194622169070948,8.407324912175962,7.7253606398087316,7.116133492787222,4.004140817699197,6.211465729875209,3.694622169070905,5.8692615292621175,4.107324912175948] # R205_100

@show length(dual_var)

pg = solomon_to_espprc(solomon, dual_var)
print_pct_neg_arcs(pg)

##################################################

@info("ESPPRC $(solomon_dataset_name) testing...")
print("Pulse     : "); @time pulse = solveESPPRC(pg, method="pulse")
print("Mono      : "); @time mono0= solveESPPRC(pg, method="monodirectional")
print("Mono DSSR : "); @time mono1 = solveESPPRC(pg, method="monodirectional", DSSR=true)
print("Bi        : "); @time bidi0= solveESPPRC(pg, method="bidirectional")
print("Bi   DSSR : "); @time bidi1 = solveESPPRC(pg, method="bidirectional", DSSR=true)


@show pulse.cost, pulse.load, pulse.time
@show mono0.cost, mono0.load, mono0.time
@show mono1.cost, mono1.load, mono1.time
@show bidi0.cost, bidi0.load, bidi0.time
@show bidi1.cost, bidi1.load, bidi1.time
@show pulse.path
@show mono0.path
@show mono1.path
@show bidi0.path
@show bidi1.path

# show_details(bidi0.path, pg)

@testset "ESPPRC $(solomon_dataset_name) Test" begin
    @test isapprox(pulse.cost, mono0.cost, atol=1e-7)
    @test isapprox(mono0.cost, mono1.cost, atol=1e-7)
    @test isapprox(pulse.cost, bidi0.cost, atol=1e-7)
    @test isapprox(bidi0.cost, bidi1.cost, atol=1e-7)
end
@show rnd_seed
println("done.")

end


############################################################
# max_neg = 20
# @info("ESPPRC $(solomon_dataset_name) testing with max_neg_routes=$(max_neg)...")

# @time sol, neg_sols = solveESPPRC_vrp(pg, method="pulse", max_neg_routes=max_neg)
# @time lab1, neg_labs1 = solveESPPRC_vrp(pg, method="monodirectional", max_neg_routes=max_neg)
# @time lab1d, neg_labs1d = solveESPPRC_vrp(pg, method="monodirectional", max_neg_routes=max_neg, DSSR=true)

# # @time lab2, neg_labs2 = solveESPPRC(pg, method="bidirectional", max_neg_routes=max_neg)

# @testset "ESPPRC $(solomon_dataset_name) Test with max_neg_routes" begin
#     @test length(neg_sols) <= max_neg
#     @test length(neg_labs1) <= max_neg
#     @test length(neg_labs1d) <= max_neg
#     # @test length(neg_labs2) <= max_neg
#     for l in neg_sols
#         @test l.cost < 0.0
#     end
#     for l in neg_labs1
#         @test l.cost < 0.0
#     end
#     for l in neg_labs1d
#         @test l.cost < 0.0
#     end
#     # for l in neg_labs2
#     #     @test l.cost < 0.0
#     # end
# end
