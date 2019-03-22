# Case-study оптимизации

## Актуальная проблема
В нашем проекте возникла серьёзная проблема.

Необходимо было обработать файл с данными, чуть больше ста мегабайт.

У нас уже была программа на `ruby`, которая умела делать нужную обработку.

Она успешно работала на файлах размером пару мегабайт, но для большого файла она работала слишком долго, и не было понятно, закончит ли она вообще работу за какое-то разумное время.

Я решил исправить эту проблему, оптимизировав эту программу.

## Формирование метрики
Для того, чтобы понимать, дают ли мои изменения положительный эффект на быстродействие программы я придумал использовать такую метрику:
  *Количество потребляемой памяти выполняемой программы на данных с размером 0.25мб*
  *Количество итераций в секунду (ips) выполнения программы на данных с размером 0.25мб*

## Анализ асимптотики
Постараюсь оценить, сколько времени и памяти займет обработка большого файла.
Для этого соберу данные на файлах различного объема и попробую понять закономерность.

Для сбора данных для текущей оценки я буду использовать собственный скрипт: `asymptotics.rb`
Вывод исходной версии программы:
* CPU:
```
Calculating -------------------------------------
    Process 0.0625Mb      7.438  (± 0.0%) i/s -     38.000  in   5.115027s
     Process 0.125Mb      2.729  (± 0.0%) i/s -     14.000  in   5.133869s
      Process 0.25Mb      0.710  (± 0.0%) i/s -      4.000  in   5.635852s
       Process 0.5Mb      0.135  (± 0.0%) i/s -      1.000  in   7.384139s
         Process 1Mb      0.034  (± 0.0%) i/s -      1.000  in  29.204867s
         Process 2Mb      0.008  (± 0.0%) i/s -      1.000  in 123.505202s

Comparison:
    Process 0.0625Mb:        7.4 i/s
     Process 0.125Mb:        2.7 i/s - 2.73x  slower
      Process 0.25Mb:        0.7 i/s - 10.48x  slower
       Process 0.5Mb:        0.1 i/s - 54.92x  slower
         Process 1Mb:        0.0 i/s - 217.22x  slower
         Process 2Mb:        0.0 i/s - 918.60x  slower
```
* Memory
```
Total memory for date_large.0065.txt: 15 MB
Total memory for date_large.0125.txt: 47 MB
Total memory for date_large.025.txt: 155 MB
Total memory for date_large.05.txt: 543 MB
Total memory for date_large.1.txt: 2027 MB
```

Просматривается тендценция: при увеличении объема исходных данных в два раза, время выполнения замедляется в ~5 раз,
потребления памяти в ~3.5 раза.

Данные в таблице: https://docs.google.com/spreadsheets/d/1DfB0HbFFRAUm6YPCdbOkFzYmOmOlYNpgodV1mZccwcM/edit#gid=0

Асимптотика по CPU: `5^(log2(size))`
Асимптотика по Memory: `3.5^(log2(size))`

## Гарантия корректности работы оптимизированной программы
Программа поставлялась с тестом. Выполнение этого теста позволяет не допустить изменения логики программы при оптимизации.

## Feedback-Loop
Для того, чтобы иметь возможность быстро проверять гипотезы я выстроил эффективный `feedback-loop`, который позволил мне получать обратную связь по эффективности сделанных изменений за ~5 секунд

Для этого был написан скрипт `feedback-loop.rb`, который
* выполняет замер метрики
* проверяет прохождения теста на валидность данных
* проверяет прохождения теста на метрики
* выводит данные

## Вникаем в детали системы, чтобы найти 20% точек роста
Для того, чтобы найти "точки роста" для оптимизации я воспользовался:

### Valgrind Massif & Massif Visualizer
Найдем точки роста памяти через данные 2 инструмента. Для анализа данных буду использовать файл объемом 0.5МБ
Для наглядности и понимания картины, я вложил скриншоты в папку `screenshots` с исходными и оптимизированными данными.

Судя по полученным данным, видно, что память растет линейно.

### Профилирование GC
Отключение ***GC*** никак не повлияло на метрику. Все дальнейшие тесты буду проводится с отключенным ***GC***

