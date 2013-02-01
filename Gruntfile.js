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
          {cwd: 'scripts/', src: '**/*.coffee', dest: 'public/js/', ext: '.js', expand: true},
          {src: '*.coffee', dest: '', ext: '.js', expand: true}
        ]
      }
    },
    handlebars: {
      compile: {
        options: {
          namespace: "Handlebars.templates"
        },
        files: [
          {src: 'templates/*.hbs', dest: 'public/js/templates.js'}
        ]
      }
    },
    sass: {
      dev: {
        files: [
          {src: 'styles/*.scss', dest: 'public/css/style.css'}
        ]
      }
    },
    jade: {
      compile: {
        options: {
          pretty: true
        },
        files: [
          {cwd: 'jade', src: '**/*.jade', dest: 'public/', expand: true, ext: '.html'}
        ]
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
      },
      jade: {
        files: ['**/*.jade'],
        tasks: 'jade'
      }
    }
  });

  // Load tasks
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-handlebars');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-jade');
  grunt.loadNpmTasks('grunt-contrib-watch');

  // Default task.
  grunt.registerTask('default', ['coffee', 'sass', 'handlebars', 'jade']);

};