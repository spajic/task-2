# Task number 2

## Description
In this task it is necessary to further optimize the task of the 1st week with the use of the profiling tools `CPU` and the explanations made in the 2nd lecture.

### What should be done
- Build and analyze the `ruby-prof` report in the` Flat` mode;
- Build and analyze the `ruby-prof` report in` Graph` mode;
- Build and analyze the `ruby-prof` report in` CallStack` mode;
- Build and analyze the `ruby-prof` report in` CallTree` mode with visualization in `QCachegrind`;
- To profile the working process `rbspy`;
- Build and analyze the `flamegraph` report using` rbspy`;
- Add to the program `ProgressBar`;
- Learn to use `Valgrind massif` with` massif-visualizer`. Build a memory usage profile for the final version of your program and add a screenshot to `PR`;
- Write at least the simplest performance test: `assert`, that the execution time of the script is less than the value, which is slightly longer than real, in order not to give false positives;

### The main thing
You need to practice working methodically according to the scheme with feedback loops:
- built a report by some of the profilers
- realized it
- understand what is the biggest growth point
- made minimal changes to use only this growth point
- rebuilt the report, make sure that the problem is solved
- calculated the metric - estimated how change affected the metric
- recorded the results
- commit
- proceed to the next iteration