Вот какие проблемы удалось найти и решить

### Находка №1
Асимптотический анализ показал, что расход памяти растет пропорционально `3.5^(log2(size))`
Необходимо найти место, где расходуется наибольшее кол-во памяти.
Для этого я воспользуюсь профилировщиком ***memory_profiler***

Отчет ***memory_profiler***, что больше всего памяти выделяется для обработку массивов:
```
allocated memory by class
-----------------------------------
 684034216  Array
  21029564  String
  13325984  Hash
   4163440  MatchData
    782280  Date
     78800  User
```
Основная проблема находится в строке *53* и *99*:
```
allocated memory by location
-----------------------------------
 473618912  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:53
 171311200  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:99
  16202432  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:52
  15689032  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:101
```

В данной *строке 53* находится cбора сессий и пользователей:
```
  file_lines.each do |line|
    cols = line.split(',')
    users = users + [parse_user(line)] if cols[0] == 'user'
    sessions = sessions + [parse_session(line)] if cols[0] == 'session'
  end
```
Для решении проблемы, мы не будем создавать дополнительные массивы, а будем добавлять в текущий

В *строке 99* происходит отбор сессий по пользоватлю:
```
  users.each do |user|
    attributes = user
    user_sessions = sessions.select { |session| session['user_id'] == user['id'] }
    user_object = User.new(attributes: attributes, sessions: user_sessions)
    users_objects = users_objects + [user_object]
  end
```
Для решения этой проблемы, мы будем собирать сессия пользователя заранее в *Hash*

#### Эффект изменения
После внесенных изменений, видно, что они эффективно повлияли на метрику *memory*.
Сократилось в 2-3 раза выделение памяти.

Обновленная метрика:
```
Total memory for date_large.0065.txt: 6 MB
Total memory for date_large.0125.txt: 14 MB
Total memory for date_large.025.txt: 30 MB
Total memory for date_large.05.txt: 66 MB
Total memory for date_large.1.txt: 161 MB
```

Необходимо снова собрать отчет через ***memory_profiler***
И судя по нему, по-прежнему, большое количество памяти выделяется для обработки массива:
```
  24514552  Array
  21108404  String
  13383424  Hash
   4163440  MatchData
    782280  Date
     78800  User
```

И стоит обратить внимание на строки *104* и *141*:
```
allocated memory by location
-----------------------------------
  15689032  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:104
  11808644  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:141
   6082000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:51
   5215200  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:26
```

*Строка 104* содержит сбор user_objects:
```
  users.each do |user|
    attributes = user
    user_sessions = sessions[user['id']]
    user_object = User.new(attributes: attributes, sessions: user_sessions)
    users_objects = users_objects + [user_object]
  end
```
Решение: переписать массив users заменив элементы экземплярами класса User

*Строка 141* содержит сбор и обработку дат:
```
  collect_stats_from_users(report, users) do |user|
    { 'dates' => user.sessions.map{|s| s['date']}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 } }
  end
```
Решение: отказаться от несольких последовательных вызовов Array#map

#### Эффект изменения
Дало сокращение потребление памяти особенно на большом объеме данных.

Обновленная метрика:
```
Total memory for date_large.0065.txt: 6 MB
Total memory for date_large.0125.txt: 12 MB
Total memory for date_large.025.txt: 26 MB
Total memory for date_large.05.txt: 51 MB
Total memory for date_large.1.txt: 101 MB
```

Новый репорт от ***memory_profiler*** показывает нам, что теперь потребление памяти уходит на работу со строками.
```
  21108404  String
  13383424  Hash
   8044960  Array
   4163440  MatchData
    782280  Date
     78800  User
```
А также советует проверить наш код по следующим строкам:
```
  11028124  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:138
   6082000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:51
   5215200  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:26
   3199840  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:40
```

*Строка 138* содержит обработку дат:
```
  collect_stats_from_users(report, users) do |user|
    { 'dates' => user.sessions.map! { |s| Date.parse(s['date']).iso8601 }.sort!.reverse! }
  end
```
Решение: заменить `Date#parse` на `Date.strptime`. Т.к. даты имеют одинаковый формат.

#### Эффект изменения
Сократило потребление памяти

