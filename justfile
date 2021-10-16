run-sample:
    mix env.diff --fix --file test/samples/t1.env --dist test/samples/t1.env.dist

rest-samples:
    @cp -v test/samples/t1.env.sample test/samples/t1.env