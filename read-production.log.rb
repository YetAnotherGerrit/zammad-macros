#!/opt/zammad/bin/ruby

require 'json'

IGNORE_ENDPOINTS = [
    '/api/v1/signshow',
    '/api/v1/signin',
    '/api/v1/users/preferences',
    '/api/v1/taskbar',
    '/api/v1/recent_view',
    '/api/v1/tickets/selector',
    '/api/v1/upload_caches'
]

production_log = ARGV.shift || '/var/log/zammad/production.log'
file_prodlog = File.read(production_log)

puts "# Please execute this script with ./run-zapi.rb <script.zapi> <optional:host> <optional:api-token>"
puts "# To provide host/api-token use either command line parameters or hash out the following two lines:"
puts "#HOST=http://localhost"
puts "#TOKEN=1234567890"

parsed_prodlog = file_prodlog.scan(/(#\d+-\d+)\]  INFO -- : Started (PUT|POST|DELETE|PATCH) "(.*?)"(?:.*?\1\]  INFO -- :   Parameters: ({.*?})$)?.*?\1\]  INFO -- : Completed (\d+)/m)

parsed_prodlog.each do |log|
    request_type = log[1]
    endpoint = log[2]
    payload = log[3]
    return_code = log[4]

    next unless return_code.match?(/200|201/)
    next if IGNORE_ENDPOINTS.any? { |str| endpoint.start_with?(str) }

    ### Thank you https://gist.github.com/gene1wood/bd8159ad90b0799d9436
    payload = "{}" unless payload

    # Transform object string symbols to quoted strings
    payload.gsub!(/([{,]\s*):([^>\s]+)\s*=>/, '\1"\2"=>')

    # Transform object string numbers to quoted strings
    payload.gsub!(/([{,]\s*)([0-9]+\.?[0-9]*)\s*=>/, '\1"\2"=>')

    # Transform object value symbols to quotes strings
    payload.gsub!(/([{,]\s*)(".+?"|[0-9]+\.?[0-9]*)\s*=>\s*:([^,}\s]+\s*)/, '\1\2=>"\3"')

    # Transform array value symbols to quotes strings
    payload.gsub!(/([\[,]\s*):([^,\]\s]+)/, '\1"\2"')

    # Transform object string object value delimiter to colon delimiter
    payload.gsub!(/([{,]\s*)(".*?"|[0-9]+\.?[0-9]*)\s*=>/, '\1\2:')

    payload.gsub!(':nil', ':null')

    puts "#{request_type} #{endpoint} #{payload}"

    JSON.parse(payload)
end