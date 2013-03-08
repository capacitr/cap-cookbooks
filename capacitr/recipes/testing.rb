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

