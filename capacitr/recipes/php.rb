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

link "/etc/nginx/sites-enabled/#{username}" do
    to "/etc/nginx/sites-available/#{username}"
end

service "nginx" do
    action :restart
end

