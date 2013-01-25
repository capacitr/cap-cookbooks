apps = data_bag('apps')
mysql = data_bag_item("passwords", "mysql")
mysql_password = mysql["password"]

apps.each do |app|
    new_user = data_bag_item('apps', app)

    username = new_user["username"]
    dbname   = new_user["dbname"]
    dbuser   = new_user["dbuser"]
    dbpass   = new_user["dbpass"]
    port     = new_user["port"]
    domains  = new_user["domains"]

    user username do
        home "/home/#{username}"
        shell "/bin/bash"
        action :create
    end

    directory "/home/#{username}" do
        owner username
        group username
    end

    directory "/home/#{username}/static" do
        owner username
        group username
    end

    directory "/home/#{username}/uploads" do
        owner username
        group username
    end

    execute "chown -R #{username}:#{username} /home/#{username}" do
        action :run
    end

    template "/etc/supervisor/conf.d/#{username}.conf" do
        variables({
            :user => username,
            :port => port,
            :domains => domains
        })
        source "supervisor.remote.conf.erb"
    end

    execute "supervisorctl reread" do
        action :run
    end

    execute "mysql -u root -p#{mysql_password} -e \"create database \\\`#{dbname}\\\`\"" do
        action :run
        returns [0,1]
    end

    execute "mysql -u root -p#{mysql_password} -e 'GRANT ALL ON \`#{dbname}\`.* TO \`#{dbuser}\`@localhost IDENTIFIED BY \"#{dbpass}\";'" do
        action :run
    end

    template "/etc/nginx/sites-available/#{username}" do
        source "site.conf.erb"
        action :create
        variables({
            :user => username,
            :port => port,
            :domains => domains 
        })
    end

    link "/etc/nginx/sites-enabled/#{username}.conf" do
        to "/etc/nginx/sites-available/#{username}.conf"
    end

    service "nginx" do
        action :reload
    end

    template "/home/#{username}/robots.txt" do
        source "robots.txt"
        owner username
        group username
        mode 0755
    end

    file "/home/#{username}/static/favicon.ico" do
        action :create_if_missing
        owner username
        group username
        mode 0755
    end

end

execute "apt-get update" do
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
]


apt_packages.each do |package|
    execute "apt-get install -yq #{package}" do
        action :run 
        returns [0,1]
    end
end

directory "/builds" do
    owner "root" 
    group "root" 
end