Обновленная метрика:
```
Total memory for date_large.0065.txt: 5 MB
Total memory for date_large.0125.txt: 11 MB
Total memory for date_large.025.txt: 22 MB
Total memory for date_large.05.txt: 43 MB
Total memory for date_large.1.txt: 88 MB
```

После очередного сбора статистики по памяти, проблема с выделением памяти на работу со строками осталась.
```
  18064917  String
  13383424  Hash
   8044960  Array
    782280  Date
    425880  MatchData
```
Но теперь стоит обратить внимание на другие строки:
```
   6082000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:51
   5215200  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:26
   4242960  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:138
   3199840  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:40
   2979766  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:141
```

*Строки 51 и 26*: частое использование `Array#split`
```
  file_lines.each do |line|
    cols = line.split(',')
    users << parse_user(line) if cols[0] == 'user'
    sessions[cols[1]] << parse_session(line) if cols[0] == 'session'
  end
```
Решение: проверить код на необходимость использование данной функции

#### Эффект изменения
Сократило потребление памяти до 18МБ
Обновленная метрика:
```
Total memory for date_large.0065.txt: 4 MB
Total memory for date_large.0125.txt: 10 MB
Total memory for date_large.025.txt: 18 MB
Total memory for date_large.05.txt: 37 MB
Total memory for date_large.1.txt: 74 MB
```

Статистика по ***memory_profilter***
```
  14549917  String
  13383424  Hash
   5477960  Array
    782280  Date
    425880  MatchData
```
И топ проблемных строк c выделением памяти в коде:
```
   6082000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:49
   4242960  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:136
   3199840  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:38
   2979766  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:139
   2758000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:36
```

В *строке 49* идет обработка каждой строки файла через String#split,
пока нет возможности ее сильнее оптимизировать

В *строке 136* мы преобразуем дату в нужный формат,
пока нет возможности оптимизровать строку для выделения меньшего кол-ва памяти.

В *строке 38* мы неоптимизировано работаем с Hash и со String
```
def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    user_key = "#{user.attributes['first_name']}" + ' ' + "#{user.attributes['last_name']}"
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge(block.call(user))
  end
end
```
Решение: использовать *Hash#merge!* для объединения хэшей и исправить конкатенацию строки

#### Эффект изменения
Сократило потребление памяти до 16МБ
Обновленная метрика:
```
Total memory for date_large.0065.txt: 3 MB
Total memory for date_large.0125.txt: 8 MB
Total memory for date_large.025.txt: 16 MB
Total memory for date_large.05.txt: 32 MB
Total memory for date_large.1.txt: 62 MB
```
Статистика по ***memory_profilter***
```
  12343517  String
  10184144  Hash
   5477960  Array
    782280  Date
    425880  MatchData
```
И топ проблемных строк c выделением памяти в коде:
```
   6082000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:49
   4242960  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:136
   2979766  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:139
   2520680  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:32
   1637943  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:43
```

В *строке 139* происходит запись данных в файл.
На данном этапе нет возможности оптимизировать по памяти эту часть кода.

В *строке 32* происходит сбор данных о сессии пользователя.
На данном этапе нет возможности оптимизировать по памяти эту часть кода.

В *строке 43* - построчное чтение файла в переменную
```
  file_lines = File.read(file).split("\n")
```
Исправления в целях оптимизации по памяти не дали какие-либо существенные результаты.

В *строке 121* мы неоптимизировано собираем информацию о браузерах пользователя.
```
{ 'browsers' => user.sessions.map {|s| s['browser']}.map {|b| b.upcase}.sort.join(', ') }
```
Решение: чтобы не выделять доп-ую память, отказаться от вторичного использование *Array#map*
и использовать *String#upcase!* и *Array#sort!*

#### Эффект изменения
Сократило потребление памяти до 15МБ
Обновленная метрика:
```
Total memory for date_large.0065.txt: 3 MB
Total memory for date_large.0125.txt: 8 MB
Total memory for date_large.025.txt: 15 MB
Total memory for date_large.05.txt: 31 MB
Total memory for date_large.1.txt: 62 MB
```
Статистика по ***memory_profilter***
```
  12361822  String
  10184144  Hash
   5031200  Array
    782280  Date
    425880  MatchData
```
И топ проблемных строк c выделением памяти в коде:
```
   6082000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:49
   4677560  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:136
   2979766  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:139
   2520680  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:32
   1521384  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:48
```

