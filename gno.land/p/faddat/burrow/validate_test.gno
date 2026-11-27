package burrow

import "testing"

func TestNormalizeTitle(t *testing.T) {
	got, ok := NormalizeTitle("  Hello burrow  ")
	if !ok || got != "Hello burrow" {
		t.Fatalf("got %q ok=%v", got, ok)
	}
	if _, ok = NormalizeTitle("abc"); ok {
		t.Fatal("short title accepted")
	}
	if _, ok = NormalizeTitle("bad\ntitle"); ok {
		t.Fatal("newline title accepted")
	}
	long := ""
	for i := 0; i < MaxTitleLen+1; i++ {
		long += "a"
	}
	if _, ok = NormalizeTitle(long); ok {
		t.Fatal("long title accepted")
	}
	// Four Unicode code points, more than four bytes.
	got, ok = NormalizeTitle("雪の夜道")
	if !ok || got != "雪の夜道" {
		t.Fatalf("unicode title %q ok=%v", got, ok)
	}
}

func TestNormalizeTextAndComment(t *testing.T) {
	got, ok := NormalizeText("  ")
	if !ok || got != "" {
		t.Fatalf("empty note %q ok=%v", got, ok)
	}
	if _, ok = NormalizeText(repeat("x", MaxTextLen+1)); ok {
		t.Fatal("long note accepted")
	}
	got, ok = NormalizeComment("  hello\nthere  ")
	if !ok || got != "hello\nthere" {
		t.Fatalf("comment %q ok=%v", got, ok)
	}
	if _, ok = NormalizeComment("  "); ok {
		t.Fatal("empty comment accepted")
	}
	if _, ok = NormalizeComment("bad\x00byte"); ok {
		t.Fatal("control character accepted")
	}
}

func TestNormalizeURL(t *testing.T) {
	cases := []struct {
		in   string
		want string
	}{
		{"https://Example.com/a/", "https://example.com/a"},
		{"https://example.com/a#section", "https://example.com/a"},
		{"http://example.com:80/a/", "http://example.com/a"},
		{"https://example.com:443", "https://example.com"},
		{"https://localhost/x/", "https://localhost/x"},
		{"https://example.com:8443/a/", "https://example.com:8443/a"},
		{"https://example.com/a?b=1", "https://example.com/a?b=1"},
	}
	for _, tc := range cases {
		got, ok := NormalizeURL(tc.in)
		if !ok || got != tc.want {
			t.Fatalf("%q -> %q ok=%v, want %q", tc.in, got, ok, tc.want)
		}
	}
	left, _ := NormalizeURL("https://Example.com/a/")
	right, _ := NormalizeURL("https://example.com/a")
	if left != right {
		t.Fatalf("equivalents differ: %q vs %q", left, right)
	}
	bad := []string{
		"",
		"javascript:alert(1)",
		"https://user:pass@example.com/a",
		"https://intranet",
		"ftp://example.com/a",
		"https://example.com/a b",
		"not a url",
	}
	for _, in := range bad {
		if _, ok := NormalizeURL(in); ok {
			t.Fatalf("accepted %q", in)
		}
	}
}

func repeat(s string, n int) string {
	out := ""
	for i := 0; i < n; i++ {
		out += s
	}
	return out
}
