// Gruntfile.js
// jt6 20141202 WTSI
//
// build file for the HICF website. Based on an auto-generated grunt config
// built using generator-webapp 0.5.1

// # Globbing
// for performance reasons we're only matching one level down:
// 'test/spec/{,*/}*.js'
// If you want to recursively match all subfolders, use:
// 'test/spec/**/*.js'

// needed to make jshint happy
/*global require, module*/

module.exports = function (grunt) {
  'use strict';

  // time how long tasks take. Can help when optimizing build times
  require('time-grunt')(grunt);

  // load grunt tasks automatically (using the JIT loader)
  require('jit-grunt')(grunt, {
    useminPrepare: 'grunt-usemin'
  });

  // define the configuration for all the tasks
  grunt.initConfig({

    // project settings
    config: {
      app: 'app',
      dist: 'dist'
    },

    // clean up
    clean: {
      // removes the distribution and temp dirs
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
      // removes just the temp space
      server: '.tmp'
    },

    // lint all of the javascript code
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

    // names assets with revision IDs
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

    // reads the main page template to find files that can be minified and
    // renamed with version IDs
    useminPrepare: {
      options: {
        dest: '<%= config.dist %>/public'
      },
      html: '<%= config.app %>/views/layouts/main.tt'
    },

    // rewrites and renames asset files
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
    imagemin: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= config.app %>/public/images',
          src: '{,*/}*.{gif,jpeg,jpg,png}',
          dest: '<%= config.dist %>/public/images'
        }]
      }
    },

    // not currently used
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

    // minifies HTML, doesn't work with some TT code though
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
    //       cwd: '<%= config.dist %>/views',
    //       src: '{,*/}*.tt',
    //       dest: '<%= config.dist %>/views'
    //     }]
    //   }
    // },

    // Copies remaining files to places other tasks can use
    copy: {
      dist: {
        options: { 
          mode: true,
        },
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
        'imagemin'
        // 'svgmin'
      ]
    }

  });

  // starts the perl backend (starman/dancer) and the nginx frontend
  grunt.registerTask('startServers', function() {

    // avoid an error if the servers are already running
    if ( grunt.file.exists('test_server/nginx.pid') ||
         grunt.file.exists('test_server/starman.pid') ) {
      grunt.log.warn( 'WARNING: servers are still running; stopping them before trying to start' );
      grunt.task.run('concurrent:stopServers');
    }
    grunt.task.run(
      'shell:buildNginxConf',
      'concurrent:startServers'
    );
  });

  // stops the backend and nginx
  grunt.registerTask('stopServers', [
    'concurrent:stopServers'
  ]);

  // starts the preview server and watches for changes to source files
  grunt.registerTask('serve', function() {
    grunt.log.subhead('preview the site at http://128.0.0.1:8001');
    grunt.task.run([
      'clean:server',
      'startServers',
      'watch'
    ]);
  });

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

  // builds the distribution
  grunt.registerTask('build', [
    'clean:dist',
    'jshint',
    'sass:dist',
    'useminPrepare',
    'concurrent:dist',
    'autoprefixer',
    'concat:generated',
    'cssmin:generated',
    'uglify:generated',
    'copy:dist',
    'filerev',
    'usemin',
  ]);
  // this breaks with certain TT idioms
    // 'htmlmin'

  // set the default task
  grunt.registerTask('default', [
    'newer:jshint',
    // 'test',
    'build'
  ]);
};
