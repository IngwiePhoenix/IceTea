module mongoose

// Configure Mongoose to use ipv6 and mbedTLS.
// OpenSSL would also be an option, but right now, there is no
// "defines" in V. So I have to be assumptious.
$if option mg_openssl {}
#flag -l openssl
#flag -D MG_ENABLE_OPENSSL=1
} $else {
#flag -D MG_ENABLE_MBEDTLS=1
}

#flag -D MG_ENABLE_IPV6=1

#flag -I @VROOT/mongoose-git
#flag @VROOT/mongoose-git/mongoose.c
#include mongoose.h

/**
	This is NOT generated - I copytyped **everything** that follows - and also
	picked the typing. They might be off, in multiple places.
	Some of the functions have side effects that require arguments to be marked
	with mutability - whilst others are simply const, and I haven't added that yet.

	This file largely serves one purpose: Making V aware of the C API exposed by Mongoose,
	so I can consume it in lib.c.v to provide a pure V interface. That is also why none
	of the methods in here are marked as "pub". They're not ment to be used that way.

	What I think is missing:
	- Converting from mg_str to V's string (which are, in fact, field-compatible)
	- A good bunch of "mut"s and "const"s.
	- Some of the constants here should probably be actual enums.
	- Many functions should be marked as [inline].
	- Some of these functions should be [trusted] and [untrusted] respectively.
 */

// Internal string lib
struct C.mg_str {
	ptr charptr // const
	len size_t
}
fn C.mg_str(charptr) C.mg_str
fn C.mg_str_n(charptr) C.mg_str
fn C.mg_lower(charptr) int
fn C.mg_ncasecmp(charptr, charptr, size_t) int
fn C.mg_casecmp(charptr, charptr) int
fn C.mg_vcmp(C.mg_str, charptr) int
fn C.mg_vcasecmp(C.mg_str, charptr) int
fn C.mg_strcmp(C.mg_str, C.mg_str) int
fn C.mg_strstrip(C.mg_str) C.mg_str
fn C.mg_strdup(C.mg_str) C.mg_str
fn C.mg_strstr(C.mg_str, C.mg_str) charptr

const {
	// Redefining a few preprocessor macros in plain V
	// This *should* help.
	MG_NULL_STR := C.mg_str{NULL, 0}
}

// Timers
struct C.mg_timer {
	period_ms int
	flags int
	fn fn(voidptr)voidptr // fixme: This most definitively won't work.
	arg voidptr
	expire u32
	next &C.mg_timer
}
fn C.mg_timer_init(&C.mg_timer, int, int, fn(voidptr)voidptr, voidptr)
fn C.mg_timer_free(&C.mg_timer)
fn C.mg_timer_poll(ulong)

// Internal I/O
fn C.mg_file_read(charptr) charptr
fn C.mg_file_size(charptr) size_t
fn C.mg_file_write(charptr, charptr, ...any) int
fn C.mg_random(&voidptr, size_t)
fn C.mg_globmatch(charptr, int, charptr, int) bool
fn C.mg_next_comma_entry(C.mg_str, C.mg_str, C.mg_str) bool
fn C.mg_ntohs(u16) u16
fn C.mg_ntohl(u32) u32
fn C.mg_hexdump(charptr, int) charptr
fn C.mg_hex(charptr, int, charptr) charptr
fn C.mg_unhex(charptr, int, charptr)
fn C.mg_unhexn(charptr, int) u32
fn C.mg_asprintf(charptrptr, size_t, charptr, ...any) int
fn C.mg_vasprintf(charptrptr, size_t, charptr, ...any) int
fn C.mg_to64(C.mg_str) i64
fn C.mg_time() f32 // what's a double in V?
fn C.mg_millis() u32
fn C.mg_usleep(u32)
// from cdefs
fn C.mg_htons(u16) u16
fn C.mg_htonl(u32) u32
fn C.MG_SWAP16(i16) i16
fn C.MG_SWAP32(int) int

// URL stuff
fn C.mg_url_port(charptr) ushort // FIXME: u16?
fn C.mg_url_is_ssl(charptr) int
fn C.mg_url_host(charptr) C.mg_str
fn C.mg_url_user(charptr) C.mg_str
fn C.mg_url_pass(charptr) C.mg_str
fn C.mg_url_uri(charptr) charptr

