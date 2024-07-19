#!/opt/zammad/bin/ruby

require 'net/http'

APP_RESTART_ENDPOINT = '/api/v1/object_manager_attributes_execute_migrations'
AVAILABLE_ENDPOINT = '/api/v1/available'
WAIT_FOR_RESTART = 2

def error_arguments
    puts "ERROR: wrong arguments"
    puts ""
    puts "Please use #{__FILE__} <script> <optional:host> <optional:api-token>"
    puts ""
    puts "- example: #{__FILE__} my-script.zapi http://localhost token123"
    exit 1
end

def error_missinghostandtoken
    puts "ERROR: missing host/token"
    puts ""
    puts "Please use #{__FILE__} <script> <optional:host> <optional:api-token>"
    puts "or provide host/token in the script using HOST=localhost TOKEN=token123!"
    exit 1
end


def wait_for_available(http,online)
    while true
        req = Net::HTTP::Get.new(AVAILABLE_ENDPOINT)
        res = http.request(req)
        print "."
        break if online == true && res.code == "200"
        break if online == false && res.code != "200"
        sleep WAIT_FOR_RESTART
    end
end

if ARGV.length != 1 && ARGV.length != 3 
    error_arguments
end

script = ARGV.shift
host = ARGV.shift
api_token = ARGV.shift

File.readlines(script, chomp: true).each do |line|
    next if line.start_with?("#")

    if line.match?(/^(HOST|TOKEN)/)
        result = line.match(/^(HOST|TOKEN) (.*)/)

        case result[1].downcase
        when "host"
            host = result[2]
        when "token"
            api_token = result[2]
        end

        uri = URI(host)
        http = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => (uri.scheme == 'https'))
    elsif (host.nil? || host.empty?) && (api_token.nil? || api_token.empty?)
        error_missinghostandtoken
    end

    unless http
        uri = URI(host)
        http = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => (uri.scheme == 'https'))
    end

    parsed_line = line.match(/(PUT|POST|DELETE|PATCH|GET) ([^ ]+) (.*)/)
    parsed_request_type = parsed_line[1].downcase
    parsed_endpoint = parsed_line[2]
    parsed_payload = parsed_line[3]

    puts line

    req = ''

    case parsed_request_type
    when "post"
        req = Net::HTTP::Post.new(parsed_endpoint)
    when "put"
        req = Net::HTTP::Put.new(parsed_endpoint)
    when "get"
        req = Net::HTTP::Get.new(parsed_endpoint)
    when "delete"
        req = Net::HTTP::Delete.new(parsed_endpoint)
    when "patch"
        req = Net::HTTP::Patch.new(parsed_endpoint)
    end

    req['Authorization'] = "Token token=#{api_token}"
    req["Content-Type"] = "application/json"
    req.body = parsed_payload

    res = http.request(req)

    unless res.code.match?(/200|201/)
        puts "==> ERROR #{res.code}: #{res.body}"
        exit 1
    else
        puts "==> Successful: #{res.code}"
    end

    if parsed_endpoint == APP_RESTART_ENDPOINT && parsed_payload == "{}"
        puts "Zammad needs to be restarted, if APP_RESTART_CMD is not configured, do that manually please."
        print "Waiting for shutdown"
        wait_for_available(http,false)
        puts " ok"

        print "Waiting for restart"
        wait_for_available(http,true)
        puts " ok"
    end 
end
