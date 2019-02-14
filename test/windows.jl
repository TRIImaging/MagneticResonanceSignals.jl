@testset "windows" begin
    A = AxisArray([1.0 2.0;
                   3.0 4.0], Axis{:time}(1:2), Axis{:channel}(1:2))

    # Window application.
    # Test with triangular window; should be evaluated to give [1, 0.5] along
    # time dimension of length 2.
    testwindow(t) = 1-t
    # Can use Axis
    @test apply_window(A, Axis{:time}=>testwindow) == [1    2;
                                                       1.5  2]
    @test apply_window(A, Axis{:channel}=>testwindow) == [1    1;
                                                          3.0  2]
    # And integer dimension number
    @test apply_window!(A, 2, testwindow) == [1    1;
                                              3.0  2]
    # Test `A` is modified in place.
    @test A == [1    1;
                3.0  2]

    @test sinebell.((0:2)/3, skew=1.5, pow=2) == [0, 0.32311591129511724, 0.9807289153754679]
end