Так же у нас есть отчет по строкам, где выделяются большое количество объектов:
```
    100710  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:49
     56095  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:136
     36493  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:139
     13790  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:36
     12836  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:48
```

На данный момент не можем оптимизировать строки: 49, 136, 139

В *строке 36* мы определяем ключ пользователя. Из-за того, что это происходит довольно часто,
мы выделяем память и создаем большое кол-во объектов.
```
    user_key = "#{user.attributes['first_name']} #{user.attributes['last_name']}"
```
Решение: сбор отчета пользователя сделать атомарным

#### Эффект изменения
Сократило потребление памяти до 13МБ
Обновленная метрика:
```
Total memory for date_large.0065.txt: 3 MB
Total memory for date_large.0125.txt: 6 MB
Total memory for date_large.025.txt: 14 MB
Total memory for date_large.05.txt: 27 MB
Total memory for date_large.1.txt: 54 MB
```
Статистика по ***memory_profilter***
```
  11436117  String
   7441904  Hash
   5165752  Array
    782280  Date
    437080  MatchData
```
И топ проблемных строк c выделением памяти в коде:
```
   6082000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:49
   4242960  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:119
   2979766  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:123
   2520680  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:32
   1637943  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:43
```

Так же у нас есть отчет по строкам, где выделяются большое количество объектов:
```
    100710  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:49
     45230  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:119
     36493  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:123
     12840  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:43
     12835  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:50
```

В *строке 90* мы собираем данные о браузерах пользователя.
Решение: сократить кол-во вызовов *Array#map*, создать обработку браузеров в одном цикле.

#### Эффект изменения
Сократило потребление памяти до ~12МБ
Обновленная метрика:
```
Total memory for date_large.0065.txt: 2 MB
Total memory for date_large.0125.txt: 7 MB
Total memory for date_large.025.txt: 13 MB
Total memory for date_large.05.txt: 26 MB
Total memory for date_large.1.txt: 52 MB
```
Статистика по ***memory_profilter***
```
  10669837  String
   7441904  Hash
   4594832  Array
    782280  Date
    437080  MatchData
```
И топ проблемных строк c выделением памяти в коде:
```
   6082000  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:49
   4242960  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:115
   2979766  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:119
   2520680  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:32
   1637943  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:43
```

Так же у нас есть отчет по строкам, где выделяются большое количество объектов:
```
    100710  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:49
     45230  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:115
     36493  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:119
     12840  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:43
     12835  /Users/alec/Projects/ruby/thinknetika/task-2/task-2.rb:50
```

В *строке 113* мы проверяем на использование IE:
```
'usedIE' => user.sessions.map{|s| s['browser']}.any? { |b| b =~ /INTERNET EXPLORER/ }
```
Решение: изменить проверку по regexp на *String#start_with?* и вынести в константу название браузера

В *строке 111* мы собираем информацию о длительности сессии, используя дважду *Array#map* и
неоптимизированную конкатенацию строк
Решение: вынести *String#to_i* в первоначальное создание хэша с сессиями и
убрать вторичное использование *Array#map*, исправить конкатенацию строки.
Также написать метод для сбора данных по браузерам в один цикл.

В *строке 115* мы проверяем на использование Chrome браузера, используя неоптимальную проверку, как и с IE
Решение по этому кейсу будет, такое же как в случае с IE. Также написать метод для сбора данных по браузерам
в один цикл.

Так же есть смысл вынести в константы строки, на которые акцентирует внимание ***memory_profiler***

#### Эффект изменения
Сократило потребление памяти до ~12МБ
Обновленная метрика:
```
Total memory for date_large.0065.txt: 2 MB
Total memory for date_large.0125.txt: 6 MB
Total memory for date_large.025.txt: 13 MB
Total memory for date_large.05.txt: 24 MB
Total memory for date_large.1.txt: 48 MB
```

