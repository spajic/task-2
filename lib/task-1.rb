# frozen_string_literal: true

require 'yajl'
#require 'ruby-progressbar'

def parse_user(fields)
  {
    id: fields[1],
    full_name: fields[2] << " " << fields[3]
  }
end

def parse_session(fields)
  {
    user_id: fields[1],
    browser: fields[3].upcase!,
    time: fields[4].to_i,
    date: fields[5].chomp!,
  }
end

def aggregate_user_stats(data)
  return {} unless data

  user = data[1][:user]
  sessions = data[1][:sessions]
  time = sessions.map {|s| s[:time] }
  browsers = sessions.map { |s| s[:browser] }
  {
    user[:full_name]=> {
      sessionsCount: sessions.count,
      totalTime: time.sum.to_s << ' min.',
      longestSession: time.max.to_s << ' min.',
      browsers: browsers.sort!.join(', '),
      usedIE: browsers.any? { |b| b.include?('INTERNET EXPLORER') },
      alwaysUsedChrome: browsers.all? { |b| b.include?('CHROME')},
      dates: sessions.map{|s| s[:date]}.sort!.reverse!
    }
  }
end

def work(input: "data.txt", output: "result.json")
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

  data = {}
  _tmp_hash = {}
  report = {
    totalUsers: 0,
    uniqueBrowsersCount: 0,
    totalSessions: 0,
    allBrowsers: [],
    usersStats: {}
  }

  #bar_output = ENV["NOPROGRESS"] ? File.open(File::NULL, "w") : $stdout
  #bar = ProgressBar.create(total: nil, output: bar_output)
  File.open(input) do |f|
    f.each_line do |line|
      cols = line.split(',')
      key = cols[1]
      if cols[0] == "user"
        if data[key].nil?
          report[:usersStats].merge!(aggregate_user_stats(data.shift))
        end
        data[key] ||= {}
        data[key][:user] = parse_user(cols)
        report[:totalUsers] += 1
      else
        data[key] ||= {}
        data[key][:sessions] ||= []
        session = parse_session(cols)
        browser = session[:browser]
        if _tmp_hash[browser].nil?
          _tmp_hash[browser] = 1
          report[:allBrowsers].push(browser)
          report[:uniqueBrowsersCount] += 1
        end
        report[:totalSessions] += 1
        data[key][:sessions].push(session)
      end
  #    bar.increment
    end
    report[:usersStats].merge!(aggregate_user_stats(data.shift))
    report[:allBrowsers] = report[:allBrowsers].sort!.join(',')
  #  bar.finish
  end
  File.open(output, 'w') do |f|
    Yajl::Encoder.encode(report, f)
    f << "\n"
  end
end
