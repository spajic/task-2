# frozen_string_literal: true

class User
  attr_accessor :name, :sessions_count, :total_time, :longest_session,
                :browsers, :dates, :used_ie, :used_only_chrome

  def initialize
    nullify

    @dates = []
    @browsers = []
  end

  def prepare
    @dates.sort!.reverse!

    browsers = @browsers.sort!.join(', ').upcase!

    @used_only_chrome = true if browsers.end_with?('CHROME')
    @used_ie = true if !@used_only_chrome && browsers.include?('INTERNET')

    browsers
  end

  def reset
    nullify

    @dates.clear
    @browsers.clear
  end

  private
  def nullify
    @longest_session = @total_time = @sessions_count = 0
    @used_only_chrome = @used_ie = false
  end
end