// Buffers
struct C.mg_iobuf {
	buf charptr // unsigned - but how?
	size size_t
	len size_t
}

fn C.mg_iobuf_init(&C.mg_iobuf, size_t)
fn C.mg_iobuf_resize(&C.mg_iobuf, size_t)
fn C.mg_iobuf_free(&C.mg_iobuf)
fn C.mg_iobuf_append(&C.mg_iobuf, voidptr, size_t, size_t) size_t
fn C.mg_iobuf_delete(&C.mg_iobuf, size_t) size_t

// Base 64
fn C.mg_base64_update(charptr, mut charptr, int) int
fn C.mg_base64_final(mut charptr, int) int
fn C.mg_base64_encode(charptr, int, mut charptr) int
fn C.mg_base64_decode(charptr, int, mut charptr) int

// MD5
[typedef]
struct mg_md5_ctx {
	buf [4]u32
	bits [2]u32
	in [64]char // FIXME: should this be [64]byte instead?
}
fn C.mg_md5_init(&C.mg_md5_ctx)
fn C.mg_md5_update(&C.mg_md5_ctx, charptr, size_t)
fn C.mg_md5_final(&C.mg_md5_ctx, [16]char) // FIXME: [16]byte?

// SHA1
[typedef]
struct mg_sha1_ctx {
	state [5]u32
	count [2]u32
	buffer [64]char // FIXME
}
fn C.mg_sha1_init(&C.mg_sha1_ctx)
fn C.mg_sha1_update(&C.mg_sha1_ctx, charptr, size_t)
fn C.mg_sha1_final([20]char, &C.mg_sha1_ctx)
fn C.mg_hmac_sha1(charptr, size_t, charptr, size_t, [20]char) // FIXME

// Connection
type mg_event_handler_t = fn(&C.mg_connection, int, voidptr, voidptr)
struct C.mg_connection {
	// FIXME: Defined *way* before the others are!
	next &C.mg_connection
	mgr &C.mg_mgr
	peer &C.mg_addr
	fd voidptr
	id u32
	recv &C.mg_iobuf
	send &C.mg_iobuf
	fn mg_event_handler_t
	fn_data voidptr
	pfn mg_event_handler_t
	pfn_data voidptr
	label [32]char // FIXME
	tls voidptr
	is_listening u32 = 1
	is_client u32 = 1
	is_accepted u32 = 1
	is_resolving u32 = 1
	is_connecting u32 = 1
	is_tls u32 = 1
	is_tls_hs u32 = 1
	is_udp u32 = 1
	is_websocket u32 = 1
	is_hexdumping u32 = 1
	is_draining u32 = 1
	is_closing u32 = 1
	is_readable u32 = 1
	is_writeable u32 = 1
}
fn C.mg_call(&C.mg_connection, int, voidptr)
fn C.mg_error(&C.mg_connection, charptr, ...any)

// FIXME: name?
enum {
	MG_EV_ERROR
	MG_EV_POLL
	MG_EV_RESOLVE
	MG_EV_CONNECT
	MG_EV_ACCEPT
	MG_EV_READ
	MG_EV_WRITE
	MG_EV_CLOSE
	MG_EV_HTTP_MSG
	MG_EV_WS_OPEN
	MG_EV_WS_MSG
	MG_EV_WS_CTL
	MG_EV_MQTT_CMD
	MG_EV_MQTT_MSG
	MG_EV_MQTT_OPEN
	MG_EV_SNTP_TIME
	MG_EV_USER
}

// DNS
struct C.mg_dns {
	url charptr
	c &C.mg_connection
}
struct C.mg_addr {
	port u16
	ip u32
	ip6 [16]u8
	is_ip6 bool
}
struct C.mg_mgr {
	conns &C.mg_connection
	dns4 &C.mg_dns
	dns6 &C.mg_dns
	dnstimeout int
	nextid u32
}

fn C.mg_mgr_poll(&C.mg_mgr, int)
fn C.mg_mgr_init(&C.mg_mgr)
fn C.mg_mgr_free(&C.mg_mgr)

