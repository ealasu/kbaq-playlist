module.exports = function(grunt) {

  // Project configuration
  grunt.initConfig({
    lint: {
      all: ['grunt.js', '**/*.js']
    },
    jshint: {
      options: {
        browser: true
      }
    },
    coffee: {
      compile: {
        files: [
          {
            expand: true,
            cwd: 'scripts/',
            src: ['**/*.coffee'],
            dest: 'public/js/',
            ext: '.js'
          },
          {
            expand: true,
            src: ['*.coffee'],
            dest: '',
            ext: '.js'
          }
          //'public/js/client.js': 'scripts/client.coffee',
          //'server.js': 'server.coffee'
        ]
      }
    },
    handlebars: {
      compile: {
        options: {
          namespace: "Handlebars.templates"
        },
        files: {
          'public/js/templates.js': 'templates/*.hbs'
        }
      }
    },
    sass: {
      dev: {
        files: {
          'public/css/*.css': 'styles/*.scss'
        }
      }
    },
    watch: {
      coffee: {
        files: ['**/*.coffee'],
        tasks: 'coffee'
      },
      handlebars: {
        files: ['**/*.hbs'],
        tasks: 'handlebars'
      },
      sass: {
        files: ['**/*.scss'],
        tasks: 'sass'
      }
    }
  });

  // Load tasks
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-handlebars');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-watch');

  // Default task.
  grunt.registerTask('default', ['coffee', 'sass', 'handlebars']);

};