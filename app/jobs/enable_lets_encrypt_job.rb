class EnableLetsEncryptJob < ApplicationJob
  queue_as :default

  def perform(app)
    @app = app
    return if app.letsencrypt_enabled?

    install_letsencrypt_plugin_if_needed

    SshExecution.new(app.server).
      execute(command: "sudo dokku config:set -no-restart #{app.clean_name} DOKKU_LETSENCRYPT_EMAIL=#{app.letsencrypt_email}")
    SshExecution.new(app.server).
      execute(command: "sudo dokku letsencrypt #{app.clean_name}")
  end

  private

  def install_letsencrypt_plugin_if_needed
    installed_plugins = SshExecution.new(@app.server).execute(command: "dokku plugin")
    return if "letsencrypt".in?(installed_plugins)
    
    SshExecution.new(@app.server).
      execute(command: "sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git")
    SshExecution.new(@app.server).
      execute(command: "sudo dokku letsencrypt:cron-job --add")
  end
end