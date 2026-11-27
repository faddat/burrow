// PKGPATH: gno.land/r/faddat/burrow/filetests/empty_front_filetest

package empty_front_filetest

import burrow "gno.land/r/faddat/burrow"

func main(cur realm) {
	println(burrow.Render(""))
}

// Output:
// # Burrow
//
// [hot](/r/faddat/burrow) · [new](/r/faddat/burrow:new) · [top](/r/faddat/burrow:top) · [submit](/r/faddat/burrow:submit)
//
// ## Hot
//
// Score decays with a 6 hour half-life, using the block time.
//
// No submissions yet. [Submit a link](/r/faddat/burrow$help&func=Submit).
//
// ---
//
// No owner yet. [Claim](/r/faddat/burrow$help&func=Claim) · [realm help](/r/faddat/burrow$help)
