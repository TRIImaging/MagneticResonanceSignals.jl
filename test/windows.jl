@testset "windows" begin
    A = AxisArray([1.0 2.0;
                   3.0 4.0], Axis{:time}(1:2), Axis{:channel}(1:2))
    # Triangular window; should be evaluated to give
    # [1, 0.5] along time dimension of length 2.
    testwindow(t) = 1-t
    @test MRWindows.apply_window!(A, testwindow) == [1    2;
                                                     1.5  2]

    A = AxisArray([1.0, 1.0, 1.0], Axis{:time}(1:3))
    @test sinebell(A, skew=1.5, n=2) == [0, 0.32311591129511724, 0.9807289153754679]
end

