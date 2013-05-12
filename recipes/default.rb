redmine node["redmine"]["alias"] do
  repository node["redmine"]["repo"]
  version node["redmine"]["revision"]
  basedir node["redmine"]["deploy_to"]
  env node["redmine"]["env"]
  db_adapter node["redmine"]["databases"]["production"]["adapter"]
  db_database node["redmine"]["databases"]["production"]["database"]
  db_username node["redmine"]["databases"]["production"]["username"]
  db_password node["redmine"]["databases"]["production"]["password"]
end
