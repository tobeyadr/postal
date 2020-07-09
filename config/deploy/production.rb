# frozen_string_literal: true

server 'mta01.mailhawk.io', user: 'root', roles: %w[app db web]

set :branch, 'master'