# Case-study оптимизации
...

## Актуальная проблема
...

## Формирование метрики
Для того чтобы понимать, дают ли мои изменения положительный эффект на
производительность программы, я выбрала такую метрику:
_кол-во итераций в секунду (ips) для входных данных обемом 1Мб._

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

## Результаты
...

## Защита от регресса производительности
...
