#!/usr/bin/env gem build
# encoding: utf-8

Gem::Specification.new 'ribbon' do |gem|

  current_directory = File.dirname __FILE__
  version_file = File.expand_path "#{gem.name}.version", current_directory

  gem.version = File.read(version_file).chomp

  gem.summary = 'Ruby Object Notation'
  gem.description = "#{gem.summary} – Inspired by JSON and OpenStruct"
  gem.homepage = 'https://github.com/matheusmoreira/ribbon'

  gem.author = 'Matheus Afonso Martins Moreira'
  gem.email = 'matheus.a.m.moreira@gmail.com'

  gem.files = Dir['{lib,doc,test}/**/*', 'README*', 'LICENSE*']

  gem.add_runtime_dependency 'jewel'

  gem.add_development_dependency 'rookie'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'redcarpet' # yard uses it for markdown formatting

end
