var gulp = require('gulp'),
    watch = require('gulp-watch'),
    shell = require('gulp-shell'),
    connect = require('gulp-connect');

gulp.task('connect', function() {
  connect.server({
    root: '../',
    livereload: true, port: 8050
  });
});


gulp.task('make', function() {
  watch('**/*.markdown')
    .pipe(shell('make'))
    .pipe(connect.reload());
});


gulp.task('default', ['connect', 'make']);
