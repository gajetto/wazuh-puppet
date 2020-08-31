# Wazuh App Copyright (C) 2020 Wazuh Inc. (License GPLv2)
# Setup for opendistro
class wazuh::opendistro (
  # Elasticsearch.yml configuration

  $opendistro_cluster_name = 'es-wazuh',
  $opendistro_node_name = 'node-01',
  $opendistro_node_master = true,
  $opendistro_node_data = true,
  $opendistro_node_ingest = true,
  $opendistro_node_max_local_storage_nodes = '1',
  $opendistro_service = 'elasticsearch',
  $opendistro_package = 'opendistroforelasticsearch',
  $opendistro_version = '1.9.0',

  $opendistro_path_data = '/var/lib/elasticsearch',
  $opendistro_path_logs = '/var/log/elasticsearch',


  $opendistro_ip = 'localhost',
  $opendistro_port = '9200',
  $opendistro_discovery_option = 'discovery.type: single-node',
  $opendistro_cluster_initial_master_nodes = "#cluster.initial_master_nodes: ['node-01']",

# JVM options
  $jvm_options_memmory = '1g',

){

  class {'wazuh::repo_opendistro':}


  if $::osfamily == 'Debian' {
    file { 'elasticsearch-oss':
        path     => '/var/tmp/elasticsearch-oss.deb',
        ensure   => present,
        mode     => '0644',
        owner    => 'root',
        group    => 'root',
        source   => 'https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-7.8.0-amd64.deb',
    }

    package { 'elasticsearch-oss-install':
        name     => 'elasticsearch-oss',
        ensure   => latest,
        provider => dpkg,                  
        source   => File['elasticsearch-oss']['path'],
        require  => File['elasticsearch-oss'],
    }
    Class['wazuh::repo_opendistro'] -> Class['apt::update'] -> Package['opendistroforelasticsearch']
  } else {
    Class['wazuh::repo_opendistro'] -> Package['opendistroforelasticsearch']
  }

  # install package
  package { 'opendistroforelasticsearch':
  #  ensure => $opendistro_version,
    name   => $opendistro_package,
  }

  file { 'Configure elasticsearch.yml':
    owner   => 'elasticsearch',
    path    => '/etc/elasticsearch/elasticsearch.yml',
    group   => 'elasticsearch',
    mode    => '0644',
    notify  => Service[$opendistro_service], ## Restarts the service
    content => template('wazuh/opendistro_yml.erb'),
    require => Package[$opendistro_package],
  }

  file { 'Configure jvm.options':
    owner   => 'elasticsearch',
    path    => '/etc/elasticsearch/jvm.options',
    group   => 'elasticsearch',
    mode    => '0660',
    notify  => Service[$opendistro_service], ## Restarts the service
    content => template('wazuh/jvm_options.erb'),
    require => Package[$opendistro_package],
  }

  service { 'elasticsearch':
    ensure  => running,
    enable  => true,
    require => Package[$opendistro_package],
  }

  exec { 'Insert line limits':
    path    => '/usr/bin:/bin/',
    command => "echo 'elasticsearch - nofile  65535\nelasticsearch - memlock unlimited' >> /etc/security/limits.conf",
    require => Package[$opendistro_package],

  }

  exec { 'Verify Elasticsearch folders owner':
    path    => '/usr/bin:/bin',
    command => "chown elasticsearch:elasticsearch -R /etc/elasticsearch\
             && chown elasticsearch:elasticsearch -R /usr/share/elasticsearch\
             && chown elasticsearch:elasticsearch -R /var/lib/elasticsearch",
    require => Package[$opendistro_package],

  }


}
