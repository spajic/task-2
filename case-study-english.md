# Case-study оптимизации

## Актуальная проблема
В нашем проекте возникла серьёзная проблема.

Необходимо было обработать файл с данными, чуть больше ста мегабайт.

У нас уже была программа на `ruby`, которая умела делать нужную обработку.

Она успешно работала на файлах размером пару мегабайт, но для большого файла она работала слишком долго, и не было понятно, закончит ли она вообще работу за какое-то разумное время.

Я решил исправить эту проблему, оптимизировав эту программу.

## Формирование метрики
Для того, чтобы понимать, дают ли мои изменения положительный эффект на быстродействие программы я придумал использовать такую метрику: Amount of iterations per second in files of different sizes.

## Анализ зависимости метрики от входных данных
In order to track metrics dependency on the amount of data, we will use script that checks this metrics in differents
files, where files sizes are: 0.25MB, o.5MB and 1MB.
For measuring this metric we will use `scripts/asymptotics.rb` script.

We will use benchmark and benchmark/ips

Results of these measurments for `benchmark/ips` (iterations per seconds) are the following:

```
Calculating -------------------------------------
      Process 0.25Mb      1.145  (± 0.0%) i/s -      6.000  in   5.240788s
       Process 0.5Mb      0.291  (± 0.0%) i/s -      2.000  in   6.891300s
         Process 1Mb      0.039  (± 0.0%) i/s -      1.000  in  25.659316s

Comparison:
      Process 0.25Mb:        1.1 i/s
       Process 0.5Mb:        0.3 i/s - 3.94x  slower
         Process 1Mb:        0.0 i/s - 29.38x  slower
```

As we can see from the above calculations the when we iterate the file of 0.5MB, we receive almost 4 times slower iterations per seconds metric comparing to the 0.25MB size file. Processing 1MB file is approximately 29 times slower. Therefore, we can observe that increasing file size in 2 times, will cause dramatic increase in processing time.

Results of these measurments using `Benchmark.realtime` are the following:

```
data/data_025mb.txt
Finish in 0.85
data/data_05mb.txt
Finish in 4.8
data/data_1mb.txt
Finish in 27.48
```

## Initial metrics
I decided to work with 1MB file where initial i/s is 0.039 and realtime processint is approximately 27 seconds.


## Гарантия корректности работы оптимизированной программы
Программа поставлялась с тестом. Выполнение этого теста позволяет не допустить изменения логики программы при оптимизации.

## Feedback-Loop
Для того, чтобы иметь возможность быстро проверять гипотезы я выстроил эффективный `feedback-loop`, который позволил мне получать обратную связь по эффективности сделанных изменений за *время, которое у вас получилось*

Вот как я построил `feedback_loop`: *как вы построили feedback_loop*

## Вникаем в детали системы, чтобы найти 20% точек роста
Для того, чтобы найти "точки роста" для оптимизации я воспользовался *инструментами, которыми вы воспользовались*
- benchmark and benchmark/ips
- ruby-prof gem (flat)

## Initial Measurements

Вот какие проблемы удалось найти и решить:

From RubyProf::Flat report, we can identify 2 main problems:
```
%self      total      self      wait     child     calls  name
 94.07     29.643    29.643     0.000     0.000     3875   Array#select

  2.98     31.432     0.938     0.000    30.494    25408  *Array#each
```
 %self - The percentage of time spent in this method, derived from self_time/total_time
  total - The time spent in this method and its children.
  self  - The time spent in this method.
  wait  - amount of time this method waited for other threads
  child - The time spent in this method's children.
  calls - The number of times this method was called.
  name  - The name of the method.

We can see that `#select` method on array is calld 3875 times and time spent in this method is 29.6
On the other hand, `#each` method is called 25408 time and most of the time is spent in this method's children.


### Ваша находка №1
О вашей находке №1

### Ваша находка №2
О вашей находке №2

### Ваша находка №X
О вашей находке №X

## Результаты
В результате проделанной оптимизации наконец удалось обработать файл с данными.
Удалось улучшить метрику системы с *того, что у вас было в начале, до того, что получилось в конце*

*Какими ещё результами можете поделиться*

## Защита от регресса производительности
Для защиты от потери достигнутого прогресса при дальнейших изменениях программы сделано *то, что вы для этого сделали*
