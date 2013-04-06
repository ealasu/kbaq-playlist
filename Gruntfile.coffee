module.exports = (grunt) ->
  
  grunt.initConfig
    lint:
      all: ['grunt.js', '**/*.js']
    
    jshint:
      options:
        browser: true
    
    coffee:
      compile:
        files: [
          {cwd: 'src/client/scripts/', src: '**/*.coffee', dest: 'build/client/js/', ext: '.js', expand: true},
          {cwd: 'src/server/', src: '**/*.coffee', dest: 'build/server/', ext: '.js', expand: true}
        ],
        sourceMap: true
    
    handlebars:
      compile:
        options:
          namespace: "Handlebars.templates"
          processName: (filePath) -> # input:  templates/_header.hbs
            pieces = filePath.split("/")
            name = pieces[pieces.length - 1] # output: _header.hbs
            name.split(".")[0] # output: _header
        files:
          'build/client/js/templates.js': 'src/client/templates/*.hbs'
          
    sass:
      dev:
        files: [
          {src: 'src/client/styles/*.scss', dest: 'build/client/css/style.css'}
        ]
        
    jade:
      compile:
        options:
          pretty: true
        files: [
          {cwd: 'src/client/site', src: '**/*.jade', dest: 'build/client/', expand: true, ext: '.html'}
        ]
    
    copy:
      main:
        files: [
          {expand: true, cwd: 'src/client/site/', src: '**/*.html', dest: 'build/client/'}
          #,{expand: true, cwd: 'src/client/lib/', src: '**/*.js', dest: 'build/client/js/lib/'}
        ]

    watch:
      coffee:
        files: ['**/*.coffee']
        tasks: 'coffee'
      handlebars:
        files: ['**/*.hbs']
        tasks: 'handlebars'
      sass:
        files: ['**/*.scss']
        tasks: 'sass'
      jade:
        files: ['**/*.jade']
        tasks: 'jade'

    simplemocha:
      options:
        globals: ['should']
        timeout: 3000
        ignoreLeaks: false
        grep: '*-test'
        ui: 'bdd'
        reporter: 'tap'
      all: { src: 'test/**/*.coffee' }


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-handlebars'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-jasmine-node'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  
  grunt.registerTask 'default', ['coffee', 'sass', 'handlebars', 'jade', 'copy']
