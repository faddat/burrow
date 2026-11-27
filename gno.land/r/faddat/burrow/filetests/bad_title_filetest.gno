// PKGPATH: gno.land/r/faddat/burrow/filetests/bad_title_filetest

package bad_title_filetest

import (
	"testing"

	burrow "gno.land/r/faddat/burrow"
)

const alice address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"

func main(cur realm) {
	testing.SetOriginCaller(alice)
	burrow.Submit(cross(cur), "no", "https://example.com/no", "")
}

// Error:
// title must be 4 to 120 characters
