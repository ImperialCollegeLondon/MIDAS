// Generated on 2014-11-11 using
// generator-webapp 0.5.1

// # Globbing
// for performance reasons we're only matching one level down:
// 'test/spec/{,*/}*.js'
// If you want to recursively match all subfolders, use:
// 'test/spec/**/*.js'

/*global require, module*/

module.exports = function (grunt) {
  'use strict';

  // Time how long tasks take. Can help when optimizing build times
  require('time-grunt')(grunt);

  // Load grunt tasks automatically
  require('load-grunt-tasks')(grunt);

  // Define the configuration for all the tasks
  grunt.initConfig({

    // Project settings
    config: {
      app: 'app',
      dist: 'dist'
    },

    // Empties folders to start fresh
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '.tmp',
            '<%= config.dist %>/*',
            '!<%= config.dist %>/.git*'
          ]
        }]
      },
      server: '.tmp'
    },

    // Make sure code styles are up to par and there are no obvious mistakes
    jshint: {
      options: {
        jshintrc: '.jshintrc',
        reporter: require('jshint-stylish-ex')
      },
      all: [
        'Gruntfile.js',
        '<%= config.app %>/public/javascripts/{,*/}*.js',
        'test/spec/{,*/}*.js'
      ]
    },

    // Mocha testing framework configuration options
    // mocha: {
    //   all: {
    //     options: {
    //       run: true,
    //       urls: ['http://<%= connect.test.options.hostname %>:<%= connect.test.options.port %>/index.html']
    //     }
    //   }
    // },

    // Renames files for browser caching purposes
    filerev: {
      assets: {
        src: [
          '<%= config.dist %>/public/javascripts/{,*/}*.js',
          '<%= config.dist %>/public/styles/{,*/}*.css',
          '<%= config.dist %>/public/*.{ico,png}',
          '<%= config.dist %>/public/images/**/*'
        ]
      }
    },

    // Reads HTML for usemin blocks to enable smart builds that automatically
    // concat, minify and revision files. Creates configurations in memory so
    // additional tasks can operate on them
    useminPrepare: {
      options: {
        dest: '<%= config.dist %>/public'
      },
      html: '<%= config.app %>/views/layouts/main.tt'
    },

    // Performs rewrites based on filerev and the useminPrepare configuration
    usemin: {
      options: {
        assetsDirs: [
          '<%= config.dist %>/public',
          '<%= config.dist %>/public/javascripts',
          '<%= config.dist %>/public/images',
          '<%= config.dist %>/public/styles'
        ]
      },
      html: ['<%= config.dist %>/views/{,*/}*.tt'],
      css: ['<%= config.dist %>/public/styles/{,*/}*.css']
    },

    // The following *-min tasks produce minified files in the dist folder
    // imagemin: {
    //   dist: {
    //     files: [{
    //       expand: true,
    //       cwd: '<%= config.app %>/public/images',
    //       src: '{,*/}*.{gif,jpeg,jpg,png}',
    //       dest: '<%= config.dist %>/public/images'
    //     }]
    //   }
    // },

    // svgmin: {
    //   dist: {
    //     files: [{
    //       expand: true,
    //       cwd: '<%= config.app %>/images',
    //       src: '{,*/}*.svg',
    //       dest: '<%= config.dist %>/images'
    //     }]
    //   }
    // },

    // htmlmin: {
    //   dist: {
    //     options: {
    //       collapseBooleanAttributes: true,
    //       collapseWhitespace: true,
    //       conservativeCollapse: true,
    //       removeAttributeQuotes: true,
    //       removeCommentsFromCDATA: true,
    //       removeEmptyAttributes: true,
    //       removeOptionalTags: true,
    //       removeRedundantAttributes: true,
    //       useShortDoctype: true
    //     },
    //     files: [{
    //       expand: true,
    //       cwd: '<%= config.dist %>',
    //       src: '{,*/}*.html',
    //       dest: '<%= config.dist %>'
    //     }]
    //   }
    // },

    // Copies remaining files to places other tasks can use
    copy: {
      dist: {
        files: [
          {
            expand: true,
            dot: true,
            cwd: '<%= config.app %>',
            src: [
              'bin/*',
              'lib/*',
              'views/**',
              '{,*/}*.conf',
              'public/*.{ico,png,txt}',
              'public/images/**',
              '!**/.*.sw?',
              'styles/fonts/{,*/}*.*'
            ],
            dest: '<%= config.dist %>'
          }
        ]
      },
      styles: {
        expand: true,
        dot: true,
        cwd: '<%= config.app %>/public/styles',
        src: '{,*/}*.css',
        dest: '.tmp/styles/'
      }
    },

    // Compiles Sass to CSS and generates necessary files if requested
    sass: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= config.app %>/public/styles',
          src: ['{,*/}*.{scss,sass}'],
          dest: '.tmp/styles',
          ext: '.css'
        }]
      },
      server: {
        files: [{
          expand: true,
          cwd: '<%= config.app %>/public/styles',
          src: ['{,*/}*.{scss,sass}'],
          dest: '.tmp/styles',
          ext: '.css'
        }]
      }
    },

    // Add vendor prefixed styles
    autoprefixer: {
      options: {
        browsers: ['> 1%', 'last 2 versions', 'Firefox ESR', 'Opera 12.1']
      },
      dist: {
        files: [{
          expand: true,
          cwd: '.tmp/styles/',
          src: '{,*/}*.css',
          dest: '.tmp/styles/'
        }]
      }
    },

    nginx: {
      options: {
        config: 'test_server/nginx.conf',
        prefix: 'nginx'
      }
    },

    shell: {
      buildNginxConf: {
        command: 'sed "s:__CWD__:"`pwd`":" test_server/nginx.conf.template > test_server/nginx.conf'
      },
      startBackend: {
        command: 'starman --listen :8000 -E development --pid test_server/starman.pid --daemonize app/bin/app.pl'
      },
      restartBackend: {
        command: 'kill -HUP `cat test_server/starman.pid`'
      },
      stopBackend: {
        command: 'kill -TERM `cat test_server/starman.pid`'
      }
    },

    watch: {
      js: {
        files: ['<%= config.app %>/public/javascripts/{,*/}*.js'],
        tasks: ['jshint']
      },
      // jstest: {
      //   files: ['test/spec/{,*/}*.js'],
      //   tasks: ['test:watch']
      // },
      gruntfile: {
        files: ['Gruntfile.js']
      },
      sass: {
        files: ['<%= config.app %>/public/styles/{,*/}*.{scss,sass}'],
        tasks: [ 'sass:server', 'autoprefixer' ],
      },
      styles: {
        files: ['<%= config.app %>/public/styles/{,*/}*.css'],
        tasks: ['newer:copy:styles', 'autoprefixer']
      },
      templates: {
        files: [ '<%= config.app %>/views/{,*/}*.tt' ],
        tasks: [ 'newer:copy:dist' ]
      },
      livereload: {
        options: {
          livereload: 35729
        },
        files: [
          '<%= config.app %>/views/**/*.tt',
          '.tmp/styles/{,*/}*.css',
          '<%= config.app %>/public/javascripts/**/*',
          '<%= config.app %>/public/images/**/*'
        ]
      }
    },

    // Run some tasks in parallel to speed up build process
    concurrent: {
      startServers: [
        'sass:server',
        'copy:styles',
        'shell:startBackend',
        'nginx:start'
      ],
      stopServers: [
        'shell:stopBackend',
        'nginx:stop'
      ],
      test: [
        'copy:styles'
      ],
      dist: [
        'sass',
        'copy:styles',
        // 'imagemin',
        // 'svgmin'
      ]
    }

  });

  // starts the perl backend (starman/dancer) and the nginx frontend
  grunt.registerTask('startServers', function() {
    grunt.task.run(
      'shell:buildNginxConf',
      'concurrent:startServers'
    );
    grunt.log.writeln('(ii) view the server at http://128.0.0.1:8001');
  });

  // stops the backend and nginx
  grunt.registerTask('stopServers', [
    'concurrent:stopServers'
  ]);

  grunt.registerTask('serve', 'start the preview server', function() {
    grunt.task.run([
      'clean:server',
      'concurrent:startServers',
      'watch'
    ]);
  });

  // grunt.registerTask('serve', 'start the server and preview your app', function (target) {
    // if (target === 'dist') {
    //   // return grunt.task.run(['build', 'connect:dist:keepalive']);
    //   return grunt.task.run(['build']);
    // }
    // grunt.task.run([
    //   'clean:server',
    //   'concurrent:server',
    //   'autoprefixer',
    //   'watch',
    // ]);
      // 'connect:livereload'
    // grunt.task.run([
    //   'clean:dist',
    //   'sass:dist',
    //   'useminPrepare',
    //   'concat:generated',
    //   'cssmin:generated',
    //   'uglify:generated',
    //   'copy:dist',
    //   'filerev',
    //   'usemin',
    //   'watch'
  // });

  // grunt.registerTask('server', function (target) {
  //   grunt.log.warn('The `server` task has been deprecated. Use `grunt serve` to start a server.');
  //   grunt.task.run([target ? ('serve:' + target) : 'serve']);
  // });

  // grunt.registerTask('test', function (target) {
  //   if (target !== 'watch') {
  //     grunt.task.run([
  //       'clean:server',
  //       'concurrent:test',
  //       'autoprefixer'
  //     ]);
  //   }
  //
  //   grunt.task.run([
  //     'connect:test',
  //     'mocha'
  //   ]);
  // });

  // grunt.registerTask('build', [
  //   'clean:dist',
  //   'jshint',
  //   'sass:dist',
  //   'useminPrepare',
  //   'concat:generated',
  //   'cssmin:generated',
  //   'uglify:generated',
  //   'copy:dist',
  //   'filerev',
  //   'usemin'
  // ]);

  // lastest working version
  // grunt.registertask('build', [
  //   'clean:dist',
  //   'jshint',
  //   'sass:dist',
  //   'useminPrepare',
  //   'concat:generated',
  //   'cssmin:generated',
  //   'uglify:generated',
  //   'copy:dist',
  //   'filerev',
  //   'usemin'
  // ]);

  // grunt.registerTask('build', [
  //   'clean:dist',
  //   'wiredep',
  //   'useminPrepare',
  //   'concurrent:dist',
  //   'autoprefixer',
  //   'concat:generated',
  //   'cssmin:generated',
  //   'uglify:generated',
  //   'copy:dist',
  //   'modernizr',
  //   'filerev',
  //   'usemin'
  // ]);
  // not sure we want to try minifying TT...
  // 'htmlmin'

  grunt.registerTask('default', [
    'build'
  ]);
    // 'newer:jshint',
    // 'test',
};
