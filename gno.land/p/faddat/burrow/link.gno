package burrow

import (
	"net/url"
	"strings"
)

// TxLink builds a gnoweb help URL that opens one exported function,
// with arguments prefilled. webPath is the realm's gnoweb path, such as
// "/r/faddat/burrow". kv is key, value, key, value, using the function's
// parameter names (the leading realm parameter is omitted).
//
// The shape matches gnoweb's transaction links: path$help&func=Name&k=v.
func TxLink(webPath, fn string, kv ...string) string {
	if fn == "" {
		panic("missing function")
	}
	if len(kv)%2 != 0 {
		panic("odd number of link arguments")
	}
	base := strings.TrimRight(webPath, "/")
	link := base + "$help&func=" + url.QueryEscape(fn)
	if len(kv) == 0 {
		return link
	}
	vals := url.Values{}
	for i := 0; i < len(kv); i += 2 {
		key := kv[i]
		if key == "" || strings.HasPrefix(key, ".") {
			panic("invalid link argument")
		}
		vals.Add(key, kv[i+1])
	}
	return link + "&" + vals.Encode()
}
