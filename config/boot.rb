ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Load runtime secrets from storage (for `docker exec` commands that bypass the entrypoint)
docker_env = File.expand_path("../storage/.docker-env", __dir__)
if File.exist?(docker_env)
  File
    .readlines(docker_env)
    .each { |line| ENV[$1] ||= $2 if line =~ /\Aexport\s+(\w+)='(.*)'\z/ }
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
