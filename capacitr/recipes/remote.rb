node["users"].each do |new_user|
    user new_user[:username] do
        home "/home/#{new_user[:username]}"
        shell "/bin/bash"
        action :create
    end

    directory "/home/#{new_user[:username]}" do
        owner new_user[:username]
        group new_user[:username]
    end

    directory "/home/#{new_user[:username]}/uploads" do
        owner new_user[:username]
        group new_user[:username]
    end

    execute "chown -R #{new_user[:username]}:#{new_user[:username]} /home/#{new_user[:username]}" do
        action :run
    end

    template "/etc/supervisor/conf.d/#{new_user[:username]}.conf" do
        variables({
            :user => new_user[:username],
            :port => new_user[:port],
            :domains => new_user[:domains]
        })
        source "supervisor.remote.conf.erb"
    end

    execute "supervisorctl reread" do
        action :run
    end

    mysql_password = data_bag_item("mysql", "password")

    execute "mysql -u root -p#{mysql_password} -e \"create database \\\`#{new_user[:dbname]}\\\`\"" do
        action :run
        returns [0,1]
    end

    execute "mysql -u root -p#{mysql_password} -e 'GRANT ALL ON \`#{new_user[:dbname]}\`.* TO \`#{new_user[:dbuser]}\`@localhost IDENTIFIED BY \"#{new_user[:dbpass]}\";'" do
        action :run
    end

    template "/etc/nginx/sites-available/#{new_user[:username]}.conf" do
        source "site.conf.erb"
        action :create
        variables({
            :user => new_user[:username],
            :port => new_user[:port],
            :domains => new_user[:domains]
        })
    end

    link "/etc/nginx/sites-enabled/#{new_user[:username]}.conf" do
        to "/etc/nginx/sites-available/#{new_user[:username]}.conf"
    end

    service "nginx" do
        action :reload
    end
end

#
#execute "apt-get update" do
#    action :run
#end
#
#execute "apt-get install -qfy" do
#    action :run
#end
#
#apt_packages = [
#    "python-setuptools",
#    "nginx",
#    "python-dev",
#    "libmysqlclient-dev",
#    "mysql-server",
#    "zlib1g-dev", 
#    "libxml2",
#    "libxslt1.1",
#    "libxml2-dev",
#    "libxslt1-dev",
#    "libfreetype6-dev", 
#    "liblcms1-dev",
#    "libjpeg62-dev",
#    "supervisor",
#    "memcached",
#    "libcurl3",
#    "libcurl3-gnutls",
#    "git-core",
#    "unzip",
#    "make",
#    "ruby",
#    "rubygems",
#    "openjdk-6-jre-headless",
#]
#
#
#apt_packages.each do |package|
#    execute "apt-get install -yq #{package}" do
#        action :run 
#    end
#end
#
##
##execute "wget -O /root/compiler-latest.zip http://closure-compiler.googlecode.com/files/compiler-latest.zip" do
##    action :run
##end
##
##execute "unzip /root/compiler-latest.zip -d /root/compiler-latest" do
##    action :run
##    user "root"
##    group "root"
##end
##
##execute "mv /root/compiler-latest/compiler.jar /usr/bin/closure_compiler" do
##    action :run
##    user "root"
##    group "root"
##end
##
##file "/usr/bin/closure_compiler" do
##    mode 00755
##    owner "root"
##    group "root"
##end
##
#

