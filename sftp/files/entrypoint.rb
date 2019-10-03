#!/bin/env ruby

S3FS_PASSWORD_FILE = '/etc/passwd-s3fs'

class Entrypoint
  attr_accessor :bucket_name, :bucket_endpoint_url, :mount_options, :s3_params, :bucket_dir_home, :bucket_dir_config

  def initialize
    @bucket_name = ENV['BUCKET_NAME']
    @bucket_endpoint_url = ENV['BUCKET_ENDPOINT_URL']
    @mount_options = ENV['MOUNT_OPTIONS']
    if bucket_endpoint_url
      @s3_params = "--endpoint-url=#{bucket_endpoint_url}"
      @mount_options = "#{@mount_options} -o url=#{bucket_endpoint_url},use_path_request_style"
    end
    @bucket_dir_home = ENV['BUCKET_DIR_HOME']
    @bucket_dir_config = ENV['BUCKET_DIR_CONFIG']
  end

  def run!
    write_s3fs_password_file
    if bucket_name and bucket_exists?
      make_dirs
      mount_dirs
      make_ssh_config
      make_ssh_users_file
    else
      log('BUCKET_NAME is not set, skip mounting S3 bucket')
    end
  end

  def write_s3fs_password_file
    unless ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
      log('Warning: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY not specified, not creating /etc/passwd-s3fs')
      return
    end
    File.open(S3FS_PASSWORD_FILE, 'w') { |f| f.write("#{ENV['AWS_ACCESS_KEY_ID']}:#{ENV['AWS_SECRET_ACCESS_KEY']}") }
    File.chmod(0600, S3FS_PASSWORD_FILE)
  end

  def bucket_exists?
    if system("aws s3api #{s3_params} head-bucket --bucket #{bucket_name}")
      log("Bucket #{bucket_name} exists")
    elsif system("aws s3 #{s3_params} mb s3://#{bucket_name}")
      log("Bucket #{bucket_name} created")
    else
      log("Bucket #{bucket_name} error listing/creating")
      return false
    end
    true
  end

  def make_dirs
    [bucket_dir_home, bucket_dir_config].each do |dir|
      cmd = "aws s3api #{s3_params} put-object --bucket #{bucket_name} --key \"#{dir}/\"" \
        "--metadata uid=0,gid=0,mode=493 --content-type application/x-directory"
      exec(cmd)
    end
  end

  def mount_dirs
    FileUitls.mkdir_p('/opt/sftp')
    [{ dir: bucket_dir_home, path: '/home' }, { dir: bucket_dir_config, path: '/opt/sftp' }].each do |record, (dir, path)|
      cmd = "s3fs \"#{bucket_name}:/#{dir}/\" #{path} -o nonempty,noexec,allow_other,umask=022,multireq_max=5 #{mount_options}"
      exec(cmd)
    end
    sleep 3
  end

  # shellcheck disable=2154
  # trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

  def make_ssh_config
    ssh_root = '/opt/sftp/sshx'
    FileUtils.mkdir_p("#{ssh_root}/authorized-keys")
    system("ssh-keygen -t ed25519 -f /opt/sftp/sshx/ssh_host_ed25519_key -N ''") unless File.exist?("#{ssh_root}/ssh_host_ed25519_key")
    system("ssh-keygen -t rsa -b 4096 -f /opt/sftp/sshx/ssh_host_rsa_key -N ''") unless File.exist?("#{ssh_root}/ssh_host_rsa_key")
  end

  # Create users on first run
  def make_ssh_users_file
    FileUtils.mkdir_p(user_cache_path) unless Dir.exist?(user_cache_path)
    system("update-sftp-user --users-conf #{user_conf_path} --users-cache #{user_cache_path}")
  end

  def user_conf_path; '/opt/sftp/users.conf' end
  def user_cache_path; '/var/run/sftp/users.conf' end

  def exec(cmd)
    log(cmd)
    system(cmd)
  end

  def log(message); STDOUT.puts(message) end
end

# Allow running other programs, e.g. bash
if ARGV.length.zero? || ARGV[0].start_with?('-')
  FileUtils.mkdir_p('/var/log/supervisor')
  # umount s3 bucket and let supervisord to run the s3fs mounts
  system('umount /opt/sftp')
  system('umount /home')
  system("set -- supervisord -c /etc/supervisor/supervisord.conf \"#{ARGV}\"")
end

Entrypoint.new.run!
