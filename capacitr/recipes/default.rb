user node["new_user"] do
    home "/home/#{node[:new_user]}"
    shell "/bin/zsh"
    action :create
end

directory "/home/#{node[:new_user]}" do
    owner node["new_user"] 
    group node["new_user"]
end

directory "/home/#{node[:new_user]}/static" do
    owner node["new_user"] 
    group node["new_user"]
end

link "/home/#{node[:new_user]}/site" do
    to "/vagrant"
    owner node["new_user"]
    group node["new_user"]
end

directory "/home/#{node[:new_user]}/uploads" do
    owner node["new_user"] 
    group node["new_user"]
end

execute "apt-get update" do
    action :run
end

execute "echo mysql-server mysql-server/root_password password password |
debconf-set-selections" do
    action :run
end

execute "echo mysql-server mysql-server/root_password_again password password |
debconf-set-selections" do
    action :run
end

execute "apt-get install -qfy" do
    action :run
end

apt_packages = [
    "python-setuptools",
    "nginx",
    "python-dev",
    "libmysqlclient-dev",
    "mysql-server",
    "zlib1g-dev", 
    "libfreetype6-dev", 
    "liblcms1-dev",
    "libjpeg62-dev",
    "supervisor",
    "zsh",
    "libcurl3",
    "libcurl3-gnutls",
    "git-core"
]


apt_packages.each do |package|
    execute "apt-get install -yq #{package}" do
        action :run 
    end
end
execute "easy_install virtualenv" do
    action :run
end

execute "virtualenv --distribute /home/#{node[:new_user]}/venv" do
    action :run
    user node[:new_user]
    group node[:new_user]
    returns [0,1]
end

node[:python_packages].each do |package|
    execute "pip install #{package}" do
        action :run
        cwd "/home/#{node[:new_user]}/site"
        user node[:new_user]
        group node[:new_user]
        environment ({'PATH' => "/home/#{node[:new_user]}/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"})
    end
end

template "/etc/nginx/sites-available/#{node[:new_user]}.conf" do
    source "site.conf.erb"
end

link "/etc/nginx/sites-enabled/#{node[:new_user]}.conf" do
    to "/etc/nginx/sites-available/#{node[:new_user]}.conf"
end

service "nginx" do
    action :restart
end

template "/etc/supervisor/conf.d/#{node[:new_user]}.conf" do
    source "supervisor.conf.erb"
end

service "supervisor" do
    action :restart
end

execute "mysql -u root -ppassword -e \"create database \\\`#{node[:dbname]}\\\`\"" do
    action :run
end

execute "mysql -u root -ppassword -e 'GRANT ALL ON \`#{node[:dbname]}\`.* TO \`#{node[:dbuser]}\`@localhost IDENTIFIED BY \"#{node[:dbpass]}\";'" do
    action :run
end

if node[:dbhost_location] != "localhost"
    execute "echo \"127.0.0.1 #{node[:dbhost_location]}\" >> /etc/hosts" do
        action :run
    end
end

execute "python manage.py syncdb --noinput --database=#{node[:dbhost]}" do
    action :run
    cwd "/home/#{node[:new_user]}/site"
    environment ({'PATH' => "/home/#{node[:new_user]}/venv/bin:/usr/bin"})
    user node["new_user"]
    group node["new_user"]
end

execute "python manage.py migrate --database=#{node[:dbhost]}" do
    action :run
    cwd "/home/#{node[:new_user]}/site"
    environment ({'PATH' => "/home/#{node[:new_user]}/venv/bin"})
    user node["new_user"]
    group node["new_user"]
    returns [0,1]
end


node[:fixtures].each do |fixture|
    execute "python manage.py loaddata #{fixture} --database=#{node[:dbhost]}" do
        action :run
        cwd "/home/#{node[:new_user]}/site"
        environment ({'PATH' => "/home/#{node[:new_user]}/venv/bin"})
        user node["new_user"]
        group node["new_user"]
    end
end

execute "python manage.py collectstatic --noinput" do
    action :run
    cwd "/home/#{node[:new_user]}/site"
    environment ({'PATH' => "/home/#{node[:new_user]}/venv/bin"})
    user node["new_user"]
    group node["new_user"]
end

