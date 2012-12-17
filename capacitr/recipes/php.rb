template "/etc/hosts" do
    source "hosts.erb"
end

execute "echo \"#{node[:new_hostname]}\" > /etc/hostname" do
    action :run
    user "root"
    group "root"
end

user node["new_user"] do
    home "/home/#{node[:new_user]}"
    shell "/bin/zsh"
    action :create
end

directory "/home/#{node[:new_user]}" do
    owner node["new_user"] 
    group node["new_user"]
end

link "/home/#{node[:new_user]}/site" do
    to "/vagrant"
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
    "apache2",
    "php5",
    "php5-mysql",
    "libmysqlclient-dev",
    "mysql-server",
    "zlib1g-dev", 
    "libfreetype6-dev", 
    "liblcms1-dev",
    "libjpeg62-dev",
    "zsh",
    "git-core"
]


apt_packages.each do |package|
    execute "apt-get install -yq #{package}" do
        action :run 
    end
end
#
#template "/etc/nginx/sites-available/#{node[:new_user]}.conf" do
#    source "site.conf.erb"
#end
#
#link "/etc/nginx/sites-enabled/#{node[:new_user]}.conf" do
#    to "/etc/nginx/sites-available/#{node[:new_user]}.conf"
#end

service "apache2" do
    action :restart
end

#
#template "/etc/supervisor/conf.d/#{node[:new_user]}.conf" do
#    source "supervisor.php.conf.erb"
#end
#
#service "supervisor" do
#    action :restart
#end

execute "mysql -u root -ppassword -e \"create database #{node[:dbname]}\"" do
    action :run
    returns [0, 1]
end

execute "mysql -u root -ppassword -e 'GRANT ALL ON \`#{node[:dbname]}\`.* TO \`#{node[:dbuser]}\`@localhost IDENTIFIED BY \"#{node[:dbpass]}\";'" do
    action :run
end

if node[:initial_sql_data]
    execute "mysql -u root -ppassword #{node[:dbname]} < /home/#{node[:new_user]}/site/#{node[:initial_sql_data]}" do
        action :run
    end
end
