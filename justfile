run-sample: reset-samples
    mix env.diff --fix --file test/samples/t1.env --dist test/samples/t1.env.dist

reset-samples:
    @cp -v test/samples/t1.env.original test/samples/t1.env
    @cp -v test/samples/t1.env.dist.original test/samples/t1.env.dist