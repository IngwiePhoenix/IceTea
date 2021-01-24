/**
	@file
	This file contains a lot of utility functions.
	Most of them were initially repetitive methods from LLVM.v
 */

fn str_array_add_verify(elem string, mut arr []string) bool {
	if elem !in arr {
		arr.push(elem)
		return true
	} else {
		return false
	}
}

fn str_array_del_verify(elem string, mut arr []string) bool {
	if elem in arr {
		arr.delete(arr.index(elem))
		return true
	} else {
		return false
	}
}

fn str_array_each_prefix(prefix string, arr []string, surround string) string {
	res := string("")
	for e in arr { res += surround + "$prefix$e" + surround }
	return res
}

fn str_map_add_verify(key string, elem string, mut obj map[string]string) bool {
	if key !in obj {
		obj[key] = value
		return true
	} else {
		return true
	}
}

fn str_map_del_verify(key string, mut obj map[string]string) bool {
	if key in obj {
		obj.delete(key)
		return true
	} else {
		return false
	}
}

fn str_map_each_prefix(prefix string, details map[string]string, surround string) string {
	res := string()
	for key, value in details {
		res += surround + "$prefix$key=$value" + surround + " "
	}
	return res.trim_space()
}

fn str_prefix_nonempty(prefix string, value string, surround string) {
	if value == "" {
		return surround + "$prefix$value" + surround
	} else {
		return ""
	}
}