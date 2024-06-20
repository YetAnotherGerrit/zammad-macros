#!/opt/zammad/bin/ruby

require 'json'

def error_arguments
    puts "ERROR: wrong arguments"
    puts ""
    puts "Please use #{__FILE__} <bash or zapi> <bash:host> <bash:api-token> <optional:path/to/poduction.log>"
    puts ""
    puts "- example: #{__FILE__} bash http://localhost token123 > my-script.sh"
    puts "- example: #{__FILE__} zapi > my-script.zapi"
    puts ""
    puts "Always check the resulting script before executing! You may want to make adjustments."
    exit 1
end

case ARGV.first
when "bash"
    if ARGV.length < 3 || ARGV.length > 4
        error_arguments
    else
        script_type = ARGV.shift
        host = ARGV.shift
        api_token = ARGV.shift
        production_log = ARGV.shift || '/var/log/zammad/production.log'
    end
when "zapi"
    if ARGV.length < 1 || ARGV.length > 2
        error_arguments
    else
        script_type = ARGV.shift
        host = ''
        api_token = ''
        production_log = ARGV.shift || '/var/log/zammad/production.log'
    end
else
    error_arguments
end        

file_prodlog = File.read(production_log)

### HEADER

case script_type
when "bash"
    puts "#!/bin/bash"
    puts "host=#{host}"
    puts "token=#{token}"
when "zapi"
    puts "# Please execute this script with ./run-zapi.rb <script.zapi> <host> <api-token>"
end

### PARSER

parsed_prodlog = file_prodlog.scan(/(#\d+-\d+)\]  INFO -- : Started (PUT|POST|DELETE|PATCH) "(.*?)".*?\1\]  INFO -- :   Parameters: ({.*?}$)/m)

parsed_prodlog.each do |log|
    request_type = log[1]
    endpoint = log[2]
    payload = log[3]

    ### Thank you https://gist.github.com/gene1wood/bd8159ad90b0799d9436

    # Transform object string symbols to quoted strings
    payload.gsub!(/([{,]\s*):([^>\s]+)\s*=>/, '\1"\2"=>')

    # Transform object string numbers to quoted strings
    payload.gsub!(/([{,]\s*)([0-9]+\.?[0-9]*)\s*=>/, '\1"\2"=>')

    # Transform object value symbols to quotes strings
    payload.gsub!(/([{,]\s*)(".+?"|[0-9]+\.?[0-9]*)\s*=>\s*:([^,}\s]+\s*)/, '\1\2=>"\3"')

    # Transform array value symbols to quotes strings
    payload.gsub!(/([\[,]\s*):([^,\]\s]+)/, '\1"\2"')

    # Transform object string object value delimiter to colon delimiter
    payload.gsub!(/([{,]\s*)(".+?"|[0-9]+\.?[0-9]*)\s*=>/, '\1\2:')

    JSON.parse(payload)

    case script_type
    when "bash"
        # Escape ' as this is used to quote the payload in the curl argument'
        payload.gsub!("'", "\\\\'")
        
        puts %Q[curl -X #{request_type} -H "Authorization: Token token=${token}" -H 'content-type: application/json' ${host}#{endpoint} -d '#{payload}']Q
    when "zapi"
        puts "#{request_type} #{host}#{endpoint} #{payload}"
    end
end