fn C.mg_listen(&C.mg_mgr, charptr, mg_event_handler_t, voidptr) &C.mg_connection
fn C.mg_connect(&C.mg_mgr, charptr, mg_event_handler_t, voidptr) &C.mg_connection
fn C.mg_send(&C.mg_connection, voidptr, size_t) int
fn C.mg_printf(&C.mg_connection, charptr, ...any) int
fn C.mg_vprintf(&C.mg_connection, charptr, ...any) int
fn C.mg_straddr(&C.mg_connection, charptr, size_t) mut charptr
fn C.mg_socketpair(int, int) bool
fn C.mg_aton(&C.mg_str, &C.mg_addr) bool
fn C.mg_ntoa(&C.mg_addr, mut charptr, size_t) mut charptr

// HTTP Header
struct C.mg_http_header {
	name &C.mg_str
	value &C.mg_str
}
struct C.mg_http_message {
	method &C.mg_str
	uri &C.mg_str
	query &C.mg_str
	proto &C.mg_str
	headers &[]C.mg_http_header // Actually predefined - but dunno how to wrap this properly.
	body &C.mg_str
	message &C.mg_str
}
struct C.mg_http_serve_opts {
	root_dir charptr
	ssi_pattern charptr
}

fn C.mg_http_parse(charptr, size_t, &C.mg_http_message) int
fn C.mg_http_get_request_len(charptr, size_t) int
fn C.mg_http_printf_chunk(&C.mg_connection, charptr, ...any)
fn C.mg_http_write_chunk(&C.mg_connection, charptr, size_t)
fn C.mg_http_listen(&C.mg_mgr, charptr, mg_eventhandler_t, voidptr) &C.mg_connection
fn C.mg_http_connect(&C.mg_mgr, charptr, mg_event_handler_t, voidptr) &C.mg_connection
fn C.mg_http_serve_dir(&C.mg_connection, &C.mg_http_message, &C.mg_http_serve_opts)
fn C.mg_http_serve_file(&C.mg_connection, &C.mg_http_message, charptr, charptr)
fn C.mg_http_reply(&C.mg_connection, int, charptr, charptr, ...any)
fn C.mg_http_get_header(&C.mg_http_message, charptr) &C.mg_str
fn C.mg_http_event_handler(&C.mg_connection, int)
fn C.mg_http_get_var(&C.mg_str, charptr, mut charptr, int) int
fn C.mg_url_decode(charptr, size_t, mut charptr, size_t, int) int
fn C.mg_http_creds(&C.mg_http_message, mut charptr, int, mut charptr, int)
fn C.mg_http_match_uri(&C.mg_http_message, charptr) bool
fn C.mg_http_upload(&C.mg_connection, &C.mg_http_message, charptr) int
fn C.mg_http_bauth(&C.mg_connection, charptr, charptr)
fn C.mg_http_serve_ssi(&C.mg_connection, charptr, charptr)

// TLS
struct C.mg_tls_opts {
	ca charptr
	cert charptr
	certkey charptr
	ciphers charptr
	srvname charptr
}

fn C.mg_tls_init(&C.mg_connection, &C.mg_tls_opts) int
fn C.mg_tls_free(&C.mg_connection) int
fn C.mg_tls_send(&C.mg_connection, voidptr, size_t, mut int) int
fn C.mg_tls_recv(&C.mg_connection, mut voidptr, size_t, int) int
fn C.mg_tls_handshake(&C.mg_connection) int

// WebSockets
const {
	// Maybe make this an emum instead?...
	WEBSOCKET_OP_CONTINUE = C.WEBSOCKET_OP_CONTINUE
	WEBSOCKET_OP_TEXT = C.WEBSOCKET_OP_TEXT
	WEBSOCKET_OP_BINARY = C.WEBSOCKET_OP_BINARY
	WEBSOCKET_OP_CLOSE = C.WEBSOCKET_OP_CLOSE
	WEBSOCKET_OP_PING = C.WEBSOCKET_OP_PING
	WEBSOCKET_OP_PONG = C.WEBSOCKET_OP_PONG
	WEBSOCKET_FLAGS_MASK_FIN = C.WEBSOCKET_FLAGS_MASK_FIN
	WEBSOCKET_FLAGS_MASK_OP = C.WEBSOCKET_FLAGS_MASK_OP
}

struct C.mg_ws_message {
	data &C.mg_str
	flags u8
}

