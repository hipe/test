window.jQuery(function($){
  $('.cancel-target').click(function(){
    var group = /^cancel-target-(.+)/.exec($(this).attr('id'))[1];
    $('#target-'+group).hide();
  });
  $('.target-button').click(function(){
    var group = /^target-button-(.+)/.exec($(this).attr('id'))[1];
    $('#target-'+group).show();
  });
  $('table.resizable').resizable_table({grid: [5,5]});
  $('#square').resizable_table({grid: [10,10]});
});
