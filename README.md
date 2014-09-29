Project-2
=========

Serial vs. Naïve prefix scan (please see readme.pdf)



Size1000500010000500001000005000001000000500000010000000Serial0.0068420.0282250.0581610.2535990.492231.987314.2838122.12343.947Naïve0.3809920.759040.4976321.11761.356543.506856.6593335.50350.145952
Runtime (microseconds) of serial vs. naïve GPU implementation of prefix scan

It’s difficult to see from the graph itself, but a look at the table will make it clear that the serial implementation scales much more quickly than my naïve GPU implementation.  This is because the GPU implementation roughly scales on log(n), one wave per depth, while the serial implementation is on the order of n, since it makes n calculations on the array to get the final result.


Naïve vs. Shared Memory Prefix Scan

-N/A-
