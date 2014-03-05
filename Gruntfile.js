module.exports = function (grunt) {
    grunt.initConfig({
        clean: ['src/*.js', 'src/*.map', 'test/spec/*.js', 'test/spec/*.map'],
        karma: {
            continuous: {
                configFile: 'test/karma.conf.js',
                autoWatch: true,
                singleRun: false
            },
            unit: {
                configFile: 'test/karma.conf.js'
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-karma');

    grunt.registerTask('test', function (type) {
        if (type === 'continuous') {
            grunt.task.run('karma:continuous');
        } else {
            grunt.task.run('karma:unit');
        }
    });
};
