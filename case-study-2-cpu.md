# Case-study оптимизации
...

## Актуальная проблема
...

## Формирование метрики
Для того чтобы понимать, дают ли мои изменения положительный эффект на
производительность программы, я выбрала такую метрику:
_кол-во итераций в секунду (ips) для входных данных объемом 1Мб._

## Анализ зависимости метрики от входных данных
```
Calculating -------------------------------------
       Process 0.5Mb      7.363  (±13.6%) i/s -     37.000  in   5.077708s
       Process 1.0Mb      2.954  (± 0.0%) i/s -     15.000  in   5.235584s
       Process 1.5Mb      2.390  (± 0.0%) i/s -     13.000  in   5.450830s
       Process 2.0Mb      1.656  (± 0.0%) i/s -      9.000  in   5.483160s
       Process 2.5Mb      1.372  (± 0.0%) i/s -      7.000  in   5.106598s
       Process 3.0Mb      1.080  (± 0.0%) i/s -      6.000  in   5.645895s
       Process 3.5Mb      0.985  (± 0.0%) i/s -      5.000  in   5.106571s
       Process 4.0Mb      0.839  (± 0.0%) i/s -      5.000  in   6.024114s
       Process 4.5Mb      0.769  (± 0.0%) i/s -      4.000  in   5.224033s
       Process 5.0Mb      0.683  (± 0.0%) i/s -      4.000  in   5.892405s

Comparison:
       Process 0.5Mb:        7.4 i/s
       Process 1.0Mb:        3.0 i/s - 2.49x  slower
       Process 1.5Mb:        2.4 i/s - 3.08x  slower
       Process 2.0Mb:        1.7 i/s - 4.45x  slower
       Process 2.5Mb:        1.4 i/s - 5.37x  slower
       Process 3.0Mb:        1.1 i/s - 6.82x  slower
       Process 3.5Mb:        1.0 i/s - 7.48x  slower
       Process 4.0Mb:        0.8 i/s - 8.77x  slower
       Process 4.5Mb:        0.8 i/s - 9.58x  slower
       Process 5.0Mb:        0.7 i/s - 10.78x  slower
```

## Гарантия корректности работы оптимизированной программы
Программа поставлялась с тестом. Выполнение этого теста позволяет не допустить изменения логики программы при оптимизации.

## Feedback-Loop
...

## Обнаруженные проблемы и проведенные оптимизации

### Оптимизация №1
Сгенерировала отчет ruby-prof с помощью `GraphHtmlPrinter` в режиме `RubyProf::WALL_TIME`.
В отчете видно, что более всего времени тратится в цикле `IO#each`. 
В списке вызовов, которые происходят в этом цикле, лидируют `Object#parse_session` и `Array#include?` 
с примерно равными временными затратами.

Вот этот кусок кода:
```
File.open(source_file, 'r').each do |line|
    users << parse_user(line) if line.start_with?(USER_ROW_MARK)
    next unless line.start_with?(SESSION_ROW_MARK)

    session = parse_session(line)
    sessions_by_users[session[:user_id]] ||= []
    sessions_by_users[session[:user_id]] << session
    browser = session[:browser].upcase!
    unique_browsers << browser unless unique_browsers.include?(browser)
    total_sessions += 1
end
```

Внутри метода `Object#parse_session` почти все затраты приходятся на разбиение строки в массив `String#split`. 
Я предприняла несколько попыток оптимизировать это место:
 - попробовала последовательно перебирать символы в строке и писать в хэш подстроки до первой встречной запятой;
 - попробовала передавать в методы `parse_session` и `parse_user` уже обрезанную строку без лишнего;
 - ради интереса протестировала библиотеку `CSV` (построчная обработка в цикле `CSV.foreach`) – работает почти 
 вдвое медленнее текущего решения.
 
Увы, тут экономия на спичках мне ничего не дала, поэтому я сосредоточилась на `Array#include?`.
Этот метод мы используем, чтобы добиться уникальности элементов в массиве браузеров. 
Вместо массива мы можем попробовать использовать `Set`, поскольку он сам по себе гарантирует уникальность. 
Более того, можем в будущем избавиться от вызова `Array#sort`, если возьмем `SortedSet`.

