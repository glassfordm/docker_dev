# Dockerdev
A flexible way to add a docker development environment to a django project.

## Features
* Supports postgres, mysql, or sqlite databases.
* In the future, may support other frameworks besides Django.

## Directory Layout

Dockerdev assumes your project has a structure like this:

    some_project
      source
        django_site
          manage.py
          requirements.txt
    
The actual names of the directories don't matter as long as the structure is the same.
The names of the "some_project" and "source" directories are completely irrelevant
as far as docker_dev is concerned, and you just have to put the name you use for the
django_site directory into docker_dev's .env file (see the installation 
instructions) to tell it what to look for.

Once Dockerdev is fully installed, your directory structure will look like this:

    some_project
      data
      source
        .env
        django_site
          manage.py
          requirements.txt
        docker-compose.yml
        docker_dev

## Installation

* Make sure your project has a requirements.txt file listing all of the python
modules you use. If you don't have one and aren't sure what to put in it,
you can create one with all of the modules you currently have installed like this:

  ```Shell
  pip freeze > some_project/source/django_site/requirements.txt
  ```

* Copy the docker_dev directory into your source directory:

  ```Shell
  cd some_project/source
  git submodule add git://github.com/docker_dev/docker_dev.git docker_dev
  ```

* Create a .env file in your source directory and paste this into it, customizing the settings for your project:

  ```Shell
  # COMPOSE_PROJECT_NAME is the prefix docker-compose uses to create images and containers. 
  # It should be different for each of your projects.
  COMPOSE_PROJECT_NAME=docker_dev
  # WEBSITE_PORT is the port the website will be exposed on.
  WEBSITE_PORT=8000
  # DATABASE_TYPE should be postgres, mysql, or sqlite.
  DATABASE_TYPE=postgres
  # DJANGO_PROJECT_DIR is the name of the directory containing manage.py.
  DJANGO_PROJECT_DIR=django_site
  ```

* Create a docker-compose.yml file in your source directory and paste this into it:

  ```YAML
  version: '2'
  services:
    db:
      extends:
        file: docker_dev/docker-compose.yml
        service: db
    web:
      extends:
        file: docker_dev/docker-compose.yml
        service: web
      links:
        - db
    ```
          
  You can, of course, add other services or options as needed.

* Create an alias (perhaps adding it to a shell configuration file to make it permanent):

  ```Shell
  alias dev="make -f docker_dev/Makefile"
  ```
    
* Enter this command to build the docker image:

    ```Shell
    dev build
    ```
    
* Copy this into your settings.py file:

  ```python
  DATABASE_TYPES = {
      'postgres': {
          'ENGINE': 'django.db.backends.postgresql_psycopg2',
          'HOST': 'db',
          'PORT': 5432,
          'USER': 'dev',
          'PASSWORD': 'dev-password',
          'NAME': 'devdb',
      },
      'mysql': {
          'ENGINE': 'django.db.backends.mysql',
          'HOST': 'db',
          'PORT': 3306,
          'USER': 'dev',
          'PASSWORD': 'dev-password',
          'NAME': 'devdb',
      },
      'sqlite': {
          'ENGINE': 'django.db.backends.sqlite3',
          'NAME': '/var/lib/sqlite/db.sqlite3',
      },
  }

  import os
  DATABASES = {
      'default': DATABASE_TYPES[os.environ['DATABASE_TYPE']]
  }
  ```
    
* If you're certain what database you're going to use, you can simplify this by 
removing all of the logic for choosing the right one by means of an environment 
variable. Like this, for example:

  ```python
  DATABASES = {
      'default': {
          'ENGINE': 'django.db.backends.postgresql_psycopg2',
          'HOST': 'db',
          'PORT': 5432,
          'USER': 'dev',
          'PASSWORD': 'dev-password',
          'NAME': 'devdb',
      },
  }
  ```
    
* Run this command to start your website:

  ```Shell
  dev start
  ```    

## Working with Dockerdev

To see what else you can do, just type:

  ```Shell
  dev help
  ```

If you don't know much about docker, look inside docker_dev/Makefile
to see what docker commands dockerdev uses to do its thing.

## What's the data directory?

All database files are all stored in the data directory. The advantage of this
is that no matter how often you rebuild or delete your docker images and containers,
the data remains available when you recreate them.
It also makes them easier to make backup copies of your data.