fn C.mg_ws_connect(&C.mg_mgr, charptr, mg_event_handler_t, voidptr, charptr, ...any) &C.mg_connection
fn C.mg_ws_upgrade(&C.mg_connection, &C.mg_http_message)
fn C.mg_ws_send(&C.mg_connection, charptr, size_t, int) size_t

// SNTP
fn C.mg_sntp_connect(&C.mg_mgr, charptr, mg_event_handler_t, voidptr) &C.mg_connection
fn C.mg_sntp_send(&C.mg_connection, u32)
// FIXME: timeval not defined in V via C-prefix, afaik!
//fn C.mg_sntp_parse(charptr, size_t, &C.timeval)

// MQTT
const {
	MQTT_CMD_CONNECT = C.MQTT_CMD_CONNECT
	MQTT_CMD_CONNACK = C.MQTT_CMD_CONNACK
	MQTT_CMD_PUBLISH = C.MQTT_CMD_PUBLISH
	MQTT_CMD_PUBACK = C.MQTT_CMD_PUBACK
	MQTT_CMD_PUBREC = C.MQTT_CMD_PUBREC
	MQTT_CMD_PUBREL = C.MQTT_CMD_PUBREL
	MQTT_CMD_PUBCOMP = C.MQTT_CMD_PUBCOMP
	MQTT_CMD_SUBSCRIBE = C.MQTT_CMD_SUBSCRIBE
	MQTT_CMD_SUBACK = C.MQTT_CMD_SUBACK
	MQTT_CMD_UNSUBSCRIBE = C.MQTT_CMD_UNSUBSCRIBE
	MQTT_CMD_UNSUBACK = C.MQTT_CMD_UNSUBACK
	MQTT_CMD_PINGREQ = C.MQTT_CMD_PINGREQ
	MQTT_CMD_PINGRESP = C.MQTT_CMD_PINGRESP
	MQTT_CMD_DISCONNECT = C.MQTT_CMD_DISCONNECT
}

// QOS? Im not a math dude. o.o
[inline]
fn C.MQTT_QOS(any_int) any_int
[inline]
fn C.MQTT_GET_QOS(any_int) any_int
[inline]
fn C.MQTT_SET_QOS(any_int) any_int

struct C.mg_mqtt_opts {
	client_id &C.mg_str
	will_topic &C.mg_str
	will_message &C.mg_str
	qos u8
	will_retain bool
	clean bool
	keepalive u16
}

struct C.mg_mqtt_message {
	topic &C.mg_str
	data &C.mg_str
	dgram &C.mg_str
	id u16
	cmd u8
	qos u8
	ack u8
}

fn C.mg_mqtt_connect(
	&C.mg_mgr, charptr, &C.mg_mqtt_opts,
	mg_event_handler_t, voidptr
) &C.mg_connection
fn C.mg_mqtt_listen(&C.mg_mgr, charptr, mg_event_handler_t, voidptr) &C.mg_connection
fn C.mg_mqtt_pub(&C.mg_connection, &C.mg_str, &C.mg_str)
fn C.mg_mqtt_sub(&C.mg_connection, &C.mg_str)
fn C.mg_mqtt_parse(u8, size_t, mut &C.mg_mqtt_message) int
fn C.mg_mqtt_send_header(&C.mg_connection, u8, u8, u32)
fn C.mg_mqtt_next_sub(&C.mg_mqtt_message, &C.mg_str, u8, int) int

// DNS
struct C.mg_dns_message {
	txnid u16
	resolved bool
	addr C.mg_addr
	name [255]byte // FIXME
}

struct C.mg_dns_header {
	txnid u16
	flags u16
	num_questions u16
	num_answers u16
	num_authority_prs u16
	num_other_prs u16
}

struct C.mg_dns_rr {
	nlen u16
	atype u16
	aclass u16
	alen u16
}

fn C.mg_resolve(&C.mg_connection, &C.mg_str, int)
fn C.mg_resolve_cancel(&C.mg_connection)
fn C.mg_dns_parse(u8, size_t, &C.mg_dns_message) bool
fn C.mg_dns_parse_rr(u8, size_t, size_t, bool, &C.mg_dns_rr) size_t
fn C.mg_dns_decode_name(u8, size_t, size_t, charptr, size_t)