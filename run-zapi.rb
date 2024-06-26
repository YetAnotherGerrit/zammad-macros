#!/opt/zammad/bin/ruby

require 'net/http'

APP_RESTART_ENDPOINT = '/api/v1/object_manager_attributes_execute_migrations'
AVAILABLE_ENDPOINT = '/api/v1/available'
WAIT_FOR_RESTART = 2

def error_arguments
    puts "ERROR: wrong arguments"
    puts ""
    puts "Please use #{__FILE__} <script> <host> <api-token>"
    puts ""
    puts "- example: #{__FILE__} my-script.zapi http://localhost token123"
    exit 1
end

if ARGV.length != 3 
    error_arguments
end

script = ARGV.shift
host = ARGV.shift
api_token = ARGV.shift

uri = URI(host)

Net::HTTP.start(uri.hostname, uri.port) do |http|
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

        if parsed_endpoint == APP_RESTART_ENDPOINT
            puts "Zammad needs to be restarted, if APP_RESTART_CMD is not configured, do that manually please."
            print "Waiting for shutdown"
            while true
                req = Net::HTTP::Get.new(AVAILABLE_ENDPOINT)
                res = http.request(req)
                print "."
                break if res.code != "200"
                sleep WAIT_FOR_RESTART
            end
            puts " ok"

            print "Waiting for restart"
            while true
                req = Net::HTTP::Get.new(AVAILABLE_ENDPOINT)
                res = http.request(req)
                print "."
                break if res.code == "200"
                sleep WAIT_FOR_RESTART
            end
            puts " ok"
        end 
    end
end