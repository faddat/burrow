// Package burrow is the stateless core of the Burrow link realm:
// input checks, time-decayed ranking, pagination, and gnoweb transaction links.
package burrow

import (
	"net/url"
	"strings"
	"unicode/utf8"
)

const (
	// MinTitleLen is the shortest accepted submission title, in Unicode code points.
	MinTitleLen = 4
	// MaxTitleLen is the longest accepted submission title, in Unicode code points.
	MaxTitleLen = 120
	// MaxURLLen is the longest accepted URL, in bytes, before and after normalization.
	MaxURLLen = 2048
	// MaxTextLen is the longest optional submission note, in bytes.
	MaxTextLen = 4000
	// MaxCommentLen is the longest comment body, in bytes.
	MaxCommentLen = 2000
	// MaxCommentDepth is how deep a reply thread may go, counting the top-level comment as 1.
	MaxCommentDepth = 6
)

// NormalizeTitle trims a title and reports whether it is short enough,
// long enough, and free of control characters.
func NormalizeTitle(raw string) (string, bool) {
	s := strings.TrimSpace(raw)
	n := utf8.RuneCountInString(s)
	if n < MinTitleLen || n > MaxTitleLen {
		return "", false
	}
	for _, r := range s {
		if r < 32 {
			return "", false
		}
	}
	return s, true
}

// NormalizeText trims an optional submission note.
// An empty note is valid.
func NormalizeText(raw string) (string, bool) {
	s := strings.TrimSpace(raw)
	if len(s) > MaxTextLen {
		return "", false
	}
	return s, true
}

// NormalizeComment trims a comment body and rejects an empty one.
func NormalizeComment(raw string) (string, bool) {
	s := strings.TrimSpace(raw)
	if s == "" || len(s) > MaxCommentLen {
		return "", false
	}
	for _, r := range s {
		if r < 32 && r != '\n' && r != '\t' {
			return "", false
		}
	}
	return s, true
}

// NormalizeURL canonicalizes an http or https URL.
// The host is lowercased, the fragment is dropped, a trailing slash is
// dropped, and default ports are dropped, so equivalent links compare equal.
func NormalizeURL(raw string) (string, bool) {
	raw = strings.TrimSpace(raw)
	if raw == "" || len(raw) > MaxURLLen {
		return "", false
	}
	if strings.ContainsAny(raw, " \t\r\n\\") {
		return "", false
	}
	u, err := url.Parse(raw)
	if err != nil || u == nil {
		return "", false
	}
	scheme := strings.ToLower(u.Scheme)
	if scheme != "http" && scheme != "https" {
		return "", false
	}
	if u.User != nil {
		return "", false
	}
	host := strings.ToLower(u.Hostname())
	if !acceptableHost(host) {
		return "", false
	}
	port := u.Port()
	if (scheme == "http" && port == "80") || (scheme == "https" && port == "443") {
		port = ""
	}
	path := u.EscapedPath()
	if path == "/" {
		path = ""
	} else {
		path = strings.TrimRight(path, "/")
	}
	var b strings.Builder
	b.WriteString(scheme)
	b.WriteString("://")
	b.WriteString(host)
	if port != "" {
		b.WriteByte(':')
		b.WriteString(port)
	}
	b.WriteString(path)
	if u.RawQuery != "" {
		b.WriteByte('?')
		b.WriteString(u.RawQuery)
	}
	out := b.String()
	if len(out) > MaxURLLen {
		return "", false
	}
	return out, true
}

func acceptableHost(host string) bool {
	if host == "" || host == "." || strings.HasPrefix(host, ".") || strings.HasSuffix(host, ".") {
		return false
	}
	if host == "localhost" || strings.Contains(host, ".") || strings.Contains(host, ":") {
		return true
	}
	return false
}
