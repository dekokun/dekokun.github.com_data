var gulp = require('gulp'),
    watch = require('gulp-watch'),
    shell = require('gulp-shell'),
    connect = require('gulp-connect');
    open = require('gulp-open');

gulp.task('connect', function() {
  var options = {
      url: 'http://localhost:8050',
      app: 'firefox'
  };
  connect.server({
    root: '../',
    livereload: true, port: 8050
  });
  gulp.src('../index.html')
  .pipe(open('', options));
});


gulp.task('make', function() {
  watch('**/*.markdown')
    .pipe(shell('make'))
    .pipe(connect.reload());
});


gulp.task('default', ['connect', 'make']);
