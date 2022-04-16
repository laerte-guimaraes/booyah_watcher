require 'capybara/dsl'
require 'selenium-webdriver'

class BooyahWatcher
  include Capybara::DSL

  FACEBOOK_EMAIL = ENV.fetch('FACEBOOK_EMAIL').freeze
  FACEBOOK_PASSWORD = ENV.fetch('FACEBOOK_PASSWORD').freeze

  def initialize(approvals_code)
    Capybara.register_driver :selenium do |app|
      Capybara::Selenium::Driver.new(app,:browser => :chrome, timeout: 30)
    end
  
    Capybara.configure do |config|
      config.default_driver = :selenium 
      config.app_host = "https://www.google.com"
      config.default_max_wait_time = 30
    end

    @approvals_code = approvals_code
  end

  def watch(channel, source = '3')
    visit("https://booyah.live/#{channel}?source=#{source}")

    click_button 'Ir Para a Página De Login'
    find('.checkbox-icon').click 
    facebook_login

    if has_content?('Assistir')
      log_message('Stream Iniciada com sucesso!')
      click_button 'Assistir'
    else
      return log_message('Streamer Offline!')
    end

    while !has_content?('Vamos continuar a conversa')
      sleep(1800) # Verifica status da Stream a cada 30 min
    end

    log_message('Stream Finalizada!')
  end

  private

  attr_reader :approvals_code

  def facebook_login
    facebook_window = window_opened_by do
      click_button 'Entre via Facebook'
    end

    within_window facebook_window do
      fill_in 'email', with: FACEBOOK_EMAIL
      fill_in 'pass', with: FACEBOOK_PASSWORD
      click_button 'Entrar'

      if has_content?('Autenticação de dois fatores necessária')
        fill_in 'approvals_code', with: approvals_code
        2.times { click_button 'Continuar' }
      end
    end
  end

  def log_message(message)
    puts "#{Time.now} - #{message}"
  end
end

BooyahWatcher.new(ARGV[0]).watch(ENV.fetch('BOOYAH_CHANNEL'))
