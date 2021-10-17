run-samples: reset-samples run-samples-as-is

run-samples-as-is:
    # mix env.diff --fix --file test/samples/t1.env --dist test/samples/t1.env.dist
    mix env.diff --fix --file test/samples/t1.env --file test/samples/t2.env --dist test/samples/t1.env.dist --dist test/samples/t2.env.dist

reset-samples:
    @cp -v test/samples/ori-t1.env test/samples/t1.env
    @cp -v test/samples/ori-t1.env.dist test/samples/t1.env.dist
    @cp -v test/samples/ori-t2.env test/samples/t2.env
    @cp -v test/samples/ori-t2.env.dist test/samples/t2.env.dist