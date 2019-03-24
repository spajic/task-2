# Case-study Задание №2

### Построить и проанализировать отчёт ruby-prof в режиме Flat
Проанализируем этим отчетом затрачиваемое время выполнения (режим wall_time)
```
Measure Mode: wall_time
Thread ID: 70208069025840
Fiber ID: 70208065413220
Total: 0.161745
Sort by: self_time

 %self      total      self      wait     child     calls  name
 19.77      0.032     0.032     0.000     0.000    20000   String#split
 16.45      0.125     0.027     0.000     0.098        5   Array#each
```
Из отчета видно, что больше всего времени мы тратим на разбиение строк(`String#split`) именно эта функция первый кандидат на улучшение, если нам не будет хватать скорости обработки. Как вариант можно попробовать заменить связку `File.readlines` + `split` на парсинг `CSV`

Следующий "пожиратель" скорости это `Array#each`, который занимает 16.45% времени выполнения, но при этом вызывается всего 5 раз. Как вариант оптимизации, можно попробовать сократить один вызов `each` за счет отказа от отдельного прохода для выборки пользователей в масcив `users`, а потом обход `users` для создания `user_object`

[Полный текст отчета ](./tools/reports/ruby_prof_flat_allocations_profile.txt)


### Построить и проанализировать отчёт ruby-prof в режиме Graph
Проанализируем этим отчетом потребление процессора (режим cpu_time)

![ruby-prof в режиме Graph](./tools/reports/RubyProfGraph.png "ruby-prof в режиме Graph")

В этом отчете первый кандидат на улучшение `Array#each` 80.94% в колонке %Total. Но 16.37% в колонке %Self подсказывают, что большую часть времени происходит ожидание других методов, из которых самый ресурсоемкий это `String#split` 20.73%

[Полный текст отчета ](./tools/reports/ruby_prof_graph_allocations_profile.html)

### Построить и проанализировать отчёт ruby-prof в режиме CallStack
Еще раз проанализируем этим отчетом затрачиваемое время выполнения (режим wall_time)

![ruby-prof в режиме CallStack](./tools/reports/RubyProfCallStack.png "ruby-prof в режиме CallStack")

А из этого отчета, получается, что самый долгий метод это `collect_stats_from_users`, что идет в разрез с выводами из отчета 1!

[Полный текст отчета ](./tools/reports/ruby_prof_stack_printer_allocations_profile.html)

### Построить и проанализировать отчёт ruby-prof в режиме CallTree c визуализацией в QCachegrind
Еще раз проанализируем этим отчетом затрачиваемое время выполнения (режим wall_time)

![ruby-prof в режиме QCachegrind-1](./tools/reports/RubyProfQCachegrind-1.png "ruby-prof в режиме QCachegrind")

А из этого отчета, получается, что самый долгий метод это `parse_file` и дальше цепочка замедляющих его вызовов выглядит как `Array#each` -> `calc_stat `

![ruby-prof в режиме QCachegrind-2](./tools/reports/RubyProfQCachegrind-2.png "ruby-prof в режиме QCachegrind")

[Сырые данные отчета ](./tools/reports/profile.callgrind.out.59260)


### Профилировать работающий процесс rbspy
Результат профилирования работающей программы выглядит вот так
```
# sudo rbspy record --pid 66589
Time since start: 46s. Press Ctrl+C to stop.
Summary of profiling data so far:
% self  % total  name
 68.70   100.00  <c function> - unknown
  6.66     7.85  block in create_users_objects - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  6.07    31.39  calc_stat - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  3.58    10.17  parse_session - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  2.58     3.58  block in dates - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  1.97    19.18  block in parse_file - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  1.91     5.42  block in find_all_browsers - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  1.52     1.52  block in work - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  1.47     2.02  block in used_ie - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  1.39     1.39  block in count_browsers - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  1.13    32.52  block in collect_stats_from_users - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.87     1.15  parse_user - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.48     1.43  block in browsers_list - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.33     0.78  block in time_from_sesions - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.30     0.30  initialize - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.28     0.28  block in always_used_chrome - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.17    11.66  dates - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.17     1.67  time_from_sesions - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.15     0.37  longest_session - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
  0.11     5.48  browsers - /Users/vikont/RoR_Project/thinknetica/RailsOptimization/task-2/task-2.rb
Wrote raw data to /Users/vikont/.cache/rbspy/records/rbspy-2019-03-24-6UxKcbpDNr.raw.gz
Writing formatted output to /Users/vikont/.cache/rbspy/records/rbspy-2019-03-24-6eLtsXXH6Z.flamegraph.svg
```

### Построить и проанализировать отчёт flamegraph с помощью rbspy
График дает данные, не противоречащие с отчетом  ruby-prof в режиме CallStack, которые мы получили выше.
![rbspy flamegraph](./tools/reports/rbspy-flamegraph.png "rbspy flamegraph")

[Сырые данные отчета ](./tools/reports/rbspy-2019-03-24-tr8u1tpfx8.flamegraph.svg)

### Добавить в программу ProgressBar

### Научиться пользоваться Valgrind massif с massif-visualizer. Построить профиль использования памяти для итоговой версии вашей программы и добавить скриншот в PR
График утилизации памяти при помощи massif-visualizer показывает линейный рост - вот и славно!
![Valgrind massif с massif-visualizer](./tools/reports/massif-visualizer.png "Valgrind massif с massif-visualizer")

[Сырые данные отчета ](./tools/reports/massif.out.4381)
