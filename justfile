run-sample: reset-samples
    mix env.diff --fix --file test/samples/t1.env --dist test/samples/t1.env.dist

reset-samples:
    @cp -v test/samples/t1.env.sample test/samples/t1.env