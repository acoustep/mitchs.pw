$('.about').click (e)->
	$('#contact').hide()
	$('#aboutMe').slideDown()

$('.contact').click (e)->
	$('#aboutMe').hide()
	$('#contact').slideDown()
