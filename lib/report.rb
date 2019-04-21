# frozen_string_literal: true

require 'oj'
require 'set'
require 'json'

class Report
  class << self
    attr_reader :unique_browsers, :total_sessions, :total_users

    def prepare(file)
      @file = file
      @unique_browsers = Set.new
      @total_sessions = @total_users = 0

      @file.write("{\"usersStats\":{")
    end

    def add_parsed(user)
      browsers = user.prepare

      @total_sessions += user.sessions_count
      @total_users += 1

      formatted = {
        "sessionsCount": user.sessions_count,
        "totalTime": "#{user.total_time} min.",
        "longestSession": "#{user.longest_session} min.",
        "browsers": browsers,
        "usedIE": user.used_ie,
        "alwaysUsedChrome": user.used_only_chrome,
        "dates": user.dates
      }

      @file.write("\"#{user.name}\":#{Oj.dump(formatted, mode: :compat)},")
    end

    def add_analyse
      analyze = {
        "totalUsers": @total_users,
        "uniqueBrowsersCount": @unique_browsers.size,
        "totalSessions": @total_sessions,
        "allBrowsers": @unique_browsers.sort.join(',').upcase!
      }.to_json.tr!('{', '') << "}\n"

      @file.write(analyze)
    end
  end
end