Чтобы посмотреть, новые возможности оптимизации памяти, я воспользуюсь иструментов ***ruby-prof***
По отчету видно, что основное потребление памяти происходит при обработке *Array#each* - *47.12%*
При этом основное потребление связано с методом *collect_stats_from_user* - *51.96%*
```
def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    user_key = "#{user.attributes['first_name']} #{user.attributes['last_name']}"
    report['usersStats'][user_key] ||= {}
    report['usersStats'][user_key] = report['usersStats'][user_key].merge!(block.call(user))
  end
end
```
Решение: заменить *Array#each* на *Object#while* с удалением элементов из массива

#### Эффект изменения
Сократило потребление памяти на ~1МБ
Обновленная метрика:
```
Total memory for date_large.0065.txt: 2 MB
Total memory for date_large.0125.txt: 6 MB
Total memory for date_large.025.txt: 12 MB
Total memory for date_large.05.txt: 25 MB
Total memory for date_large.1.txt: 48 MB
```

По текущему отчету видно, что основными проблемами по памяти, являются:
* Object#collect_stats_from_user - 25.09%
* Array#each - 21.71%
* Hash#to_json - 18.92%
* Array#map - 16.33%

Чтобы понимать причину возникновения утечки памяти с *Array#each* все части кода,
где используется этот метод, я вынесу в отдельные методы. После чего по отчету становится
ясным, что момент обработки файла является основной проблемой для данного кейса.
Решение: использовать *File#open* c *IO.each_line* вместо *File.read* и *Array#each*

#### Эффект изменения
Данное решение практически не повлияло на память.
Обновленная метрика:
```
Total memory for date_large.0065.txt: 3 MB
Total memory for date_large.0125.txt: 5 MB
Total memory for date_large.025.txt: 13 MB
Total memory for date_large.05.txt: 24 MB
Total memory for date_large.1.txt: 47 MB
```


### Находка №2
Асимптотический анализ показал, что нагрузка на CPU растет пропорционально `5^(log2(size))`
Необходимо найти место, где расходуется наибольшее кол-во памяти.
Для этого я воспользуюсь профилировщиком ***ruby-prof***

Данные на момент начальной оптимизации:
```
Calculating -------------------------------------
      Process 0065Mb     34.713  (± 5.8%) i/s -    173.000  in   5.007380s
      Process 0125Mb     19.651  (± 5.1%) i/s -     98.000  in   5.011432s
       Process 025Mb      9.835  (±10.2%) i/s -     50.000  in   5.105793s
        Process 05Mb      4.996  (± 0.0%) i/s -     25.000  in   5.014055s
         Process 1Mb      2.486  (± 0.0%) i/s -     13.000  in   5.261025s
         Process 2Mb      1.193  (± 0.0%) i/s -      7.000  in   5.960086s
```

Судя по отчету ***ruby-prof*** мы вызываем 12835 раз *Array#all?*
Решение: заменить данный метод, на более легкую альтернативу. Убрать лишний вызов в коде.

#### Эффект изменения
Данное решение почти в 2 раза ускорило работу программы.
Обновленная метрика:
```
      Process 0065Mb     50.276  (± 9.9%) i/s -    250.000  in   5.014285s
      Process 0125Mb     30.978  (±12.9%) i/s -    153.000  in   5.009691s
       Process 025Mb     15.831  (± 6.3%) i/s -     79.000  in   5.033943s
        Process 05Mb      7.984  (±12.5%) i/s -     40.000  in   5.049658s
         Process 1Mb      3.950  (± 0.0%) i/s -     20.000  in   5.120427s
         Process 2Mb      1.942  (± 0.0%) i/s -     10.000  in   5.256002s
```

Также *Symbol#to_s* вызывается 9851 раз.
Решение: заменить все ключи хэшей с символов на строки

#### Эффект изменения
Данное решение ускорило работу программы с 15.831 до 16.183 *IPS*
Обновленная метрика:
```
Calculating -------------------------------------
      Process 0065Mb     53.522  (± 9.3%) i/s -    266.000  in   5.012856s
      Process 0125Mb     32.002  (±12.5%) i/s -    159.000  in   5.034213s
       Process 025Mb     16.183  (± 6.2%) i/s -     81.000  in   5.038417s
        Process 05Mb      8.201  (±12.2%) i/s -     42.000  in   5.158457s
         Process 1Mb      4.025  (± 0.0%) i/s -     21.000  in   5.271813s
         Process 2Mb      1.990  (± 0.0%) i/s -     11.000  in   5.643538s
```

