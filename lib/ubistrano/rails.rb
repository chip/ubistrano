Capistrano::Configuration.instance(:must_exist).load do

  namespace :rails do
    
    # namespace :plugins do      
    #   desc 'Adds plugins defined in config/plugins.rb'
    #   task :install do
    #     if ENV['quiet'] == 'true'
    #       go = true
    #     else
    #       puts "Review config/plugins.rb. Install plugins now? (y/n)"
    #       go = STDIN.gets.upcase.strip == 'Y'
    #     end
    #     if go
    #       eval(File.read('config/plugins.rb')).each do |plugin|
    #         install_plugin plugin
    #       end
    #     end
    #   end
    # 
    #   desc 'Updates plugins defined in config/plugins.rb'
    #   task :update do
    #     eval(File.read('config/plugins.rb')).each do |plugin|
    #       path = install_path plugin
    #       if File.exists?(path)
    #         next if plugin == 'haml'
    #         Dir.chdir path do
    #           git_fetch_and_checkout(plugin, path)
    #         end
    #       else
    #         install_plugin plugin
    #       end
    #     end
    #   end
    # 
    #   desc 'Removes plugins defined in config/plugins.rb'
    #   task :remove do
    #     eval(File.read('config/plugins.rb')).each do |plugin|
    #       remove_plugin plugin
    #     end
    #   end
    # 
    #   def install_path(plugin)
    #     plugin[:to] || "vendor/plugins/#{plugin == 'haml' ? 'haml' : File.basename(plugin[:repo], '.git')}"
    #   end
    # 
    #   def install_plugin(plugin)
    #     if plugin[:repo] && plugin[:repo].include?('app_helpers')
    #       puts "Skipping #{plugin[:repo]}"
    #       return
    #     end
    #     path = remove_plugin plugin
    #     if plugin == 'haml'
    #       puts 'Installing haml'
    #       run "haml --rails ."
    #     else
    #       puts "Installing #{plugin[:repo]} at path #{path}"
    #       path = FileUtils.mkdir_p "#{path}"
    #       run "cd #{path} && git init && git remote add origin #{plugin[:repo]}"
    #       git_fetch_and_checkout(plugin, path)
    # 
    #       # Dir.chdir path do
    #       #   run "git init"
    #       #   run "git remote add origin #{plugin[:repo]}"
    #       #   git_fetch_and_checkout plugin
    #       # end
    #     end
    #   end
    # 
    #   def remove_plugin(plugin)
    #     if plugin[:repo] && plugin[:repo].include?('app_helpers')
    #       puts "Skipping #{plugin[:repo]}"
    #       return
    #     end
    #     path = install_path plugin
    #     # return path unless File.exists?(path)
    #     puts "Removing #{path}"
    #     run "rm -rf #{path}"
    #     return path
    #   end
    # 
    #   def git_fetch_and_checkout(plugin, path)
    #     if plugin[:tag] || plugin[:branch]
    #       puts "Fetching #{plugin[:repo]}"
    #       run "cd #{path} && git fetch #{plugin[:depth] ? "--depth #{plugin[:depth]} " : ''}#{plugin[:tag] ? '-t ' : ''}-q"
    #     else
    #       puts "Pulling #{plugin[:repo]}"
    #       run "cd #{path} && git pull #{plugin[:depth] ? "--depth #{plugin[:depth]} " : ''}-q origin master"
    #     end
    #     puts "Checking out #{git_head(plugin)}"
    #     run "cd #{path} && git checkout #{git_head(plugin)} -q"
    #   end
    # 
    #   def git_head(plugin)
    #     return plugin[:commit]             if plugin[:commit]
    #     return "origin/#{plugin[:branch]}" if plugin[:branch]
    #     return "tags/#{plugin[:tag]}"      if plugin[:tag]
    #     return 'master'
    #   end
    # end
    
    namespace :config do
      desc "Creates database.yml in the shared config"
      task :default, :roles => :app do
        run "mkdir -p #{shared_path}/config"
        Dir[File.expand_path('../../templates/rails/*', File.dirname(__FILE__))].each do |f|
          upload_from_erb "#{shared_path}/config/#{File.basename(f, '.erb')}", binding, :folder => 'rails'
        end
      end
      
      desc "Set up app with app_helpers" 
      task :app_helpers do
        run "cd #{release_path} && script/plugin install git://github.com/winton/app_helpers.git"
        run "cd #{release_path} && rake RAILS_ENV=production quiet=true app_helpers"
      end
      
      desc "Configure attachment_fu"
      task :attachment_fu, :roles => :app do
        run_each [
          "mkdir -p #{shared_path}/media",
          "ln -sf #{shared_path}/media #{release_path}/public/media"
        ]
        sudo_each [
          "mkdir -p #{release_path}/tmp/attachment_fu",
          "chown -R #{user} #{release_path}/tmp/attachment_fu"
        ]
      end

      desc "Plugins hook (shared by releases)"
      task :plugins_hook, :roles => :app do
        run "mkdir -p #{release_path}/vendor"
        run "ln -sf #{shared_path}/extras #{release_path}/vendor/plugins"
      end
            
      desc "Configure asset_packager" 
      task :asset_packager do
        run "source ~/.bash_profile && cd #{release_path} && rake RAILS_ENV=production asset:packager:build_all"
      end
      
      desc "Configure rails_widget"
      task :rails_widget, :roles => :app do
        run "cd #{release_path} && rake RAILS_ENV=production widget:production"
      end
      
      desc "Copies yml files in the shared config folder into our app config"
      task :to_app, :roles => :app do
        run "cp -Rf #{shared_path}/config/* #{release_path}/config"
      end
      
      namespace :thinking_sphinx do
        desc "Configures thinking_sphinx"
        task :default, :roles => :app do
          sudo ";cd #{release_path} && rake RAILS_ENV=production ts:config"
        end
        
        desc "Stop thinking_sphinx"
        task :stop, :roles => :app do
          sudo ";cd #{release_path} && rake RAILS_ENV=production ts:stop"
        end
        
        desc "Start thinking_sphinx"
        task :start, :roles => :app do
          sudo ";cd #{release_path} && rake RAILS_ENV=production ts:start"
        end
        
        desc "Restart thinking_sphinx"
        task :restart, :roles => :app do
          rails.config.thinking_sphinx.stop
          rails.config.thinking_sphinx.start
        end
      end
    end
    
    desc "Intialize Git submodules"
    task :setup_git, :roles => :app do
      run "cd #{release_path}; git submodule init; git submodule update"
    end
  end  

end