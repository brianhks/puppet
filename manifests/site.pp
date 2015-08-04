node default {
	$msg = hiera('hello_message')
	notify {"Message: ${msg}":}
}

