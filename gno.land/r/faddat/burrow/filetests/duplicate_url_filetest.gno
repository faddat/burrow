// PKGPATH: gno.land/r/faddat/burrow/filetests/duplicate_url_filetest

package duplicate_url_filetest

import (
	"testing"

	burrow "gno.land/r/faddat/burrow"
)

const (
	alice address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"
	bob   address = "g1ecely4gjy0yl6s9kt409ll330q9hk2lj9ls3ec"
)

func main(cur realm) {
	testing.SetOriginCaller(alice)
	burrow.Submit(cross(cur), "Original", "https://example.com/same", "")
	testing.SetOriginCaller(bob)
	burrow.Submit(cross(cur), "Copycat", "https://example.com/same#section", "")
}

// Error:
// duplicate url
