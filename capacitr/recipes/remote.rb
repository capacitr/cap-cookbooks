user node["new_user"] do
    home "/home/#{node[:new_user]}"
    shell "/bin/bash"
    action :create
end

directory "/home/#{node[:new_user]}/uploads" do
    owner node["new_user"] 
    group node["new_user"]
end

execute "chown -R #{node[:new_user]}:#{node[:new_user]} /home/#{node[:new_user]}" do
    action :run
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
    "libxml2",
    "libxslt1.1",
    "libxml2-dev",
    "libxslt1-dev",
    "libfreetype6-dev", 
    "liblcms1-dev",
    "libjpeg62-dev",
    "supervisor",
    "memcached",
    "libcurl3",
    "libcurl3-gnutls",
    "git-core",
    "unzip",
    "make",
    "ruby",
    "rubygems",
    "openjdk-6-jre-headless",
]


apt_packages.each do |package|
    execute "apt-get install -yq #{package}" do
        action :run 
    end
end
#
#execute "wget -O /root/compiler-latest.zip http://closure-compiler.googlecode.com/files/compiler-latest.zip" do
#    action :run
#end
#
#execute "unzip /root/compiler-latest.zip -d /root/compiler-latest" do
#    action :run
#    user "root"
#    group "root"
#end
#
#execute "mv /root/compiler-latest/compiler.jar /usr/bin/closure_compiler" do
#    action :run
#    user "root"
#    group "root"
#end
#
#file "/usr/bin/closure_compiler" do
#    mode 00755
#    owner "root"
#    group "root"
#end
#

template "/etc/nginx/sites-available/#{node[:new_user]}.conf" do
    source "site.conf.erb"
end

link "/etc/nginx/sites-enabled/#{node[:new_user]}.conf" do
    to "/etc/nginx/sites-available/#{node[:new_user]}.conf"
end

service "nginx" do
    action :reload
end

template "/etc/supervisor/conf.d/#{node[:new_user]}.conf" do
    source "supervisor.conf.erb"
end

service "supervisor" do
    action :restart
end

execute "mysql -u root -ppassword -e \"create database \\\`#{node[:dbname]}\\\`\"" do
    action :run
    returns [0,1]
end

execute "mysql -u root -ppassword -e 'GRANT ALL ON \`#{node[:dbname]}\`.* TO \`#{node[:dbuser]}\`@localhost IDENTIFIED BY \"#{node[:dbpass]}\";'" do
    action :run
end

