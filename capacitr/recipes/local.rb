app = data_bag_item('apps', node[:app])
mysql = data_bag_item('passwords', 'mysql')

username = app["username"]
dbname = app["dbname"]
dbuser = app["dbuser"]
dbpass = app["dbpass"]
domains = app["domains"]

user username do
    home "/home/#{username}"
    shell "/bin/bash"
    action :create
end

directory "/home/#{username}" do
    owner username
    group username
end

directory "/home/#{username}/uploads" do
    owner username
    group username
end

directory "/home/#{username}/static" do
    owner username
    group username
end

execute "touch /home/#{username}/static/favicon.ico" do
    action :run
    user username
    group username
end

execute "chown -R #{username}:#{username} /home/#{username}" do
    action :run
end

execute "apt-get update" do
    action :run
end

execute "easy_install virtualenv" do
    action :run
end

execute "virtualenv --distribute /home/#{username}/venv" do
    action :run
    user username
    group username
    returns [0,1]
end

unless File.file?("requirements.txt")
  execute "pip install -v --no-index --index-url=file://basket/ -r requirements.txt" do
      action :run
      cwd "/home/#{username}/site"
      user "root"
      group "root" 
      environment ({'PATH' => "/home/#{username}/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"})
      returns [0,1]
  end
end

execute "chown -R #{username}:#{username} /home/#{username}/venv" do
    action :run
    user "root"
    group "root"
end

execute "mysql -u root -ppassword -e \"create database \\\`#{dbname}\\\`\"" do
    action :run
    returns [0,1]
end

execute "mysql -u root -ppassword -e 'GRANT ALL ON \`#{dbname}\`.* TO \`#{dbuser}\`@localhost IDENTIFIED BY \"#{dbpass}\";'" do
    action :run
end

template "/etc/nginx/sites-available/#{username}" do
    source "site.conf.erb"
    action :create
    variables({
        :user => username,
        :domains => domains,
        :port => "8000"
    })
end

template "/etc/supervisor/conf.d/#{username}.conf" do
    variables({
        :user => username,
        :port => "8000",
        :domains => domains
    })
    source "supervisor.conf.erb"
end

link "/etc/nginx/sites-enabled/#{username}" do
    to "/etc/nginx/sites-available/#{username}"
end

service "nginx" do
    action :restart
end

