# Introducing the Dockerfilemerge gem

    require 'dockerfilemerge'

    s2 =<<EOF
    # Dockermergefile

    INCLUDE
      https://raw.githubusercontent.com/hypriot/rpi-ruby/master/Dockerfile
      https://raw.githubusercontent.com/acencini/rpi-python-serial-wiringpi/master/Dockerfile

    MAINTAINER James Robertson <james@jamesrobertson.eu>

    RUN gem install humble_rpi
    RUN gem install dynarex
    EOF

    puts DockerfileMerge.new(s2).to_s

## Resources

* ?dockerfilemerge https://rubygems.org/gems/dockerfilemerge?

dockerfilemerge gem dockerfile merge


