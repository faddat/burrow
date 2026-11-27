// PKGPATH: gno.land/r/faddat/burrow/filetests/rate_limit_filetest

package rate_limit_filetest

import (
	"testing"

	burrow "gno.land/r/faddat/burrow"
)

const alice address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"

func main(cur realm) {
	testing.SetOriginCaller(alice)
	burrow.Submit(cross(cur), "First post", "https://example.com/one", "")
	burrow.Submit(cross(cur), "Too soon", "https://example.com/two", "")
}

// Error:
// rate limited
