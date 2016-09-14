require "rake"
require "yaml"
require "net/ssh"

attributes = YAML.load_file("attributes.yml")

namespace :provisioning do
  targets = attributes.keys

  task all: targets
  task default: :all

  targets.each do |target|
    desc "Run provision to #{target}"
    task target => attributes[target][:roles].map { |r| [target, r].join(":") }
    attributes[target][:roles].each do |role|
      desc "Run provision to #{target}:#{role}"
      task [target, role].join(":") do
        ENV["TARGET_HOST"] = target
        options = Net::SSH::Config.for(target, ["./ssh_config"])
        options[:keys] = options[:keys] ? options[:keys].first : nil
        command = "bundle exec itamae ssh"
        command << " -y attributes/#{target}.yml" if File.exist?("attributes/#{target}.yml")
        command << " -h #{options[:host_name] || target}"
        command << " -u #{options[:user] || attributes[target]['ssh_user'] || ENV['USER']}"
        command << " -i #{options[:keys] || attributes[target]['private_key'] || '~/.ssh/id_rsa'}"
        command << " -p #{options[:port] || attributes[target]['ssh_port'] || 22}"
        command << " cookbooks/#{role}/default.rb"
        puts command
        system command
      end
    end
  end
end
