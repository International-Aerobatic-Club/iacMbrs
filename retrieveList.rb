require 'yaml'
require 'uri'
require 'capybara/dsl'

class Golden
  include Capybara::DSL

  def initialize(config)
    @config = config
  end

  def retriever()
    url = URI.parse(@config['url'])
    root = url.scheme + '://' + url.host
    Capybara.current_driver = :selenium
    Capybara.app_host = root

    puts "Visiting #{url.path} at #{root}"
    visit(url.path)

    puts "Signing-in..."
    fill_in('username', with: @config['uname'])
    fill_in('password', with: @config['pwd'])
    select(@config['dom'], from: 'domain')
    click_button('loginButton')

    link = find(:xpath, '//a[text="Partner upload/download area"]')
    puts "Navigating to download area"
    save_and_open_page
    link.click
  end
end

config = YAML.load(File.read('config.yml'))
golden = Golden.new(config)
golden.retriever
