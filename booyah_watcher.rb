require 'capybara/cuprite'
require 'capybara/dsl'

class BooyahWatcher
  include Capybara::DSL

  FACEBOOK_EMAIL = ENV.fetch('FACEBOOK_EMAIL').freeze
  FACEBOOK_PASSWORD = ENV.fetch('FACEBOOK_PASSWORD').freeze

  def initialize(approvals_code)
    Capybara.register_driver :cuprite do |app|
      Capybara::Cuprite::Driver.new(
        app,
        headless: true,
        inspector: true,
        process_timeout: 5,
        timeout: 120,
        browser_options: {
          'no-sandbox': nil,
          'ignore-certificate-errors' => true
        }
      )
    end
  
    Capybara.configure do |config|
      config.default_driver = :cuprite 
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

    while !has_content?('Vamos continuar a conversa') && !has_content?('Ir para o canal')
      log_message('Stream em andamento...')
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
