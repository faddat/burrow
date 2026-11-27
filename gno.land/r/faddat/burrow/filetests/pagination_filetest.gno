// PKGPATH: gno.land/r/faddat/burrow/filetests/pagination_filetest

package pagination_filetest

import (
	"strconv"
	"testing"

	burrow "gno.land/r/faddat/burrow"
)

const alice address = "g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"

func bump(blocks int64) {
	ctx := testing.GetContext()
	testing.SetHeight(ctx.Height + blocks)
}

func main(cur realm) {
	testing.SetOriginCaller(alice)
	for i := 1; i <= 21; i++ {
		if i > 1 {
			bump(burrow.RateLimitBlocks)
			testing.SetOriginCaller(alice)
		}
		burrow.Submit(cross(cur), "Link number "+strconv.Itoa(i), "https://example.com/p/"+strconv.Itoa(i), "")
	}
	println(burrow.Render("new?page=2"))
}

// Output:
// # Burrow
//
// [hot](/r/faddat/burrow) · [new](/r/faddat/burrow:new) · [top](/r/faddat/burrow:top) · [submit](/r/faddat/burrow:submit)
//
// ## New
//
// Newest submissions first.
//
// **21. [Link number 1](/r/faddat/burrow:item/1)** · [example.com](https://example.com/p/1)
//
// +0 -0 · [g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5](/r/faddat/burrow:user/g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5) · 2009-02-13 23:31 UTC · block 123 · [0 comments](/r/faddat/burrow:item/1) · [up](/r/faddat/burrow$help&func=VoteItem&dir=1&id=1) · [down](/r/faddat/burrow$help&func=VoteItem&dir=-1&id=1) · [clear](/r/faddat/burrow$help&func=VoteItem&dir=0&id=1)
//
//
// [prev](/r/faddat/burrow:new) · page 2 of 2
//
// ---
//
// No owner yet. [Claim](/r/faddat/burrow$help&func=Claim) · [realm help](/r/faddat/burrow$help)
