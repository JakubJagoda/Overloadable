module.exports = function (grunt) {
  grunt.initConfig({
    clean: ["src/*.js", "src/*.map", "test/spec/*.js", "test/spec/*.map", "dist/*"],
    coffee: {
      dist: {
        bare: false,
        files: {
          "dist/Overloadable.js": "src/Overloadable.coffee"
        }
      }
    },
    karma: {
      dist: {
        configFile: "test/karma.conf.js",
        options: {
          files: [
            'test/bindPolyfill.js',
            'dist/Overloadable.js',
            'test/spec/*.spec.coffee'
          ]
        }
      },
      continuous: {
        configFile: "test/karma.conf.js",
        autoWatch: true,
        singleRun: false
      },
      unit: {
        configFile: "test/karma.conf.js"
      }
    },
    uglify: {
      dist: {
        files: {
          "dist/Overloadable.min.js": "dist/Overloadable.js"
        },
        options: {
          sourceMap: true
        }
      }
    }
  });

  grunt.loadNpmTasks("grunt-contrib-clean");
  grunt.loadNpmTasks("grunt-contrib-coffee");
  grunt.loadNpmTasks("grunt-contrib-uglify");
  grunt.loadNpmTasks("grunt-karma");

  grunt.registerTask("test", function (type) {
    switch(type) {
      case "continuous":
        grunt.task.run("karma:continuous");
        break;

      case "dist":
        grunt.task.run("karma:dist");
        break;

      default:
        grunt.task.run("karma:unit");
        break;
    }
  });

  grunt.registerTask("build", function () {
    grunt.task.run("default");
  });

  grunt.registerTask("default", function () {
    /*
      tests run two times in order to ensure that after compiling with contrib-coffee
      (if it had other coffeescript compiler than karma) and minifying, everything works fine
    */

    [
      "clean",
      "test",
      "coffee",
      "uglify",
      "test:dist"
    ].forEach(function (task) {
      grunt.task.run(task);
    });

  });
};
