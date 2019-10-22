# frozen_string_literal: true

require 'fileutils'
require 'ostruct'
require 'aws-sdk-s3'
require 'pry'
require 'erb'
require 'config'

Config.setup do |config|
  config.const_name = 'Settings'
  config.use_env = true
  config.env_prefix = 'PLATFORM'
  config.env_separator = '__'
end
Config.load_and_set_settings('')

class Console
  def self.exec(cmd)
    log(cmd)
    system(cmd)
  end

  def self.log(message); STDOUT.puts(message) end
end

class Storage
  S3FS_PASSWORD_FILE = '/etc/passwd-s3fs'.freeze
  S3_METADATA = { 'uid' => '0', 'gid' => '0', 'mode' => '493' }.freeze
  S3FS_MOUNT_OPTIONS = ['nonempty', 'noexec', 'allow_other', 'multireq_max=5'].freeze

  attr_accessor :config, :bucket, :mounts

  def initialize(config:, bucket:, mounts:)
    @config = config
    @bucket = bucket
    @mounts = mounts
    if config.region.eql?('localstack')
      config.access_key_id = 'localstack'
      config.secret_access_key = 'localstack'
      config.endpoint = 'http://localstack:4572'
      config.force_path_style = true
    end
    write_crdentials if credentials_exist?
  end

  def credentials_exist?
    return (config.access_key_id and config.secret_access_key)
  end

  def write_crdentials
    File.open(S3FS_PASSWORD_FILE, 'w') { |f| f.write("#{config.access_key_id}:#{config.secret_access_key}") }
    File.chmod(0600, S3FS_PASSWORD_FILE)
  end

  def bucket_exists?
    begin
      client.head_bucket(bucket: bucket.name)
      return true
    rescue Aws::S3::Errors::NotFound => error
      begin
        client.create_bucket(bucket: bucket.name)
        return true
      rescue StandardError => error
        Console.log("Error creating bucket #{bucket.name}")
      end
    rescue StandardError => error
      Console.log('Unknown error listing bucket')
    end
    false
  end

  def mount
    mounts.each do |record|
      client.put_object(bucket: bucket.name, key: "#{record.bucket_path}/",
                        metadata: S3_METADATA, content_type: 'application/x-directory')
      FileUtils.mkdir_p(record.local_path)
      Console.exec(s3fs_mount_cmd(record))
    end
  end

  def ls; client.list_objects(bucket: bucket.name) end

  def s3fs_mount_cmd(record)
    "s3fs \"#{bucket.name}:/#{record.bucket_path}\" #{record.local_path} -o #{mount_options(record)}"
  end

  def mount_options(record)
    opts = []
    if config.region.eql?('localstack')
      opts.append("url=#{config.endpoint}")
      opts.append('use_path_request_style')
    else
      opts.append("url=http://s3-#{config.region}.amazonaws.com")
    end
    if record.name.to_sym.eql?(:config)
      mount_options = S3FS_MOUNT_OPTIONS + ['mp_umask=022']
    else
      mount_options = S3FS_MOUNT_OPTIONS + ['umask=022']
    end
    (mount_options + opts).join(',')
  end

  def client
    @client ||= Aws::S3::Client.new(config.to_hash)
  end

  def get_binding; binding() end
end

class Ssh
  attr_accessor :root, :cache_root, :config_root

  def initialize(root: nil, cache_root: nil)
    @root = root
    @config_root = "#{root}/sshx"
    @cache_root = cache_root
  end

  # Create users on first run
  def setup
    make_config
    make_users_file
  end

  def make_config
    FileUtils.mkdir_p("#{config_root}/authorized-keys") unless Dir.exist?("#{config_root}/authorized-keys")
    unless File.exist?("#{config_root}/ssh_host_ed25519_key")
      Console.exec("ssh-keygen -t ed25519 -f #{config_root}/ssh_host_ed25519_key -N ''")
      File.chmod(0600, "#{config_root}/ssh_host_ed25519_key")
      File.chmod(0600, "#{config_root}/ssh_host_ed25519_key.pub")
    end
    unless File.exist?("#{config_root}/ssh_host_rsa_key")
      Console.exec("ssh-keygen -t rsa -b 4096 -f #{config_root}/ssh_host_rsa_key -N ''")
      File.chmod(0600, "#{config_root}/ssh_host_rsa_key")
      File.chmod(0600, "#{config_root}/ssh_host_rsa_key.pub")
    end
  end

  def make_users_file
    FileUtils.mkdir_p(cache_root) unless Dir.exist?(cache_root)
    Console.exec("update-sftp-user --users-conf #{root}/users.conf --users-cache #{cache_root}/users.conf")
  end
end


class Entrypoint
  attr_accessor :mounts, :storage

  def initialize
    @storage = Storage.new(config: client, bucket: bucket, mounts: mounts)
  end

  def run!
    if not storage.credentials_exist?
      Console.log('Warning: AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY not specified')
    elsif not storage.bucket_exists?
      Console.log("Warning: Cannot mount bucket #{bucket.name}")
    else
      storage.mount
      sleep 2
      Ssh.new(root: Settings.ssh.root, cache_root: Settings.ssh.cache_root).setup
    end
  end

  def run_supervisord!
    # umount bucket paths and have supervisord manage them
    mounts.each { |record| Console.exec("umount #{record.local_path}") }
    FileUtils.mkdir_p('/var/log/supervisor')
    write_supervisord
    # Replace this script process with supervisord
    exec('supervisord', '-c', conf_file)
  end

  def write_supervisord
    template_file = 'supervisord.conf.erb'
    renderer = ERB.new(File.read(template_file))
    output = renderer.result(storage.get_binding)
    File.write(conf_file, output)
  end

  def conf_file; '/etc/supervisor/supervisord.conf' end

  def client
    Settings.aws ||= Config::Options.new(ENV.select { |k,v| k.start_with?('AWS') }.transform_keys { |k| k.downcase.gsub('aws_', '') })
  end

  def bucket; Settings.bucket end

  def mounts
    @mounts ||= (Settings.mounts || {}).each_with_object([]) do |(key, values), ary|
      base_key = bucket.feature_set ? "#{bucket.feature_set}/" : ''
      values.bucket_path = "#{base_key}#{values.bucket_path}"
      ary.append(OpenStruct.new(values.to_hash.merge(name: key.to_s)))
    end
  end
end
