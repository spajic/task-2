# Deoptimized version of homework task
# frozen_string_literal: true

require 'json'
require 'date'
require 'oj'

class TaskClass
  def parse_user(fields)
    {
      'id' => fields[1],
      'first_name' => fields[2],
      'last_name' => fields[3],
      'age' => fields[4],
      'sessions' => []
    }
  end

  def parse_session(fields)
    {
      'session_id' => fields[2],
      'browser' => fields[3],
      'time' => fields[4],
      'date' => fields[5].strip,
    }
  end

  def prepare_data(filename, users, sessions)
    file_lines = File.open(filename, "r")
    file_lines.each_line do |line|
      cols = line.split(',')
      if cols[0] == 'session'
        session = parse_session(cols)
        sessions << session
        users[cols[1].to_i]['sessions'] << session
      else
        users << parse_user(cols)
      end
    end
  end

  def collect_stats_from_users(report, users_objects)
    report['usersStats'] = {}
    users_objects.each do |user|
      user_key = "#{user['first_name']}" + ' ' + "#{user['last_name']}"
      report['usersStats'][user_key] ||= {}
      mapped_time = map_time(user['sessions'])
      report['usersStats'][user_key]['sessionsCount'] = collect_session_count(user['sessions'])
      report['usersStats'][user_key]['totalTime'] = collect_session_time(mapped_time)
      report['usersStats'][user_key]['longestSession'] = collect_session_longest(mapped_time)
      mapped_browsers = map_browsers(user['sessions'])
      browsers_as_string = collect_browsers(mapped_browsers)
      report['usersStats'][user_key]['browsers'] = browsers_as_string.upcase
      report['usersStats'][user_key]['usedIE'] = collect_ie_usage(browsers_as_string)
      report['usersStats'][user_key]['alwaysUsedChrome'] = collect_if_only_chrome_used(browsers_as_string)
      report['usersStats'][user_key]['dates'] = collect_session_dates(user['sessions'])
    end
  end

  # Собираем количество сессий по пользователям
  def collect_session_count(sessions)
    sessions.count
  end

  def map_time(sessions)
    sessions.map {|s| s['time'].to_i }
  end

  def map_browsers(sessions)
    sessions.map {|s| s['browser']}
  end

  # Собираем количество времени по пользователям
  def collect_session_time(mapped_time)
    mapped_time.sum.to_s + ' min.'
  end

  # Выбираем самую длинную сессию пользователя
  def collect_session_longest(mapped_time)
    mapped_time.max.to_s + ' min.'
  end

  # Браузеры пользователя через запятую
  def collect_browsers(mapped_browsers)
    mapped_browsers.sort.join(', ')
  end

  # Хоть раз использовал IE?
  def collect_ie_usage(browsers_as_string)
    !!(browsers_as_string =~ /INTERNET EXPLORER/i)
  end

  # Всегда использовал только Chrome?
  def collect_if_only_chrome_used(browsers_as_string)
    !!(browsers_as_string =~ /^CHROME$/i)
  end

  # Даты сессий через запятую в обратном порядке в формате iso8601
  def collect_session_dates(sessions)
    sessions.map{|s| s['date']}.sort.reverse
  end

  def work(filename:)
    users = []
    sessions = []
    prepare_data(filename, users, sessions)

    # Отчёт в json
    #   - Сколько всего юзеров +
    #   - Сколько всего уникальных браузеров +
    #   - Сколько всего сессий +
    #   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
    #
    #   - По каждому пользователю
    #     - сколько всего сессий +
    #     - сколько всего времени +
    #     - самая длинная сессия +
    #     - браузеры через запятую +
    #     - Хоть раз использовал IE? +
    #     - Всегда использовал только Хром? +
    #     - даты сессий в порядке убывания через запятую +

    report = {}

    report['totalUsers'] = users.count

    # Подсчёт количества уникальных браузеров
    uniqueBrowsers = sessions.each_with_object({}) do |session, result|
      browser = session['browser']
      result[browser] = true unless result[browser]
    end.keys

    report['uniqueBrowsersCount'] = uniqueBrowsers.count

    report['totalSessions'] = sessions.count
    report['allBrowsers'] = uniqueBrowsers.sort.join(',').upcase

    collect_stats_from_users(report, users)

    File.write('result.json', "#{Oj.dump(report)}\n")
  end
end