Мы используем встроенные библиотеку работы с JSON, но есть более оптимизированная Oj.
Решение: использовать gem Oj для конвертации в JSON.

#### Эффект изменения
Обновленная метрика:
```
Calculating -------------------------------------
      Process 0065Mb     59.896  (±10.0%) i/s -    297.000  in   5.014986s
      Process 0125Mb     35.012  (±20.0%) i/s -    167.000  in   5.028761s
       Process 025Mb     18.829  (±10.6%) i/s -     93.000  in   5.036377s
        Process 05Mb      9.560  (±10.5%) i/s -     48.000  in   5.078154s
         Process 1Mb      4.898  (± 0.0%) i/s -     25.000  in   5.146738s
         Process 2Mb      2.401  (± 0.0%) i/s -     12.000  in   5.071606s
```


## Результаты
В результате проделанной оптимизации наконец удалось обработать файл с данными.
Удалось улучшить метрику системы:
Было
```
Total memory for date_large.0065.txt: 15 MB
Total memory for date_large.0125.txt: 47 MB
Total memory for date_large.025.txt: 155 MB
Total memory for date_large.05.txt: 543 MB
Total memory for date_large.1.txt: 2027 MB

Calculating -------------------------------------
    Process 0.0625Mb      7.438  (± 0.0%) i/s -     38.000  in   5.115027s
     Process 0.125Mb      2.729  (± 0.0%) i/s -     14.000  in   5.133869s
      Process 0.25Mb      0.710  (± 0.0%) i/s -      4.000  in   5.635852s
       Process 0.5Mb      0.135  (± 0.0%) i/s -      1.000  in   7.384139s
         Process 1Mb      0.034  (± 0.0%) i/s -      1.000  in  29.204867s
         Process 2Mb      0.008  (± 0.0%) i/s -      1.000  in 123.505202s

Comparison:
    Process 0.0625Mb:        7.4 i/s
     Process 0.125Mb:        2.7 i/s - 2.73x  slower
      Process 0.25Mb:        0.7 i/s - 10.48x  slower
       Process 0.5Mb:        0.1 i/s - 54.92x  slower
         Process 1Mb:        0.0 i/s - 217.22x  slower
         Process 2Mb:        0.0 i/s - 918.60x  slower
```
Стало
```
Total memory for date_large.0065.txt: 2 MB
Total memory for date_large.0125.txt: 5 MB
Total memory for date_large.025.txt: 11 MB
Total memory for date_large.05.txt: 20 MB
Total memory for date_large.1.txt: 41 MB

Calculating -------------------------------------
      Process 0065Mb     60.944  (± 8.2%) i/s -    303.000  in   5.003275s
      Process 0125Mb     36.796  (±10.9%) i/s -    182.000  in   5.009886s
       Process 025Mb     18.731  (±10.7%) i/s -     93.000  in   5.040241s
        Process 05Mb      9.639  (±10.4%) i/s -     49.000  in   5.125648s
         Process 1Mb      4.866  (± 0.0%) i/s -     25.000  in   5.182842s
         Process 2Mb      2.344  (± 0.0%) i/s -     12.000  in   5.158683s

Comparison:
      Process 0065Mb:       60.9 i/s
      Process 0125Mb:       36.8 i/s - 1.66x  slower
       Process 025Mb:       18.7 i/s - 3.25x  slower
        Process 05Mb:        9.6 i/s - 6.32x  slower
         Process 1Mb:        4.9 i/s - 12.52x  slower
         Process 2Mb:        2.3 i/s - 26.00x  slower
```

## Защита от регресса производительности
Для защиты от потери достигнутого прогресса при дальнейших изменениях программы сделано 2 теста, 
первый проверяет количество IPS, и при падении числа ниже среднего, тест будет невалиден
второй проверяет кол-во выделяемой памяти, при увеличении выше среднего, тест будет невалиден