```
unique_browsers = SortedSet.new
```
Отчет ruby-prof показал, что оптимизация дала небольшой эффект – доля времени, которую занимает работа цикла `IO#each`, 
снизилась с 44 до 40%.
А замеры подтвердили, что метрика выросла с **3.0 до 4.5 i/s**

### Оптимизация №2
На отчёте `CallTree` в режиме `RubyProf::CPU_TIME` можно увидеть, что в топ-3 находится геренация JSON из хэша.
В исходном скрипте используется стандартная библиотека ruby, и на единственный вызов ее метода `to_json` приходится 
более 14% процессорного времени.

![call_tree](https://ucarecdn.com/3300eefc-b61c-4b57-9c1b-f48dc17e6bdd/ScreenShot20190314at231622.png)

Я решила поискать альтернативы и нашла пару библиотек:
 - [YAJL](https://github.com/brianmario/yajl-ruby)
 - [Oj](https://github.com/ohler55/oj)

Я не стала сама проводить сравнение их производительности, но в многочисленных статьях, которых которые мне 
нагуглились, самым быстрым был признан Oj.

Меняю
```
File.write(target_file, report.to_json)
```
на
```
  Oj.to_file(target_file, report, mode: :wab)
```

Режим `wab` оказался чуть более производительным, чем `strict`, даже с учетом того, что пришлось сделать 
доп. преобразование имени пользователя, который используется в качестве ключа в хэше, из строки в символ 
(требование этого режима).

На новом дереве этот узел не отображается, в списке он ушел далеко вниз.
![new_call_tree](https://ucarecdn.com/eadd7fb6-25c5-483b-88e7-f7f976e1620f/ScreenShot20190314at234514.png)

Метрика после этого изменения выросла до **5 i/s**

### Оптимизация №3

Построила отчёт `CallStack` с помощью ruby-prof.
На нем видно, что после большого цикла `IO#each` (который пока не понятно как оптимизировать), 
идет вызов метода `Array#map` (более 17% времени).
При более детальном рассмотрении стало понятно, что все вызовы этого метода сосредоточены в одном месте:
```
until users.empty?
    user = users.shift
    user_sessions = sessions_by_users.delete(user[:id]) || []
    sessions_duration = user_sessions.map { |s| s[:time].to_i }
    browsers = user_sessions.map { |s| s[:browser] }
    
    report[:usersStats][user[:full_name]] = {
        sessionsCount: user_sessions.count,
        totalTime: "#{sessions_duration.sum} min.",
        longestSession: "#{sessions_duration.max} min.",
        browsers: browsers.sort!.join(DELIMITER),
        usedIE: browsers.any? { |b| b =~ IE_PATTERN },
        alwaysUsedChrome: browsers.all? { |b| b =~ CHROME_PATTERN },
        dates: user_sessions.map { |s| Date.strptime(s[:date], '%Y-%m-%d') }.sort!.reverse!.map!(&:iso8601)
    }
end
```

Тут `#map` фигурирует трижды, и все три раза для одного и того же массива `user_sessions`. 
Я подумала, что можно пройтись по массиву один раз и достать все нужные данные сразу. 
А вместо промежуточных массивов `sessions_duration` и `browsers` аккумулировать нужные срезы в одном объекте – хэше.

```
until users.empty?
    user = users.shift
    user_sessions = sessions_by_users.delete(user[:id]) || []
    sessions_stats = {
      total_duration: 0,
      max_duration: 0,
      browsers: [],
      dates: [],
      length: user_sessions.length
    }

    until user_sessions.empty?
      session = user_sessions.shift
      time = session[:time].to_i

      sessions_stats[:total_duration] += time
      sessions_stats[:max_duration] = time if sessions_stats[:max_duration] < time
      sessions_stats[:browsers] << session[:browser]
      sessions_stats[:dates] << Date.strptime(session[:date], '%Y-%m-%d')
    end

    report[:usersStats][user[:name]] = {
      sessionsCount: sessions_stats[:length],
      totalTime: "#{sessions_stats[:total_duration]} min.",
      longestSession: "#{sessions_stats[:max_duration]} min.",
      browsers: sessions_stats[:browsers].sort!.join(DELIMITER),
      usedIE: sessions_stats[:browsers].any? { |b| b =~ IE_PATTERN },
      alwaysUsedChrome: sessions_stats[:browsers].all? { |b| b =~ CHROME_PATTERN },
      dates: sessions_stats[:dates].sort!.reverse!.map!(&:iso8601)
    }
  end
```

Как изменился отчёт, можно увидеть ниже:

Before | After
------ | -----
![stack_before](https://ucarecdn.com/6f271373-b78a-4f61-8b6f-b87370913253/ScreenShot20190315at003138.png) | ![stack_after](https://ucarecdn.com/3ec9ad92-1e2c-4001-b15c-de7ff3bd93da/ScreenShot20190315at003157.png)

К сожалению, метрика выросла незначительно – **5.2 i/s**. Но откатывать изменения я не стала.

### Оптимизация №4

Дальнейшая медитация на отчёты натолкнула меня на интересную мысль: мы делаем преобразование из строкового 
представления даты в формате `iso8601` в объекты класса `Date` для того чтобы отсортировать их и затем обратно 
конвертировать в строки. Хотя по факту результат сортировки исходных строк в данном формате будет совпадать с 
результатом сортировки объектов `Date`.
Решение сортировать даты как строки неоднозначное, и в иных условиях я предпочла бы к нему не прибегать, но, допустим, 
в данном случае вопрос производительности стоит острее ☺️

Затраты на это преобразование довольно заметные, см. строку 4 и 8 (режим `RubyProf::WALL_TIME`):

```
#    %self      total      self      wait     child     calls  name
1     15.00      0.187     0.061     0.000     0.126        1   IO#each
2     12.97      0.405     0.053     0.000     0.353        1   Object#create_report
3     10.67      0.043     0.043     0.000     0.000    26497   String#split
4      9.70      0.044     0.039     0.000     0.004    22424   <Class::Date>#strptime
5      6.15      0.060     0.025     0.000     0.035    22428   Object#parse_session
6      4.51      0.034     0.018     0.000     0.016    22428   SortedSet#add
7      4.31      0.017     0.017     0.000     0.000        1   <Module::Oj>#to_file
8      3.91      0.016     0.016     0.000     0.000    22424   Date#iso8601
```

Убираем преобразование туда-обратно.
Метрика выросла до **7 i/s**.

### Оптимизация №5
Перезапустив flat-отчёт после предыдущего шага, увидела, что на 7 строке теперь у нас матчинг строки с регулярным 
выражением.

```
#    %self      total      self      wait     child     calls  name
1     18.58      0.178     0.059     0.000     0.119        1   IO#each
2     14.82      0.319     0.047     0.000     0.272        1   Object#create_report
3     11.99      0.038     0.038     0.000     0.000    26497   String#split
4      8.02      0.056     0.026     0.000     0.031    22428   Object#parse_session
5      5.44      0.032     0.017     0.000     0.015    22428   SortedSet#add
6      5.31      0.017     0.017     0.000     0.000        1   <Module::Oj>#to_file
7      3.76      0.012     0.012     0.000     0.000    24866   String#=~
```

Поскольку regexp'ы у нас довольно тривиальные, к тому же искомая подстрока всегда гарантированно находится 
в начале строки, можно бузболезненно заметить `String#=~` на `String#start_with?`, что я и сделала.

Результат – метрика выросла до **8 i/s**

## Результаты
На данных размером 1Mb метрика увеличилась **с 3 до 8 i/s**

Как изменилась зависимость IPS от размера данных:
![asymptotics](https://ucarecdn.com/358541a6-415a-407a-9bb8-b1221525f68e/ScreenShot20190315at194955.png)


Время работы скрипта:
```
 * 1Mb:             0.3 –> 0.15 секунд
 * Полный объем:    50 –> 32 секунды
```

## Защита от регресса производительности
Для защиты от потери достигнутого прогресса при дальнейших изменениях программы написан простейший тест, 
который проверяет, что время работы скрипта на данных размером 1Mb не превышает 0.3 секунды.
