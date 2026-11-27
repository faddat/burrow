// PKGPATH: gno.land/r/faddat/burrow/filetests/non_mod_hide_filetest

package non_mod_hide_filetest

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
	id := burrow.Submit(cross(cur), "Leave this up", "https://example.com/up", "")
	testing.SetOriginCaller(bob)
	burrow.HideItem(cross(cur), id)
}

// Error:
// moderator only
