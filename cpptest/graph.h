#include <iostream>
#include <climits>
#include <vector>
#include <algorithm>
#include <string>
#include <cmath>
#include <numeric>

const int max_num = 0x3f3f3f3f;
const double err = 1e-3;
const int maxn = 100 + 10;

class Node {
public:
    int x, y, demand, twl, twu, service_time;
    bool label;
    double best_cost;
    std::vector<int> outgoing_index;
    Node(int x, int y, int d, int twl, int twu, int t) \
        : x(x), y(y), demand(d), twl(twl), twu(twu), service_time(t), label(false), best_cost(double(max_num)) {}
};


class Edge {
public:
    int from, to;
    double cost, time;
    int next;
    Edge(int from, int to, double cost, double time, std::vector<int>& head, int& index) \
        : from(from), to(to), cost(cost), time(time) {
        next = head[from];
        head[from] = index++;
    }
};


// 链式前向星
class Graph {
private:
    struct T {
        int ix;
        double cost;
        T(int i, double c) : ix(i), cost(c) {}
    };
    std::vector<double> fixed_rand = {0.0,3.8237089201877836,5.935211267605691,3.5788732394366782,7.671830985915506,6.599999999999994,4.678873239436655,11.300000000000072,16.204225352112584,5.099999999999973,12.976291079812267,6.776291079812243,12.121126760563307,6.208450704225527,12.900000000000034,18.743661971831017,0.6999999999999886,18.164788732394427,12.098356807511898,10.623708920187784,14.301291079812213,15.335211267605604,8.099999999999994,8.43521126760563,8.878873239436668,23.042253521126618,14.214084507042223,0.5999999999999943,0.7999999999999545,26.52887323943669,18.499999999999915,4.376291079812155,14.477582159624472,7.247417840375427,17.850000000000094,29.799999999999997,22.476291079812142,4.199999999999996,20.352112676056265,17.021126760563277,6.28591549295777,8.099999999999994,12.75633802816887,31.16478873239444,5.300000000000068,13.80000000000009,14.600000000000009,1.5237089201877154,16.66478873239444,39.23521126760568,14.007042253521107,15.048122065727835,10.67629107981211,8.70000000000001,15.235915492957815,6.135915492957793,11.999999999999936,6.1563380281688715,4.756338028168925,4.3352112676056045,5.400000000000006,12.200000000000017,6.9525821596244235,26.847417840375446,19.40000000000003,37.94553990610343,15.521126760563313,30.90000000000004,7.721126760563319,10.123708920187838,7.798708920187778,20.40704225352111,6.578873239436646,9.799999999999972,16.33591549295781,5.300000000000011,11.928873239436705,5.300000000000026,5.599999999999959,6.77887323943666,3.70000000000001,2.7230046948355415,9.499999999999911,11.20000000000001,12.956338028168986,2.752112676056356,20.487323943661863,16.48732394366207,6.399999999999917,2.3999999999999773,21.001291079812308,6.299999999999997,1.700000000000017,11.700000000000017,9.142253521126836,1.0000000000000036,8.435211267605553,4.900000000000006,11.26478873239446,6.587323943661858,3.299999999999983};
    std::vector<int> head;
    double euclid_dist(int x1, int y1, int x2, int y2);
    void rng(std::vector<int>& rd, int num, int l, int r);
    void outgoing_edge_sort();
public:
    std::vector<Node> node_list;
    std::vector<Edge> edge_list;

    Graph(std::vector<std::vector<int>>& data, std::vector<double>& dual_var);
    int get_edge(int u, int v);
    void reset_label();
    void show_graph();
};










